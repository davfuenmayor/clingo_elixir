defmodule Clingo.MaintenanceTest do
  use ExUnit.Case, async: true
  alias Clingo.TestSupport.Raw, as: A

  test "bulk conversion preserves order, structs, bounds and empty arrays" do
    Clingo.with_session(fn s ->
      values = Enum.to_list(-500..500)
      array = Clingo.array(s, "int", values)
      assert Clingo.read_array(s, array, length(values)) == values
      assert Clingo.write_array(s, array, [42, 43], 10) == :ok
      assert Clingo.read(s, array, 10) == 42
      assert Clingo.read(s, array, 11) == 43
      assert_raise ArgumentError, fn -> Clingo.read_array(s, array, 1002) end
      assert_raise ArgumentError, fn -> Clingo.write_array(s, array, [1, 2], 1000) end
      assert Clingo.read_array(s, Clingo.array(s, "int", []), 0) == []
      assert Clingo.read_array(s, nil, 0) == []
      assert_raise ArgumentError, fn -> Clingo.read_array(s, nil, 1) end
      parts = [%{name: "base", params: nil, size: 0}]
      assert Clingo.read_array(s, Clingo.array(s, "clingo_part_t", parts), 1) == parts
    end)
  end

  test "output helpers preserve native returns and multiple outputs" do
    Clingo.with_session(fn s ->
      assert {true, value} =
               Clingo.output(s, :clingo_parse_term, ["7", nil, nil, 20], "clingo_symbol_t")

      assert {true, 7} == Clingo.output(s, :clingo_symbol_number, [value], "int")

      {true, function} = Clingo.Internal.API.symbol_create_function(s, "f", [value], true)

      assert {true, {pointer, 1}} =
               Clingo.output(s, :clingo_symbol_arguments, [function], [
                 "clingo_symbol_t*",
                 "size_t"
               ])

      assert Clingo.read_array(s, pointer, 1) == [value]
    end)
  end

  test "callback arity is checked before registration and errors preserve stack context" do
    Clingo.with_session(fn s ->
      assert_raise ArgumentError, fn -> Clingo.callback(s, "clingo_logger_t", fn _ -> :ok end) end
      assert :sys.get_state(s.dispatcher).callbacks == %{}
      callback = Clingo.callback(s, "clingo_default_model_printer_t", fn _ -> raise "context" end)

      assert_raise Clingo.Error, ~r/maintenance_test.exs/, fn ->
        Clingo.call_pointer(s, callback, [nil])
      end
    end)
  end

  test "arena limit rejects aggregate growth and keeps existing storage usable" do
    Clingo.with_session(
      fn s ->
        array = Clingo.alloc(s, "char", 30_000)
        assert {used, 65_536} = Clingo.memory(s)
        assert used >= 30_000
        assert_raise Clingo.Error, fn -> Clingo.alloc(s, "char", 30_000) end
        assert Clingo.write(s, array, 65) == :ok
        assert Clingo.read(s, array) == 65
      end,
      max_arena: 65_536
    )

    assert_raise ArgumentError, fn -> Clingo.open(max_queue: -1) end
    assert_raise ArgumentError, fn -> Clingo.open(unknown: 1) end
  end

  test "queue and callback admission limits fail explicitly rather than accumulating workers" do
    Clingo.with_session(
      fn s ->
        owner = self()

        callback =
          Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
            send(owner, {:entered, self()})

            receive do
              :continue -> true
            end
          end)

        active = Task.async(fn -> Clingo.call_pointer(s, callback, [nil]) end)
        assert_receive {:entered, worker}

        try do
          assert_raise ArgumentError, ~r/busy/, fn -> Clingo.alloc(s, "int") end
        after
          send(worker, :continue)
        end

        assert Task.await(active)
      end,
      max_queue: 0
    )

    Clingo.with_session(
      fn s ->
        callback = Clingo.callback(s, "clingo_default_model_printer_t", fn _ -> true end)

        assert_raise Clingo.Error, ~r/admission limit/, fn ->
          Clingo.call_pointer(s, callback, [nil])
        end
      end,
      max_callbacks: 0
    )
  end

  test "coordinated parallel callbacks use separate cells" do
    Clingo.with_session(fn s ->
      owner = self()

      init =
        Clingo.TestSupport.field_callback(s, "clingo_propagator_t", :init, fn init, _ ->
          A.propagate_init_set_check_mode(s, init, 1)
          true
        end)

      check =
        Clingo.TestSupport.field_callback(s, "clingo_propagator_t", :check, fn control, _ ->
          id = A.propagate_control_thread_id(s, control)
          buffer = Clingo.array(s, "int", [id, id + 1])
          send(owner, {:ready, self(), id})

          receive do
            :inspect -> :ok
          end

          assert Clingo.read_array(s, buffer, 2) == [id, id + 1]
          true
        end)

      c = Clingo.TestSupport.control(s, ["0", "--parallel-mode=2,split"])
      prop = Clingo.TestSupport.struct(s, "clingo_propagator_t", %{init: init, check: check})
      assert A.control_register_propagator(s, c, prop, nil, false)
      Clingo.TestSupport.ground(s, c, "{a(1..5)}.")
      task = Task.async(fn -> Clingo.TestSupport.models(s, Clingo.TestSupport.handle(s, c)) end)
      # Coordinate callbacks; guaranteed simultaneous activity is tested by script_lifecycle.
      drain = fn recur, count ->
        receive do
          {:ready, pid, _id} ->
            send(pid, :inspect)
            recur.(recur, count + 1)

          {ref, result} when ref == task.ref ->
            Process.demonitor(ref, [:flush])
            {count, result}
        after
          5_000 -> raise "parallel solver did not finish"
        end
      end

      {count, models} = drain.(drain, 0)
      assert count > 0
      assert length(models) == 32
    end)
  end

  test "randomized repeated sessions and owner death use the managed cleanup queue" do
    :rand.seed(:exsss, {17, 23, 29})

    for _ <- 1..30 do
      owner = self()

      {pid, ref} =
        spawn_monitor(fn ->
          s = Clingo.open()
          values = for _ <- 1..:rand.uniform(30), do: :rand.uniform(1000)
          array = Clingo.array(s, "int", values)
          send(owner, {:checked, Clingo.read_array(s, array, length(values)) == values})
          if rem(length(values), 2) == 0, do: Clingo.close(s)
        end)

      assert_receive {:checked, true}
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end

    assert Clingo.Native.cleanup_wait() == :ok
  end
end
