defmodule Clingo.ConcurrencyTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "deeply nested native callbacks do not consume a dirty scheduler per level" do
    Clingo.with_session(fn s ->
      recursive = fn recur, depth ->
        if depth == 0 do
          true
        else
          callback =
            Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
              recur.(recur, depth - 1)
            end)

          Clingo.call_pointer(s, callback, [nil])
        end
      end

      assert recursive.(recursive, 20)
    end)
  end

  test "a killed callback worker produces a native error and releases its request" do
    Clingo.with_session(fn s ->
      callback =
        Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
          Process.exit(self(), :kill)
        end)

      assert_raise Clingo.Error, ~r/callback exited/, fn ->
        Clingo.call_pointer(s, callback, [nil])
      end

      assert text(s, symbol(s, "still_alive")) == "still_alive"
    end)
  end

  test "parallel solver callbacks inspect their own originating assignments" do
    Clingo.with_session(fn s ->
      owner = self()

      init =
        field_callback(s, "clingo_propagator_t", :init, fn ptr, _ ->
          assert A.propagate_init_number_of_threads(s, ptr) == 2
          A.propagate_init_set_check_mode(s, ptr, 1)
          true
        end)

      check =
        field_callback(s, "clingo_propagator_t", :check, fn ptr, _ ->
          id = A.propagate_control_thread_id(s, ptr)
          assert id in [0, 1]
          assert A.assignment_is_total(s, A.propagate_control_assignment(s, ptr))
          send(owner, {:solver_thread, id})
          true
        end)

      c = ground(s, control(s, ["0", "--parallel-mode=2,split"]), "{a(1..4)}.")
      prop = struct(s, "clingo_propagator_t", %{init: init, check: check})
      assert A.control_register_propagator(s, c, prop, nil, false)
      assert length(models(s, handle(s, c))) == 16
      assert_receive {:solver_thread, _}
    end)
  end

  test "an owner exiting closes the native arena even when pointers survive in another process" do
    parent = self()

    owner =
      spawn(fn ->
        s = Clingo.open()
        c = ground(s, control(s), "{a}.")
        h = handle(s, c)
        send(parent, {:session, s, c, h})

        receive do
          :done -> :ok
        end
      end)

    on_exit(fn -> Process.exit(owner, :kill) end)
    assert_receive {:session, s, c, _}, 2_000
    ref = Process.monitor(s.dispatcher)
    # Establish that the dispatcher has processed our monitor signal before
    # owner death arrives from a different sender. Avoid a :noproc monitor race.
    :sys.get_state(s.dispatcher)
    Process.exit(owner, :kill)
    assert_receive {:DOWN, ^ref, :process, _, :normal}

    closed =
      Enum.reduce_while(1..30, false, fn _, _ ->
        try do
          A.control_is_conflicting(s, c)
          Process.sleep(5)
          {:cont, false}
        rescue
          ArgumentError -> {:halt, true}
        end
      end)

    assert closed
  end

  test "cancelling a synchronous yield waits for active model search" do
    parent = self()

    Clingo.with_control(fn c ->
      Clingo.Control.register_propagator!(c, %{
        init: fn init ->
          Clingo.View.check_mode!(init, :clingo_propagator_check_mode_total)
          :ok
        end,
        check: fn _ ->
          send(parent, {:checking, self()})

          receive do
            {:cancel_self, h} ->
              assert_raise ArgumentError, ~r/cannot wait for cancellation/, fn ->
                Clingo.SolveHandle.cancel!(h)
              end

              send(parent, :cancel_rejected)
          end

          receive do
            :continue -> :ok
          end
        end
      })

      Clingo.Control.add!(c, "{selected}.")
      Clingo.Control.ground!(c)

      Clingo.Control.with_solve!(c, fn h ->
        Clingo.SolveHandle.resume!(h)
        search = Task.async(fn -> Clingo.SolveHandle.model!(h) end)
        assert_receive {:checking, worker}, 1_000
        send(worker, {:cancel_self, h})
        assert_receive :cancel_rejected
        cancel = Task.async(fn -> Clingo.SolveHandle.cancel!(h) end)
        # Cancellation promises to drain search, including the blocked callback.
        waiting = Task.yield(cancel, 50)
        send(worker, :continue)
        assert waiting == nil
        assert Task.await(cancel, 5_000) == :ok
        # An in-flight model may complete before the interrupt takes effect.
        model = Task.await(search, 5_000)
        assert model == nil or match?(%Clingo.Model{}, model)
        assert Clingo.SolveHandle.result!(h).interrupted
      end)
    end)
  end

  test "independent controls prepare fact programs concurrently" do
    results =
      Task.async_stream(
        1..4,
        fn id ->
          for _ <- 1..20 do
            result = Clingo.solve!("id(#{id}). {selected}.", models: :all)
            assert result.exhausted

            assert Enum.sort(Enum.map(result.models, & &1.shown)) == [
                     ["id(#{id})"],
                     ["id(#{id})", "selected"]
                   ]
          end

          :ok
        end,
        max_concurrency: 4,
        timeout: 30_000
      )

    assert Enum.to_list(results) == List.duplicate({:ok, :ok}, 4)
  end

  test "owner death drains raw asynchronous callbacks before arena cleanup" do
    parent = self()

    {owner, monitor} =
      spawn_monitor(fn ->
        s = Clingo.open()

        init =
          field_callback(s, "clingo_propagator_t", :init, fn ptr, _ ->
            A.propagate_init_set_check_mode(s, ptr, 1)
            true
          end)

        check =
          field_callback(s, "clingo_propagator_t", :check, fn _, _ ->
            send(parent, :raw_callback_active)
            receive do: (:never -> true)
          end)

        c = ground(s, control(s, ["0", "--parallel-mode=2,split"]), "{a(1..8)}.")
        prop = struct(s, "clingo_propagator_t", %{init: init, check: check})
        true = A.control_register_propagator(s, c, prop, nil, false)
        h = out(s, :control_solve, [c, 1, nil, 0, nil, nil], "clingo_solve_handle_t*")
        send(parent, {:raw_session, s, h})
        receive do: (:never -> :ok)
      end)

    on_exit(fn -> Process.exit(owner, :kill) end)
    assert_receive {:raw_session, s, h}, 2_000
    assert_receive :raw_callback_active, 2_000
    dispatcher = Process.monitor(s.dispatcher)
    :sys.get_state(s.dispatcher)
    Process.exit(owner, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^owner, :killed}
    assert_receive {:DOWN, ^dispatcher, :process, _, :normal}, 2_000
    closer = Task.async(fn -> Clingo.Native.close(s.native) end)
    assert :ok = Task.await(closer, 5_000)

    assert_raise ArgumentError, fn ->
      out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t")
    end
  end

  test "model pointers expire on resume while copied symbol buffers remain readable" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "a.")
      h = handle(s, c)
      assert A.solve_handle_resume(s, h)
      model = out(s, :solve_handle_model, [h], "clingo_model_t*")
      symbols = Clingo.alloc(s, "clingo_symbol_t", 1)
      assert A.model_symbols(s, model, 2, symbols, 1)
      assert A.solve_handle_resume(s, h)
      assert_raise ArgumentError, fn -> out(s, :model_number, [model], "uint64_t") end
      assert text(s, Clingo.read(s, symbols)) == "a"
    end)
  end
end

defmodule Clingo.VoidDiagnosticTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  test "void callback failures are reported without changing their native return contract" do
    log =
      capture_log(fn ->
        Clingo.with_session(fn s ->
          callback =
            Clingo.callback(s, "clingo_logger_t", fn _, _, _ -> raise "logger failure" end)

          assert Clingo.call_pointer(s, callback, [0, "message", nil]) == :ok
          :sys.get_state(s.dispatcher)
        end)
      end)

    assert log =~ "callback failed"
    assert log =~ "logger failure"
  end
end
