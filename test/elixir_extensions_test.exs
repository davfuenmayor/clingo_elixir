defmodule Clingo.ElixirExtensionsTest do
  use ExUnit.Case, async: true
  alias Clingo.{Control, Configuration, Statistics, Backend, AST, View}

  test "configuration paths and copied statistics preserve native semantics" do
    Clingo.with_control(fn c ->
      Configuration.put!(c, ["solve", "models"], "0")
      assert Configuration.get!(c, ["solve", "models"]) == "0"
      assert is_binary(Configuration.description!(c, ["solve", "models"]))
      assert_raise ArgumentError, fn -> Configuration.get!(c, ["absent"]) end
      Control.add!(c, "{a}.")
      Control.ground!(c)
      assert length(Control.solve!(c).models) == 2
      assert is_map(Statistics.snapshot!(c))
    end)
  end

  test "scoped backend closes after exceptions and supports weighted rules" do
    Clingo.with_control(fn c ->
      assert_raise RuntimeError, "builder", fn ->
        Backend.with_backend(c, fn _ -> raise "builder" end)
      end

      Backend.with_backend(c, fn b ->
        atom = Backend.add_atom!(b, Clingo.Symbol.parse!("a"))
        assert :ok = Backend.rule!(b, [atom])
      end)

      assert [%{shown: ["a"]}] = Control.solve!(c).models
    end)
  end

  test "propagators and observers receive converted arguments and ordinary decisions" do
    parent = self()

    Clingo.with_control([models: :all], fn c ->
      Control.register_observer!(c, %{
        rule: fn choice, head, body ->
          send(parent, {:rule, choice, head, body})
          :ok
        end
      })

      Control.register_propagator!(c, %{
        init: fn init ->
          View.check_mode!(init, :clingo_propagator_check_mode_total)
          :ok
        end,
        decide: fn _thread, assignment, fallback ->
          assert is_integer(View.decision_level(assignment))
          fallback
        end,
        check: fn control ->
          send(parent, {:level, View.decision_level(View.assignment(control))})
          :ok
        end
      })

      Control.add!(c, "{a;b}.")
      Control.ground!(c)
      assert length(Control.solve!(c).models) == 4
      assert_receive {:rule, true, [_ | _], []}
      assert_receive {:level, _}
    end)
  end

  test "decoded solve events and live model views preserve callback behavior" do
    parent = self()

    result =
      Clingo.solve!("a.",
        on_finish: fn result -> send(parent, {:finish, result.status}) end,
        on_model_view: fn view ->
          assert Clingo.ModelView.snapshot!(view).shown == ["a"]
          :cont
        end,
        on_statistics: fn step, _ -> Statistics.put!(step, ["custom"], 42) end
      )

    assert result.status == :satisfiable
    assert_receive {:finish, :satisfiable}
  end

  test "AST parsing acquires callback nodes and transforms copies" do
    AST.with_ast(fn s ->
      nodes = AST.parse!(s, "a. b :- a.")
      assert length(nodes) == 3
      original = Enum.at(nodes, 1)
      assert AST.to_string!(original) == "a."

      transformed =
        AST.walk!(original, fn ast ->
          if ast.type == Clingo.constant(:clingo_ast_type_function),
            do: AST.update!(ast, %{name: "renamed"}),
            else: ast
        end)

      assert AST.to_string!(transformed) == "renamed."
      assert AST.to_string!(original) == "a."
      assert_raise ArgumentError, fn -> AST.get!(original, :absent) end
      Enum.each(nodes, &AST.release/1)
    end)
  end

  test "AST updates preserve originals across scalar, array and optional-child changes" do
    AST.with_ast(fn s ->
      location = %{
        begin_file: "test",
        end_file: "test",
        begin_line: 1,
        end_line: 1,
        begin_column: 1,
        end_column: 2
      }

      number = AST.symbolic_term!(s, %{location: location, symbol: Clingo.Symbol.number(1)})

      function =
        AST.function!(s, %{location: location, name: "f", arguments: [number], external: 0})

      updated = AST.update!(function, %{name: "g", arguments: []})
      assert AST.to_string!(updated) == "g"
      assert AST.to_string!(function) == "f(1)"
      assert AST.update!(function, %{}) == function

      changed =
        AST.update!(number, %{
          symbol: Clingo.Symbol.number(2),
          location: %{location | end_column: 3}
        })

      assert AST.to_string!(changed) == "2"
      assert AST.get!(changed, :location).end_column == 3
      assert AST.to_string!(number) == "1"

      element = AST.theory_unparsed_term_element!(s, %{operators: ["+", "-"], term: number})
      assert AST.get!(AST.update!(element, %{operators: [], term: changed}), :operators) == []

      assert AST.get!(AST.update!(element, %{operators: ["*", "/", "-"]}), :operators) == [
               "*",
               "/",
               "-"
             ]

      assert AST.get!(element, :operators) == ["+", "-"]
      guard = AST.theory_guard_definition!(s, %{operators: ["<"], term: "term"})

      atom =
        AST.theory_atom_definition!(s, %{
          location: location,
          atom_type: 0,
          name: "t",
          arity: 0,
          term: "term",
          guard: nil
        })

      guarded = AST.update!(atom, %{guard: guard})
      assert AST.to_string!(AST.get!(guarded, :guard)) == AST.to_string!(guard)
      assert AST.get!(AST.update!(guarded, %{guard: nil}), :guard) == nil
      assert AST.get!(atom, :guard) == nil
      assert_raise ArgumentError, fn -> AST.update!(function, %{absent: 1}) end
      assert AST.to_string!(function) == "f(1)"
    end)
  end

  test "observer symbols are copied while ordinary arrays remain lists" do
    parent = self()

    Clingo.with_control(fn c ->
      Control.register_observer!(c, %{
        output_atom: fn symbol, atom ->
          send(parent, {:output_atom, symbol, atom})
          :ok
        end,
        output_term: fn symbol, condition ->
          send(parent, {:output_term, symbol, condition})
          :ok
        end
      })

      Control.add!(c, "a(1). {b}. #show a/1. #show x : b.")
      Control.ground!(c)
    end)

    assert_receive {:output_atom, %Clingo.Symbol{} = symbol, atom}
    assert to_string(symbol) == "a(1)"
    assert is_integer(atom)
    assert_receive {:output_term, %Clingo.Symbol{} = term, [_ | _] = condition}
    assert to_string(term) == "x"
    assert Enum.all?(condition, &is_integer/1)
  end

  test "hot solve paths and structured models do not accumulate arena storage" do
    Clingo.with_control([models: :all, session: [max_arena: 65_536]], fn c ->
      Control.add!(c, "{a(1..6)}.")
      Control.ground!(c)
      :erlang.garbage_collect()
      before = Clingo.memory(c.session)

      for _ <- 1..40 do
        assert 64 == Enum.count(Control.models(c, symbols: true))
      end

      :erlang.garbage_collect()
      assert elem(Clingo.memory(c.session), 0) <= elem(before, 0)

      for _ <- 1..40 do
        assert Control.solve!(c, assumptions: [{Clingo.Symbol.parse!("a(1)"), true}]).status ==
                 :satisfiable
      end

      :erlang.garbage_collect()
      assert elem(Clingo.memory(c.session), 0) <= elem(before, 0)
    end)
  end

  test "killed consumers release solve leases on a longer lived control" do
    Clingo.with_control([models: :all], fn c ->
      Control.add!(c, "{a;b}.")
      Control.ground!(c)
      parent = self()

      {pid, ref} =
        spawn_monitor(fn ->
          Enum.each(Control.models(c), fn _ ->
            send(parent, :model)

            receive do
              :never -> :ok
            end
          end)
        end)

      assert_receive :model
      assert_raise ArgumentError, ~r/solve_active/, fn -> Control.solve!(c) end
      assert_raise ArgumentError, ~r/solve_active/, fn -> Control.add!(c, "c.") end
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}
      wait_idle(c)
      assert length(Control.solve!(c).models) == 4
    end)
  end

  test "asynchronous scoped handles wait, return copied models and cancel" do
    Clingo.with_control(fn c ->
      Control.add!(c, "{a;b}.")
      Control.ground!(c)

      Control.with_solve!(c, [async: true], fn h ->
        Clingo.SolveHandle.resume!(h)
        assert Clingo.SolveHandle.wait!(h, -1)
        assert %Clingo.Model{} = Clingo.SolveHandle.model!(h)
        task = Task.async(fn -> Clingo.SolveHandle.cancel!(h) end)
        assert :ok = Task.await(task)
        assert %Clingo.Result{} = Clingo.SolveHandle.result!(h)
      end)

      literal = Control.literal(c, "a")

      Control.with_solve!(c, [assumptions: [literal, -literal]], fn h ->
        Clingo.SolveHandle.resume!(h)
        assert Clingo.SolveHandle.model!(h) == nil
        assert Clingo.SolveHandle.result!(h).status == :unsatisfiable
        assert Enum.sort(Clingo.SolveHandle.core!(h)) == Enum.sort([literal, -literal])
        assert Clingo.SolveHandle.last!(h) == nil
      end)

      Control.with_solve!(c, fn h ->
        Clingo.SolveHandle.resume!(h)
        first = Clingo.SolveHandle.model!(h)
        Clingo.SolveHandle.resume!(h)
        assert Clingo.SolveHandle.model!(h) == nil
        assert Clingo.SolveHandle.result!(h).status == :satisfiable
        assert Clingo.SolveHandle.last!(h).shown == first.shown
      end)
    end)
  end

  test "copied atom inspection and the packaged CLI work without native buffers" do
    Clingo.with_control(fn c ->
      Control.add!(c, "a. #external b.")
      Control.ground!(c)
      atoms = Clingo.Inspection.symbolic_atoms!(c)
      assert Enum.any?(atoms, &(to_string(&1.symbol) == "a" and &1.fact))
      assert Enum.any?(atoms, &(to_string(&1.symbol) == "b" and &1.external))
      assert Clingo.Inspection.theory_atoms!(c) == []
    end)

    assert %{exit_code: 0, output: output} = Clingo.CLI.run!(["--version"])
    assert output =~ "5.8.2"
  end

  test "Elixir application and global script hooks run in an isolated VM" do
    {output, status} =
      Clingo.TestSupport.vm(
        [
          "-pa",
          Path.dirname(:code.which(Clingo.Native)),
          "test/fixtures/elixir_hooks.exs"
        ],
        20_000,
        [{"ERL_FLAGS", "+S 2:2 +SDcpu 2 +SDio 1"}]
      )

    assert status == 0, output
    assert output =~ "ELIXIR_HOOKS_PASS"
  end

  defp wait_idle(c, attempts \\ 100)
  defp wait_idle(_c, 0), do: flunk("consumer lease did not drain")

  defp wait_idle(c, attempts) do
    if map_size(:sys.get_state(c.session.dispatcher).leases) != 0 do
      Process.sleep(5)
      wait_idle(c, attempts - 1)
    end
  end
end
