defmodule Clingo.LearningMaterialTest do
  use ExUnit.Case, async: true
  @root Path.expand("..", __DIR__)
  test "language exercise hints agree with modified worked programs" do
    recursion = program("language/02-negation-and-recursion", "reached(dock).")
    assert [%{shown: []}] = Clingo.solve!(String.replace(recursion, "reached(dock).", "")).models

    choice = program("language/03-choices-and-constraints", "1 { assigned")

    assert length(
             Clingo.solve!(String.replace(choice, "1 { assigned", "0 { assigned"), models: :all).models
           ) == 3

    conditional = program("language/05-aggregates-and-conditionals", "complete :-")
    assert [%{shown: ["complete"]}] = Clingo.solve!(conditional <> " ok(blue).").models
    empty_domain = String.replace(conditional, "required(red;blue).", "")
    assert [%{shown: ["complete"]}] = Clingo.solve!(empty_domain).models

    optimized =
      program("language/06-optimization-and-projection", "fare(bus,3).")
      |> String.replace("fare(bus,3).", "fare(bus,1).")

    optimal =
      Clingo.solve!(optimized, models: :all, arguments: ["--opt-mode=optN"]).models
      |> Enum.filter(& &1.optimality_proven)

    assert Enum.sort(Enum.map(optimal, & &1.shown)) == [["take(bus)"], ["take(tram)"]]
    assert Enum.all?(optimal, &(&1.cost == [1]))
  end

  test "modeling exercise hints agree with modified worked programs" do
    graph = program("modeling/01-graphs-and-sets", "picked(V) : vertex(V)")
    assert Clingo.solve!(graph <> " edge(1,3).").status == :unsatisfiable

    grid = program("modeling/02-grids-and-puzzles", "cell(Row,Col,Value)")

    assert Clingo.solve!(grid <> " :- not cell(1,1,1). :- not cell(1,2,1).").status ==
             :unsatisfiable

    planning = program("planning/01-actions-and-robots", "place(depot;hall;yard;lab).")

    assert length(
             Clingo.solve!(String.replace(planning, "edge(depot,yard).", ""), models: :all).models
           ) == 1

    scheduling = program("planning/01-actions-and-robots", "job(polish;pack).")

    assert length(
             Clingo.solve!(String.replace(scheduling, "slot(1..2).", "slot(1..3)."), models: :all).models
           ) == 6

    classifier = program("modeling/03-learning-and-configuration", "positive(sample1).")
    assert Clingo.solve!(classifier <> " has(sample2,stripes).").status == :unsatisfiable
    product = program("modeling/03-learning-and-configuration", "frame(compact;cargo).")
    unconstrained = String.replace(product, ":- fitted_frame(compact), fitted_motor(heavy).", "")
    assert length(Clingo.solve!(unconstrained, models: :all).models) == 4
  end

  defp program(slug, contains) do
    text = File.read!(Path.join([@root, "livebooks", slug <> ".livemd"]))

    code =
      Regex.scan(~r/^```elixir\n(.*?)^```/ms, text, capture: :all_but_first)
      |> List.flatten()
      |> Enum.filter(&String.contains?(&1, "~S\"\"\""))
      |> Enum.find(&String.contains?(&1, contains))

    {_, program} =
      Macro.prewalk(Code.string_to_quoted!(code), nil, fn
        {:sigil_S, _, _} = literal, _ ->
          {program, []} = Code.eval_quoted(literal)
          {literal, program}

        node, program ->
          {node, program}
      end)

    program
  end
end
