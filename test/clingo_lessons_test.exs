defmodule Clingo.LessonsTest do
  use ExUnit.Case, async: true
  @root Path.expand("../livebooks", __DIR__)
  test "dinosaur, quadrilateral and guilt examples derive the stated answers" do
    dinosaur = solve_last("language/01-facts-and-rules", "Classify creatures with rules")
    assert [%{shown: ["resembles_dinosaur(riley)"]}] = dinosaur.models

    quadrilaterals =
      solve_last("language/01-facts-and-rules", "Express alternatives without body disjunction")

    assert [model] = quadrilaterals.models

    assert model.shown ==
             Enum.sort(
               for shape <- [
                     "rectangle",
                     "square",
                     "rhombus",
                     "parallelogram",
                     "trapezium",
                     "kite"
                   ],
                   do: "four_sided(\"#{shape}\")"
             )

    guilty = solve_last("language/02-negation-and-recursion", "Reason with missing evidence")
    assert [model] = guilty.models
    assert "implicated(alex)" in model.shown
    assert "cleared(blair)" in model.shown
    refute "implicated(blair)" in model.shown
  end

  test "classical negation retains both choices for Pip" do
    result =
      solve_last(
        "language/02-negation-and-recursion",
        "Distinguish explicit and default negation"
      )

    assert result.exhausted
    assert Enum.sort(Enum.map(result.models, & &1.shown)) == [[], ["airborne(pip)"]]
  end

  test "Hanoi generator is bounded and the complete encoding yields valid plans" do
    programs = programs("planning/01-actions-and-robots", "Plan legal disc transfers")
    {generator, 1} = Enum.at(programs, 3)
    result = Clingo.solve!(generator, models: 1)
    assert result.status == :satisfiable
    refute result.exhausted
    assert length(result.models) == 1
    result = solve_last("planning/01-actions-and-robots", "Plan legal disc transfers")
    assert result.status == :satisfiable
    assert result.exhausted
    assert result.models != []

    for model <- result.models do
      moves =
        Enum.map(model.shown, fn atom ->
          [disk, peg, time] =
            Regex.run(~r/^transfer\((\d+),(left|middle|right),(\d+)\)$/, atom,
              capture: :all_but_first
            )

          {String.to_integer(time), String.to_integer(disk), peg}
        end)
        |> Enum.sort()

      assert Enum.map(moves, &elem(&1, 0)) == Enum.to_list(1..15)
      # Disk 4 is the smallest physical disk.
      final =
        Enum.reduce(moves, %{1 => "left", 2 => "left", 3 => "left", 4 => "left"}, fn {_, disk,
                                                                                      target},
                                                                                     positions ->
          source = positions[disk]
          refute source == target

          refute Enum.any?(positions, fn {other, peg} ->
                   other > disk and peg in [source, target]
                 end)

          Map.put(positions, disk, target)
        end)

      assert Enum.all?(final, fn {_, peg} -> peg == "right" end)
    end
  end

  defp solve_last(path, section) do
    {program, :all} = programs(path, section) |> List.last()
    Clingo.solve!(program, models: :all)
  end

  defp programs(path, section) do
    Path.join(@root, path <> ".livemd")
    |> File.read!()
    |> String.split("\n## " <> section <> "\n", parts: 2)
    |> List.last()
    |> String.split("\n## ", parts: 2)
    |> List.first()
    |> code_cells()
    |> Enum.flat_map(fn cell ->
      case program_and_limit(cell) do
        {nil, nil} -> []
        pair -> [pair]
      end
    end)
  end

  defp program_and_limit(cell) do
    {_, pair} =
      Macro.prewalk(Code.string_to_quoted!(cell), {nil, nil}, fn
        {:sigil_S, _, _} = literal, {_, limit} ->
          {program, []} = Code.eval_quoted(literal)
          {literal, {program, limit}}

        {{:., _, [{:__aliases__, _, [:Clingo]}, :solve!]}, _, args} = call, {program, _} ->
          {call, {program, args |> List.last() |> Keyword.fetch!(:models)}}

        node, pair ->
          {node, pair}
      end)

    pair
  end

  defp code_cells(text) do
    Regex.scan(~r/^```elixir\n(.*?)^```/ms, text, capture: :all_but_first) |> List.flatten()
  end
end
