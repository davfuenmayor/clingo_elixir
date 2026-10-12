defmodule Clingo.ElixirLifecycleTest do
  use ExUnit.Case, async: true
  alias Clingo.{AST, Control, SolveHandle, Symbol}

  test "closed controls reject operations consistently and close is idempotent" do
    c = Control.new!()
    assert :ok = Control.close(c)
    assert :ok = Control.close(c)
    assert_raise ArgumentError, ~r/closed/, fn -> Control.solve!(c) end
    assert_raise ArgumentError, ~r/closed/, fn -> Control.add!(c, "a.") end
    assert_raise ArgumentError, ~r/closed/, fn -> Control.register_observer!(c, %{}) end
  end

  test "missing symbolic assumptions remain false across repeated cleanup" do
    missing = Symbol.parse!("missing")

    Clingo.with_control([models: :all], fn c ->
      Control.add!(c, "{a}.")
      Control.ground!(c)

      for _ <- 1..5 do
        assert Control.solve!(c, assumptions: [{missing, true}]).status == :unsatisfiable
        assert length(Control.solve!(c, assumptions: [{missing, false}]).models) == 2
        Control.cleanup!(c)
      end
    end)
  end

  test "cross-session AST construction is rejected before calling upstream" do
    AST.with_ast(fn a ->
      AST.with_ast(fn b ->
        [_, rule] = AST.parse!(a, "a.")

        assert_raise ArgumentError, ~r/another session/, fn ->
          AST.update!(rule, %{head: AST.get!(Enum.at(AST.parse!(b, "b."), 1), :head)})
        end
      end)
    end)
  end

  test "nonempty theory inspection copies elements and guards" do
    atoms =
      Clingo.with_control(fn c ->
        Control.add!(c, """
        #theory t {
          term { + : 1, binary, left };
          &a/0 : term, {=}, term, any
        }.
        p. &a { 1+2 : p } = 3.
        """)

        Control.ground!(c)
        Clingo.Inspection.theory_atoms!(c)
      end)

    assert [%{term: "a", guard: {"=", "3"}, elements: [element]}] = atoms
    assert element.terms == ["(1+2)"]
    assert is_list(element.condition)
    assert is_integer(element.condition_id)
  end

  test "an owner killed before opening a cursor releases its lease" do
    Clingo.with_control(fn c ->
      parent = self()

      {pid, monitor} =
        spawn_monitor(fn ->
          {:ok, _} = GenServer.call(c.session.dispatcher, {:lease, c.handle})
          send(parent, :leased)
          receive do: (:never -> :ok)
        end)

      assert_receive :leased
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^monitor, :process, ^pid, :killed}
      await_idle(c)
      assert Control.solve!(c).status == :satisfiable
    end)
  end

  test "a killed queued opener is discarded and a killed active opener is drained" do
    for phase <- [:queued, :active] do
      Clingo.with_control(fn c ->
        Control.add!(c, "{a;b}.")
        Control.ground!(c)
        parent = self()

        callback =
          Clingo.callback(c.session, "clingo_default_model_printer_t", fn _ ->
            send(parent, {:blocked, self()})
            receive do: (:release -> true)
          end)

        blocker = Task.async(fn -> Clingo.call_pointer(c.session, callback, [nil]) end)
        assert_receive {:blocked, worker}

        {pid, monitor} =
          spawn_monitor(fn ->
            opts =
              if phase == :active do
                [
                  on_model_view: fn _ ->
                    send(parent, {:opening, self()})
                    receive do: (:release -> :cont)
                  end
                ]
              else
                []
              end

            handle = Control.open_solve(c, opts)
            SolveHandle.resume!(handle)
            SolveHandle.model!(handle)
            receive do: (:never -> :ok)
          end)

        await_queued(c)

        hook =
          if phase == :active do
            send(worker, :release)
            assert true == Task.await(blocker)
            assert_receive {:opening, hook}, 1000
            hook
          end

        Process.exit(pid, :kill)
        assert_receive {:DOWN, ^monitor, :process, ^pid, :killed}

        if phase == :queued do
          send(worker, :release)
          assert true == Task.await(blocker)
        else
          send(hook, :release)
        end

        await_idle(c)
        assert Control.solve!(c).status == :satisfiable
      end)
    end
  end

  test "an owner killed during native solve initialization drains the opened cursor" do
    Clingo.with_control(fn c ->
      Control.add!(c, "{a}.")
      Control.ground!(c)
      parent = self()
      once = :atomics.new(1, [])

      Control.register_propagator!(c, %{
        init: fn _ ->
          if :atomics.exchange(once, 1, 1) == 0 do
            send(parent, {:init, self()})
            receive do: (:release -> :ok)
          end

          :ok
        end
      })

      {pid, monitor} = spawn_monitor(fn -> Control.open_solve(c, []) end)
      assert_receive {:init, worker}, 1000
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^monitor, :process, ^pid, :killed}
      send(worker, :release)
      await_idle(c)
      assert Control.solve!(c).status == :satisfiable
    end)
  end

  test "closing a control interrupts a native result wait before queuing cleanup" do
    c = Control.new!()

    try do
      Control.add!(c, """
      1 { place(P,H) : H=1..29 } 1 :- P=1..30.
      :- place(P,H), place(Q,H), P < Q.
      """)

      Control.ground!(c)
      h = Control.open_solve(c, async: true)
      SolveHandle.resume!(h)
      waiter = Task.async(fn -> SolveHandle.result!(h) end)
      await_result_wait(c)
      closer = Task.async(fn -> Control.close(c) end)
      assert :ok == Task.await(closer, 5000)
      assert %Clingo.Result{interrupted: true} = Task.await(waiter, 5000)
    after
      Control.close(c)
    end
  end

  test "cancel and close can race without reviving a cursor" do
    Clingo.with_control([models: :all], fn c ->
      Control.add!(c, "{a;b}.")
      Control.ground!(c)

      for _ <- 1..12 do
        h = Control.open_solve(c, async: true)
        SolveHandle.resume!(h)

        task =
          Task.async(fn ->
            try do
              SolveHandle.cancel!(h)
            rescue
              ArgumentError -> :closed
            end
          end)

        assert :ok = SolveHandle.close(h)
        assert Task.await(task) in [:ok, :closed]
        assert :ok = SolveHandle.close(h)
      end
    end)
  end

  defp await_idle(c, attempts \\ 200)
  defp await_idle(_, 0), do: flunk("lease was not released")

  defp await_idle(c, n) do
    if map_size(:sys.get_state(c.session.dispatcher).leases) != 0 do
      Process.sleep(5)
      await_idle(c, n - 1)
    end
  end

  defp await_result_wait(c, attempts \\ 200)
  defp await_result_wait(_, 0), do: flunk("result wait did not start")

  defp await_result_wait(c, n) do
    case :sys.get_state(c.session.dispatcher).command do
      {:run, [:values_result, _]} ->
        :ok

      _ ->
        Process.sleep(5)
        await_result_wait(c, n - 1)
    end
  end

  defp await_queued(c, attempts \\ 200)
  defp await_queued(_, 0), do: flunk("open was not queued")

  defp await_queued(c, n) do
    if :queue.len(:sys.get_state(c.session.dispatcher).queue) == 0 do
      Process.sleep(5)
      await_queued(c, n - 1)
    end
  end
end
