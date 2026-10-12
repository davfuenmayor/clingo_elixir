defmodule Clingo.ReviewRegressionTest do
  use ExUnit.Case, async: true
  alias Clingo.TestSupport.Raw, as: A

  test "failed registration does not retain functions" do
    Clingo.with_session(
      fn s ->
        {used, limit} = Clingo.memory(s)
        # Static callback descriptors are smaller than the former libffi closure.
        # Leave room for the allocation node, but insufficient for registration.
        Clingo.alloc(s, "char", limit - used - 128)

        for _ <- 1..10 do
          assert_raise Clingo.Error, fn ->
            Clingo.callback(s, "clingo_default_model_printer_t", fn _ -> true end)
          end
        end

        assert :sys.get_state(s.dispatcher).callbacks == %{}
      end,
      max_arena: 20_000
    )
  end

  for stop <- [:normal, :owner_kill, :dispatcher_kill] do
    @stop stop
    test "blocked callbacks terminate on #{@stop}" do
      parent = self()

      {owner, owner_ref} =
        spawn_monitor(fn ->
          s = Clingo.open()

          cb =
            Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
              send(parent, {:entered, self()})

              receive do
                :continue -> true
              end
            end)

          send(parent, {:ready, s, cb})

          receive do
            :stop -> :ok
          end
        end)

      assert_receive {:ready, s, cb}

      caller =
        Task.async(fn ->
          try do
            Clingo.call_pointer(s, cb, [nil])
          rescue
            _ -> :closed
          catch
            :exit, reason -> {:dispatcher_exit, reason}
          end
        end)

      assert_receive {:entered, worker}
      worker_ref = Process.monitor(worker)
      dispatcher_ref = Process.monitor(s.dispatcher)

      try do
        case @stop do
          :normal -> send(owner, :stop)
          :owner_kill -> Process.exit(owner, :kill)
          :dispatcher_kill -> Process.exit(s.dispatcher, :kill)
        end

        assert_receive {:DOWN, ^dispatcher_ref, :process, _, _}, 2000
        assert_receive {:DOWN, ^worker_ref, :process, _, _}, 2000
        Task.await(caller, 4000)
      after
        Process.exit(worker, :kill)
        Process.exit(owner, :kill)
        Clingo.close(s)
      end

      assert_receive {:DOWN, ^owner_ref, :process, _, _}, 2000
    end
  end

  test "large nested arrays make progress while all dirty CPU threads wait for callbacks" do
    dirty = :erlang.system_info(:dirty_cpu_schedulers)
    # One callback per dirty CPU scheduler leaves no spare dirty CPU slot for transport.
    parent = self()

    tasks =
      for _ <- 1..dirty do
        Task.async(fn ->
          Clingo.with_session(fn s ->
            callback =
              Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
                send(parent, {:waiting, self()})

                receive do
                  :go -> :ok
                end

                values = Enum.to_list(1..10_000)
                array = Clingo.array(s, "int", values)
                assert Clingo.read_array(s, array, 10_000) == values

                assert {:error, :transport_limit} =
                         Clingo.Native.nested(
                           s.native,
                           Process.get({Clingo, :request}),
                           :array_new,
                           {"int", values}
                         )

                true
              end)

            Clingo.call_pointer(s, callback, [nil])
          end)
        end)
      end

    workers =
      for _ <- 1..dirty do
        assert_receive {:waiting, pid}, 5000
        pid
      end

    Enum.each(workers, &send(&1, :go))
    Enum.each(tasks, fn task -> assert Task.await(task, 10_000) end)
  end

  test "oversized callback replies fail without retaining the term" do
    Clingo.with_session(fn s ->
      callback =
        Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
          List.duplicate(true, 100_000)
        end)

      assert_raise Clingo.Error, ~r/transport limit/, fn ->
        Clingo.call_pointer(s, callback, [nil])
      end
    end)
  end

  test "AST cast aliases share reference ownership" do
    Clingo.with_session(fn s ->
      out = Clingo.alloc(s, "clingo_ast_t*")

      callback =
        Clingo.callback(s, "clingo_ast_callback_t", fn ast, _ ->
          alias = Clingo.cast(s, ast, "clingo_ast_t")
          A.ast_acquire(s, alias)
          Clingo.write(s, out, alias)
          true
        end)

      assert A.ast_parse_string(s, "a.", callback, nil, nil, nil, nil, 20)
      alias = Clingo.read(s, out)
      assert is_integer(A.ast_hash(s, alias))
      assert :ok = A.ast_release(s, alias)
      assert_raise ArgumentError, fn -> A.ast_hash(s, alias) end
    end)
  end
end
