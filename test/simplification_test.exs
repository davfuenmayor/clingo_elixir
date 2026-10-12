defmodule Clingo.SimplificationTest do
  use ExUnit.Case, async: true
  alias Clingo.{Control, Symbol}

  test "managed options reject typos, duplicates and invalid values before allocation" do
    for opts <- [
          [modles: :all],
          [models: :all, models: 1],
          [logger: :bad],
          [session: [max_queue: 1, max_queue: 2]],
          [context: %{"f" => fn -> 1 end}],
          [symbols: :yes],
          [show: :not_a_show_type],
          [assumptions: [{"a", :yes}]]
        ] do
      assert_raise ArgumentError, fn -> Clingo.solve!("a.", opts) end
    end

    assert_raise ArgumentError, fn -> Clingo.models("a.", collect: false) end
    assert_raise ArgumentError, fn -> Control.new!(files: []) end
  end

  test "option validation covers registrations and specialized CLI helpers" do
    assert_raise ArgumentError, fn -> Clingo.CLI.run!([], directory: "/tmp") end
    assert_raise ArgumentError, fn -> Clingo.CLI.run!([], env: [:bad]) end

    Clingo.with_control(fn c ->
      assert_raise ArgumentError, fn -> Control.register_observer!(c, %{}, replce: true) end
      assert_raise ArgumentError, fn -> Control.register_propagator!(c, %{}, sequential: :yes) end
      assert_raise ArgumentError, fn -> Clingo.Model.snapshot(nil, nil, symbols: :yes) end
    end)
  end

  test "leaf symbols need no session and preserve native value limits" do
    assert Symbol.parse!("2147483647") == Symbol.number(2_147_483_647)
    minimum = Symbol.number(-2_147_483_648)

    result =
      Clingo.solve!("a(@minimum()).",
        symbols: true,
        context: %{"minimum" => fn [] -> minimum end}
      )

    assert hd(hd(result.models).symbols).arguments == [minimum]
    assert to_string(minimum) == "-2147483648"

    for value <- [2_147_483_648, -2_147_483_649, :bad] do
      assert_raise ArgumentError, fn -> Symbol.number(value) end
    end

    assert_raise ArgumentError, fn -> Symbol.string("a" <> <<0>> <> "b") end
  end

  test "concurrent close treats normal teardown as idempotent" do
    c = Control.new!()
    tasks = for _ <- 1..4, do: Task.async(fn -> Control.close(c) end)
    assert Enum.map(tasks, &Task.await/1) == [:ok, :ok, :ok, :ok]
  end

  test "invalid cursor options neither take nor disturb a solve lease" do
    Clingo.with_control(fn c ->
      Control.add!(c, "a.")
      Control.ground!(c)
      assert_raise ArgumentError, fn -> Control.solve!(c, on_model: :bad) end
      assert_raise ArgumentError, fn -> Control.ground!(c, [{"base", []}], contex: %{}) end

      Control.with_solve!(c, fn _ ->
        assert_raise ArgumentError, ~r/unknown option/, fn -> Control.open_solve(c, modles: 2) end
      end)

      assert Control.solve!(c).status == :satisfiable
    end)
  end

  test "one-shot constructor, grounding and solve options reach only their consumer" do
    result =
      Clingo.solve!("a(@f()).",
        models: :all,
        logger: fn _, _ -> :ok end,
        session: [max_queue: 4],
        context: %{"f" => fn [] -> Symbol.number(3) end},
        symbols: true
      )

    assert %Clingo.Result{exhausted: true, models: [%{shown: ["a(3)"]}]} = result
  end

  test "Symbol formatting and encoding agree after updates and control closure" do
    two = %{Symbol.number(1) | value: 2}
    text = %{Symbol.string("old") | value: "new\n\"quoted\""}
    function = %{Symbol.function("old", [two]) | name: "new", positive: false}
    assert to_string(two) == "2"
    assert to_string(function) == "-new(2)"
    assert Symbol.parse!(to_string(text)) == text
    assert inspect(function) == "#Clingo.Symbol<-new(2)>"

    assert Clingo.solve!("a(@f()).", context: %{"f" => fn [] -> function end}).models
           |> hd()
           |> Map.fetch!(:shown) == ["a(-new(2))"]

    refute Map.has_key?(two, :text)
  end

  test "live views and cursor snapshots produce the same copied model values" do
    parent = self()

    result =
      Clingo.solve!("1 {a;b} 1. #minimize {1:a;2:b}.",
        symbols: true,
        on_model_view: fn view ->
          send(parent, {:snapshot, Clingo.ModelView.snapshot!(view, symbols: true)})
          :cont
        end
      )

    for model <- result.models do
      assert_receive {:snapshot, snapshot}
      assert snapshot == model
    end
  end

  test "copied live snapshots survive while escaped live views expire" do
    parent = self()

    snapshot =
      Clingo.with_control(fn c ->
        Control.add!(c, "a(f(2),\"text\"). #show a/2.")
        Control.ground!(c)

        result =
          Control.solve!(c,
            symbols: true,
            on_model_view: fn view ->
              send(parent, {:live, view, Clingo.ModelView.snapshot!(view, symbols: true)})
              :cont
            end
          )

        assert_receive {:live, view, snapshot}
        assert result.models == [snapshot]
        assert_raise ArgumentError, fn -> Clingo.ModelView.snapshot!(view) end
        assert_raise ArgumentError, fn -> Clingo.Model.snapshot(c.session, c.handle) end
        snapshot
      end)

    assert snapshot.shown == Enum.map(snapshot.symbols, &to_string/1)
  end

  test "one-shot streams repeat and unwind failed setup without keeping a control" do
    parent = self()

    stream =
      Clingo.models("a(@f()).",
        context: %{
          "f" => fn [] ->
            send(parent, {:stream_session, Process.get({Clingo, :session})})
            Symbol.number(2)
          end
        }
      )

    for _ <- 1..2 do
      assert Enum.map(stream, & &1.shown) == [["a(2)"]]
      assert_receive {:stream_session, session}
      refute Process.alive?(session.dispatcher)
    end

    stream =
      Clingo.models("a(@f()).",
        context: %{
          "f" => fn [] ->
            send(parent, {:failed_session, Process.get({Clingo, :session})})
            raise "failed grounding"
          end
        }
      )

    assert_raise Clingo.Error, ~r/failed grounding/, fn -> Enum.to_list(stream) end
    assert_receive {:failed_session, session}
    refute Process.alive?(session.dispatcher)
  end

  test "AST construction uses the shared native converter for child and string arrays" do
    alias Clingo.AST

    AST.with_ast(fn s ->
      location = %{
        begin_file: "test",
        end_file: "test",
        begin_line: 1,
        end_line: 1,
        begin_column: 1,
        end_column: 2
      }

      number = AST.symbolic_term!(s, %{location: location, symbol: Symbol.number(42)})

      function =
        AST.function!(s, %{location: location, name: "f", arguments: [number], external: 0})

      assert AST.to_string!(function) == "f(42)"
      assert Enum.map(AST.get!(function, :arguments), &AST.to_string!/1) == ["42"]

      element = AST.theory_unparsed_term_element!(s, %{operators: ["+", "-"], term: number})
      assert AST.get!(element, :operators) == ["+", "-"]
      empty = AST.theory_unparsed_term_element!(s, %{operators: [], term: number})
      assert AST.get!(empty, :operators) == []

      signature =
        AST.theory_atom_definition!(s, %{
          location: location,
          atom_type: 0,
          name: "t",
          arity: 0,
          term: "term",
          guard: nil
        })

      assert AST.get!(signature, :guard) == nil
    end)
  end

  test "native export can be solved again and reification preserves model semantics" do
    source = "1 {a;b} 1. #show a/0. #show b/0."
    aspif = Clingo.Ground.to_string!(source)

    assert Clingo.solve!(aspif, models: :all).models |> Enum.map(& &1.shown) |> Enum.sort() == [
             ["a"],
             ["b"]
           ]

    reify = Clingo.Ground.to_string!(source, format: :reify)
    assert reify =~ "rule("
    assert reify =~ "output(a,"
    assert Clingo.solve!(reify).status == :satisfiable
  end

  test "DIMACS clauses map to copied SAT, UNSAT and empty results" do
    assert %Clingo.Result{models: [%{shown: ["v(1)"]}]} =
             Clingo.Dimacs.solve!("c sample\np cnf 2 2\n1 0\n-2\n0")

    assert Clingo.Dimacs.solve!("p cnf 1 2\n1 0 -1 0").status == :unsatisfiable
    assert Clingo.Dimacs.solve!("p cnf 0 0").models == [%Clingo.Model{number: 1}]
    assert Clingo.Dimacs.solve!("p cnf 0 1\n0").status == :unsatisfiable

    for text <- ["p cnf 1 1\n2 0", "p cnf 1 1\n1", "p cnf 1 2\n1 0", "p cnf -1 0"] do
      assert_raise ArgumentError, fn -> Clingo.Dimacs.solve!(text) end
    end
  end

  test "views reject unknown families, operations and arities before touching native state" do
    for {kind, operation, args} <- [
          {:assignment, :decision_level, [1]},
          {:control, :free, []},
          {:assignment, "nonexistent", []}
        ] do
      view = %Clingo.View{kind: kind}

      assert_raise ArgumentError, ~r/unsupported/, fn ->
        Clingo.View.call!(view, operation, args)
      end
    end
  end

  test "cleanup preserves body exceptions and exposes cleanup errors after success" do
    assert_raise RuntimeError, "body", fn ->
      Clingo.Scope.run(fn -> raise "body" end, fn -> exit(:cleanup) end)
    end

    assert catch_exit(Clingo.Scope.run(fn -> :ok end, fn -> exit(:cleanup) end)) == :cleanup
  end

  test "initialization rollback runs only on failure and preserves throw and exit" do
    cleanup = fn ->
      send(self(), :cleaned)
      raise "cleanup"
    end

    assert Clingo.Scope.on_error(fn -> :kept end, cleanup) == :kept
    refute_receive :cleaned
    assert catch_throw(Clingo.Scope.on_error(fn -> throw(:original) end, cleanup)) == :original
    assert_receive :cleaned
    refute_receive :cleaned
    assert catch_exit(Clingo.Scope.on_error(fn -> exit(:original) end, cleanup)) == :original
    assert_receive :cleaned

    assert_raise RuntimeError, "original", fn ->
      Clingo.Scope.on_error(fn -> raise "original" end, cleanup)
    end

    assert_receive :cleaned
  end

  test "native worker crashes retain their cause instead of becoming solver diagnostics" do
    pid =
      spawn(fn ->
        receive do
          {:"$gen_call", from, _} ->
            GenServer.reply(from, {:error, {:native_worker_exited, :test_failure}})
        end
      end)

    assert catch_exit(Clingo.memory(%Clingo{dispatcher: pid})) ==
             {:clingo_native_worker_exited, :test_failure}
  end

  test "dispatch only translates known normal teardown, preserving timeouts and crashes" do
    {pid, ref} = spawn_monitor(fn -> :ok end)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    assert Clingo.Dispatch.call(pid, :hello) == {:error, :closed}
    {:ok, agent} = Agent.start(fn -> :ok end)
    reason = catch_exit(Clingo.Dispatch.call(agent, {:get, fn _ -> Process.sleep(50) end}, 1))
    assert {:timeout, _} = reason
    Process.exit(agent, :kill)
    {:ok, agent} = Agent.start(fn -> :ok end)
    reason = catch_exit(Clingo.Dispatch.call(agent, {:get, fn _ -> exit(:deliberate_crash) end}))
    assert {:deliberate_crash, _} = reason
  end
end
