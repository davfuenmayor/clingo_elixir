defmodule Clingo.LivebookProseTest do
  use ExUnit.Case, async: true
  @root Path.expand("../livebooks", __DIR__)
  test "rewritten numerical explanations match the actual workload program" do
    program =
      cell_program("language/04-domains-and-grounding.livemd", "hours_per_semester(Cr * H)")

    assert [%{shown: ["hours_per_semester(900)", "hours_per_week(42)"]}] =
             Clingo.solve!(program).models

    program = String.replace(program, "hours_per_credit(30).", "hours_per_credit(25).")

    assert [%{shown: ["hours_per_semester(750)", "hours_per_week(35)"]}] =
             Clingo.solve!(program).models
  end

  test "bike and Latin-square counts in the rewritten lessons match their files" do
    root = Path.join(@root, "assets/configuration")

    result =
      Clingo.solve!(
        files: [
          Path.join(root, "configuration.lp"),
          Path.join(root, "instances/bike-1-basic.lp")
        ],
        models: :all
      )

    expected = File.read!(Path.join(root, "solutions/bike-1-basic.json")) |> JSON.decode!()
    assert result.exhausted == expected["exhausted"]
    assert Atom.to_string(result.status) == expected["status"]
    assert length(result.models) == 4
    assert Enum.sort(Enum.map(result.models, &Enum.sort(&1.shown))) == expected["models"]

    path = Path.join(@root, "assets/propagators/latin.lp")
    result = Clingo.solve!(files: [path], models: :all)
    assert result.exhausted
    assert length(result.models) == 4
    unrestricted = File.read!(path) |> String.replace("latin(1,1,1).", "")
    assert length(Clingo.solve!(unrestricted, models: :all).models) == 12
  end

  defp cell_program(path, contains) do
    text = File.read!(Path.join(@root, path))

    source =
      Regex.scan(~r/^```elixir\n(.*?)^```/ms, text, capture: :all_but_first)
      |> List.flatten()
      |> Enum.find(&String.contains?(&1, contains))

    {_, program} =
      Macro.prewalk(Code.string_to_quoted!(source), nil, fn
        {:sigil_S, _, _} = literal, _ ->
          {program, []} = Code.eval_quoted(literal)
          {literal, program}

        node, program ->
          {node, program}
      end)

    program
  end
end
