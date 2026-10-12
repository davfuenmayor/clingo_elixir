defmodule Clingo.TransientStorageTest do
  use ExUnit.Case, async: true
  alias Clingo.{Control, Inspection, ModelView, Statistics, Symbol}

  test "repeated solve hooks reclaim arena storage and Elixir registrations" do
    Clingo.with_control([session: [max_arena: 131_072]], fn c ->
      Control.add!(c, "{a;b}.")
      Control.ground!(c)

      opts = [
        on_finish: fn _ -> :ok end,
        on_statistics: fn step, _ -> Statistics.put!(step, ["custom"], 42) end,
        on_model_view: fn view ->
          assert %Clingo.Model{} = ModelView.snapshot!(view)
          :cont
        end
      ]

      assert Control.solve!(c, opts).status == :satisfiable
      before = retained(c)
      for _ <- 1..300, do: assert(Control.solve!(c, opts).status == :satisfiable)
      assert retained(c) <= before + 1024
      assert :sys.get_state(c.session.dispatcher).callbacks == %{}
    end)
  end

  test "grounding contexts and failure rollback do not retain callback functions" do
    Clingo.with_control([session: [max_arena: 131_072]], fn c ->
      Control.add!(c, "part", [], "a(@value()).")
      context = %{"value" => fn [] -> Symbol.number(42) end}
      Control.ground!(c, [{"part", []}], context: context)
      before = retained(c)

      for i <- 1..300 do
        if rem(i, 30) == 0 do
          assert_raise Clingo.Error, ~r/unknown grounding function/, fn ->
            Control.ground!(c, [{"part", []}], context: %{})
          end
        end

        Control.ground!(c, [{"part", []}], context: context)
      end

      assert retained(c) <= before + 1024
      assert :sys.get_state(c.session.dispatcher).callbacks == %{}
      assert [%{shown: ["a(42)"]}] = Control.solve!(c).models
    end)
  end

  test "symbolic and theory inspection keep copied results without accumulating output cells" do
    snapshots =
      Clingo.with_control([session: [max_arena: 524_288]], fn c ->
        Control.add!(c, """
        p(1..100).
        #theory t { term { + : 1, binary, left }; &a/0 : term, {=}, term, any }.
        &a { 1+2 : p(1) } = 3.
        """)

        Control.ground!(c)
        first = {Inspection.symbolic_atoms!(c), Inspection.theory_atoms!(c)}
        before = retained(c)

        for _ <- 1..200 do
          assert length(Inspection.symbolic_atoms!(c)) == 100
          assert [%{guard: {"=", "3"}, elements: [_]}] = Inspection.theory_atoms!(c)
        end

        assert retained(c) <= before + 1024
        first
      end)

    {atoms, [%{elements: [element]}]} = snapshots
    assert Enum.any?(atoms, &(to_string(&1.symbol) == "p(100)"))
    assert element.terms == ["(1+2)"]
  end

  test "escaped callback views, casts and saved cells stay expired across reclamation" do
    Clingo.with_control(fn c ->
      Control.add!(c, "a.")
      Control.ground!(c)
      cell = Clingo.alloc(c.session, "clingo_model_t*")
      parent = self()

      Control.solve!(c,
        on_model_view: fn view ->
          alias = Clingo.cast(c.session, view.handle, "clingo_model_t")
          Clingo.write(c.session, cell, alias)
          send(parent, {:view, view, alias})
          :cont
        end
      )

      assert_receive {:view, view, alias}

      for _ <- 1..100 do
        Control.solve!(c, on_model_view: fn _ -> :cont end)
        retained(c)
      end

      assert_raise ArgumentError, fn -> ModelView.snapshot!(view) end

      assert_raise ArgumentError, fn ->
        Clingo.values(c.session, :values_snapshot, [alias, 2, false])
      end

      assert_raise ArgumentError, fn -> Clingo.read(c.session, cell) end
    end)
  end

  test "control-lifetime observers and propagators survive transient retirement" do
    Clingo.with_control([session: [max_arena: 131_072]], fn c ->
      counter = :atomics.new(1, [])

      Control.register_observer!(c, %{
        rule: fn _, _, _ ->
          :atomics.add(counter, 1, 1)
          :ok
        end
      })

      Control.register_propagator!(c, %{
        init: fn _ ->
          :atomics.add(counter, 1, 1)
          :ok
        end
      })

      registrations = map_size(:sys.get_state(c.session.dispatcher).callbacks)
      Control.add!(c, "a.")
      Control.ground!(c)
      Control.solve!(c)
      before = retained(c)
      for _ <- 1..300, do: Control.solve!(c, on_finish: fn _ -> :ok end)
      assert :atomics.get(counter, 1) >= 302
      assert retained(c) <= before + 1024
      assert map_size(:sys.get_state(c.session.dispatcher).callbacks) == registrations
    end)
  end

  test "a failed solve hook retires its registration and releases the lease" do
    Clingo.with_control(fn c ->
      Control.add!(c, "a.")
      Control.ground!(c)

      for _ <- 1..30 do
        assert_raise Clingo.Error, ~r/failed hook/, fn ->
          Control.solve!(c, on_model_view: fn _ -> raise "failed hook" end)
        end

        assert :sys.get_state(c.session.dispatcher).callbacks == %{}
        assert :sys.get_state(c.session.dispatcher).leases == %{}
        assert Control.solve!(c).status == :satisfiable
      end
    end)
  end

  test "solve-event failures become errors without terminating the VM, including async events" do
    for event <- [:on_unsat, :on_statistics, :on_finish], async <- [false, true] do
      Clingo.with_control([arguments: ["--opt-str=usc,oll,0", "--stats=2"]], fn c ->
        Control.add!(c, "1 { p(X); q(X) } 1 :- X=1..3. #minimize { 1,p,X: p(X); 1,q,X: q(X) }.")
        Control.ground!(c)

        hook =
          if event == :on_statistics,
            do: fn _, _ -> raise "deferred hook" end,
            else: fn _ -> raise "deferred hook" end

        assert_raise Clingo.Error, ~r/deferred hook/, fn ->
          Control.solve!(c, [{event, hook}, {:async, async}])
        end

        assert :sys.get_state(c.session.dispatcher).leases == %{}
        assert :sys.get_state(c.session.dispatcher).callbacks == %{}
        assert Control.solve!(c).status == :satisfiable
      end)
    end
  end

  test "configuration, statistics and backend scopes retire copied output cells" do
    Clingo.with_control([session: [max_arena: 524_288]], fn c ->
      Control.add!(c, "#const n=42. a.")
      Control.ground!(c)
      Control.solve!(c)
      before = retained(c)

      for _ <- 1..100 do
        Clingo.Configuration.put!(c, ["solve", "models"], "1")
        assert Clingo.Configuration.get!(c, ["solve", "models"]) == "1"
        assert is_binary(Clingo.Configuration.description!(c, ["solve", "models"]))
        assert is_map(Statistics.snapshot!(c))
        assert Control.get_const!(c, "n") == Symbol.number(42)
        assert :ok = Clingo.Backend.with_backend(c, fn _ -> :ok end)
      end

      assert retained(c) <= before + 1024
    end)
  end

  test "a single hook-heavy enumeration stays within its arena quota" do
    Clingo.with_control([models: :all, session: [max_arena: 262_144]], fn c ->
      Control.add!(c, "{a(1..10)}.")
      Control.ground!(c)
      assert Enum.count(Control.models(c, on_model_view: fn _ -> :cont end)) == 1024
      assert :sys.get_state(c.session.dispatcher).callbacks == %{}
    end)
  end

  # BEAM resource collection governs how long intentionally escaped identities
  # survive. Measure retained native storage, independently of that GC schedule.
  defp retained(c) do
    await_callbacks(c, 1000)
    :erlang.garbage_collect()
    :erlang.garbage_collect(c.session.dispatcher)
    :erlang.garbage_collect(:sys.get_state(c.session.dispatcher).workers)
    elem(Clingo.memory(c.session), 0)
  end

  defp await_callbacks(_c, 0), do: flunk("callback workers did not drain")

  defp await_callbacks(c, attempts) do
    unless :sys.get_state(c.session.dispatcher).pending == %{} do
      Process.sleep(1)
      await_callbacks(c, attempts - 1)
    end
  end
end
