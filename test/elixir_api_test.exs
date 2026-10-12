defmodule Clingo.ElixirAPITest do
  use ExUnit.Case, async: true
  doctest Clingo
  alias Clingo.{Control, Symbol}

  test "copied outcomes distinguish an empty model, UNSAT, and limited enumeration" do
    assert %{status: :satisfiable, models: [%{shown: []}]} = Clingo.solve!("")
    assert %{status: :unsatisfiable, exhausted: true, models: []} = Clingo.solve!(":-.")
    assert %{status: :satisfiable, exhausted: false, models: [_]} = Clingo.solve!("{a;b}.")
    result = Clingo.solve!("1 {a;b} 1.", models: :all, symbols: true)
    assert Enum.sort(Enum.map(result.models, & &1.shown)) == [["a"], ["b"]]
    assert result.exhausted
    assert Enum.all?(result.models, &match?([%Symbol{}], &1.symbols))
  end

  test "symbol values round trip nested terms, signs, strings and bounds" do
    for text <- ["f(1,\"hello\")", "-a", "(1,2)", "#inf", "#sup", "\"a\\\"b\""] do
      symbol = Symbol.parse!(text)
      assert to_string(Symbol.parse!(to_string(symbol))) == to_string(symbol)
    end

    assert to_string(Symbol.function("f", [Symbol.number(2)], false)) == "-f(2)"
    assert Symbol.string("a\nb").value == "a\nb"
  end

  test "multi shot external assignments and assumptions keep one control" do
    Clingo.with_control([models: :all], fn c ->
      assert :ok = Control.add!(c, "#external a. b :- not a.")
      assert :ok = Control.ground!(c)
      assert [%{shown: ["b"]}] = Control.solve!(c).models
      Control.assign_external!(c, Symbol.parse!("a"), true)
      assert [%{shown: ["a"]}] = Control.solve!(c).models
      Control.assign_external!(c, "a", :free)

      assert Control.solve!(c, assumptions: [{Symbol.parse!("missing"), true}]).status ==
               :unsatisfiable

      assert Control.solve!(c, assumptions: [{Symbol.parse!("missing"), false}]).status ==
               :satisfiable
    end)
  end

  test "ground context receives values and emits symbols without native plumbing" do
    result = Clingo.solve!("a(@value()).", context: %{"value" => fn [] -> Symbol.number(42) end})
    assert [%{shown: ["a(42)"]}] = result.models

    for bad <- [nil, :invalid, [42]] do
      assert_raise Clingo.Error, ~r/grounding function value at <block>:1/, fn ->
        Clingo.solve!("a(@value()).", context: %{"value" => fn [] -> bad end})
      end
    end

    assert_raise Clingo.Error, ~r/unknown grounding function/, fn ->
      Clingo.solve!("a(@unknown()).", context: %{})
    end
  end

  test "snapshot callbacks, early enumeration and exceptions release handles" do
    parent = self()

    result =
      Clingo.solve!("{a;b}.",
        models: :all,
        collect: false,
        on_model: fn model ->
          send(parent, model.shown)
          :halt
        end
      )

    assert result.models == []
    assert_receive []
    stream = Clingo.models("{a;b;c}.", models: :all)
    assert length(Enum.take(stream, 2)) == 2
    assert length(Enum.to_list(stream)) == 8

    Clingo.with_control([models: :all], fn c ->
      Control.add!(c, "{a;b}.")
      Control.ground!(c)
      assert length(Enum.take(Control.models(c), 1)) == 1

      assert_raise RuntimeError, "consumer", fn ->
        Enum.each(Control.models(c), fn _ -> raise "consumer" end)
      end

      assert length(Control.solve!(c).models) == 4
    end)
  end

  test "optimization keeps cost and actual optimality evidence" do
    result = Clingo.solve!("1 {a;b} 1. #minimize {1:a;2:b}.", arguments: ["--opt-mode=optN"])
    assert result.status == :satisfiable
    assert Enum.any?(result.models, &(&1.cost == [1] and &1.optimality_proven))

    # Same lower-bound fixture as pinned libpyclingo/tests/test_control.py.
    parent = self()

    lower_result =
      Clingo.solve!(
        "1 { p(X); q(X) } 1 :- X=1..3. #minimize { 1,p,X: p(X); 1,q,X: q(X) }.",
        arguments: ["--opt-str=usc,oll,0", "--stats=2"],
        on_unsat: fn lower -> send(parent, {:lower, lower}) end
      )

    assert lower_result.status == :satisfiable
    for bound <- [[1], [2], [3]], do: assert_receive({:lower, ^bound})
  end

  test "native option conflicts are explicit and invalid programs raise" do
    assert_raise ArgumentError, ~r/conflicts/, fn ->
      Clingo.solve!("a.", models: :all, arguments: ["0"])
    end

    assert_raise Clingo.Error, fn -> Clingo.solve!("invalid (") end
  end
end
