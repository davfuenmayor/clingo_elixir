defmodule Clingo.LivebooksTest do
  use ExUnit.Case, async: true
  @root Path.expand("../livebooks", __DIR__)
  Code.require_file(Path.join(@root, "support/course.exs"))

  test "teaching notebooks have one setup and stay within the topic budget" do
    paths = Path.wildcard(Path.join(@root, "*/*.livemd"))
    assert length(paths) in 10..20
    assert Path.wildcard(Path.join(@root, "*.livemd")) == [Path.join(@root, "intro.livemd")]

    topics =
      paths
      |> Enum.map(&Path.relative_to(&1, @root))
      |> Enum.filter(&String.contains?(&1, "/"))
      |> Enum.map(&Path.dirname/1)
      |> Enum.uniq()
      |> Enum.sort()

    assert topics == [
             "elixir",
             "extensions",
             "language",
             "modeling",
             "planning"
           ]

    for path <- paths do
      text = File.read!(path)
      assert length(Regex.scan(~r/Mix\.install\(/, text)) == 1
      assert text =~ "Clingo."

      for [cell] <- Regex.scan(~r/^```elixir\n(.*?)^```/ms, text, capture: :all_but_first),
          do: assert({:ok, _} = Code.string_to_quoted(cell))

      refute text =~ ~r/upstream-|provenance|Source concept:|Credits and rights|\.ipynb/
    end
  end

  test "relative Markdown links and figures resolve" do
    paths = Path.wildcard(Path.join(@root, "**/*.livemd"))

    paths =
      paths ++ Enum.map(["README.md", "CONCEPTS.md", "VALIDATION.md"], &Path.join(@root, &1))

    for path <- paths do
      links =
        Regex.scan(~r/!?\[[^\]]*\]\(([^)]+)\)/, File.read!(path), capture: :all_but_first)
        |> List.flatten()

      for link <- links,
          not String.starts_with?(link, ["http:", "https:", "mailto:", "data:"]) do
        [relative | fragment] = String.split(link, "#", parts: 2)
        target = if relative == "", do: path, else: Path.expand(relative, Path.dirname(path))

        assert File.exists?(target),
               "broken #{link} in #{path}"

        if fragment != [] do
          headings =
            File.read!(target)
            |> String.replace(~r/^```[^\n]*\n.*?^```/ms, "")
            |> then(&Regex.scan(~r/^\#{1,6} (.+)$/m, &1, capture: :all_but_first))
            |> List.flatten()
            |> Enum.map(fn title ->
              title
              |> String.downcase()
              |> String.replace(~r/[^\w\s-]/u, "")
              |> String.trim()
              |> String.replace(" ", "-")
            end)

          assert hd(fragment) in headings, "broken section #{link} in #{path}"
        end
      end
    end
  end

  test "exercise writes are isolated and solver results preserve satisfiability" do
    source = Path.join(System.tmp_dir!(), "course-source-#{System.unique_integer([:positive])}")
    File.mkdir_p!(source)
    File.write!(Path.join(source, "original.lp"), "a.")
    workspace = ASPCourse.workspace(source)

    try do
      ASPCourse.write(workspace, "original.lp", "b.")
      assert File.read!(Path.join(source, "original.lp")) == "a."

      assert %{models: [%{shown: ["b"]}], status: :satisfiable, exhausted: true} =
               Clingo.solve!(files: [Path.join(workspace, "original.lp")], models: :all)

      assert %{models: [], status: :unsatisfiable} = Clingo.solve!("a. :- a.")
    after
      File.rm_rf!(source)
      File.rm_rf!(workspace)
    end
  end

  test "every asset belongs to a lesson, without bundled tools or duplicate content" do
    assets = Path.wildcard(Path.join(@root, "assets/**/*")) |> Enum.filter(&File.regular?/1)

    links =
      for notebook <- Path.wildcard(Path.join(@root, "**/*.livemd")),
          [link] <-
            Regex.scan(~r/\[[^\]]*\]\(([^)]+)\)/, File.read!(notebook), capture: :all_but_first),
          do: Path.expand(link, Path.dirname(notebook))

    for asset <- assets do
      assert asset in links, "unreferenced asset: #{asset}"
      assert Path.extname(asset) in [".lp", ".json", ".coom"], "unexpected asset: #{asset}"
    end

    assert length(Enum.uniq_by(assets, &File.read!/1)) == length(assets)
    workspace = ASPCourse.workspace()
    on_exit(fn -> File.rm_rf!(workspace) end)
    assert File.ls!(workspace) == []
  end

  test "readable modeling references preserve the complete projected solution sets" do
    for {book, exercises} <- [
          {"modeling/01-graphs-and-sets.livemd",
           ["hitting", "independent", "cover", "dominating", "satisfiability"]},
          {"modeling/02-grids-and-puzzles.livemd", ["latin"]}
        ] do
      references =
        File.read!(Path.join(@root, book))
        |> String.split("### Compare with the reference\n")
        |> Enum.drop(1)

      assert length(references) == length(exercises)

      for {section, exercise} <- Enum.zip(references, exercises) do
        [_, program] = Regex.run(~r/~S"""\n(.*?)"""/s, section)
        input = if exercise == "cover", do: "independent", else: exercise
        instance = Path.join(@root, "assets/modeling/instances/instance-#{input}.lp")
        reference = Path.join(@root, "assets/modeling/solutions/#{exercise}.lp")
        worked = Clingo.solve!(program, files: [instance], models: :all)
        supplied = Clingo.solve!(files: [instance, reference], models: :all)
        assert worked.exhausted and supplied.exhausted
        assert worked.models != []

        assert Enum.sort(Enum.map(worked.models, & &1.shown)) ==
                 Enum.sort(Enum.map(supplied.models, & &1.shown))
      end
    end
  end

  test "file-only solve, streams and export preserve includes, contexts and model options" do
    dir = ASPCourse.workspace()
    on_exit(fn -> File.rm_rf!(dir) end)
    ASPCourse.write(dir, "domain.lp", "a.")
    file = Path.join(dir, "problem.lp")
    File.write!(file, "#include \"domain.lp\". {b}. c(@value()).")

    opts = [
      files: [file],
      models: :all,
      context: %{"value" => fn [] -> Clingo.Symbol.number(7) end}
    ]

    result = Clingo.solve!(opts)
    assert result.exhausted
    assert Enum.sort(Enum.map(result.models, & &1.shown)) == [["a", "b", "c(7)"], ["a", "c(7)"]]
    stream = Clingo.models(opts)
    assert Enum.to_list(stream) == result.models
    assert Enum.to_list(stream) == result.models
    assert Clingo.solve!(":- b.", opts).models |> hd() |> Map.fetch!(:shown) == ["a", "c(7)"]
    aspif = Clingo.Ground.to_string!(opts)
    assert Clingo.solve!(aspif, models: :all).models == result.models
    assert Clingo.Ground.to_string!(Keyword.put(opts, :format, :reify)) =~ "rule("
  end

  test "options-only entry points reject invalid options before solving" do
    for call <- [&Clingo.solve!/1, &Clingo.models/1, &Clingo.Ground.to_string!/1] do
      assert_raise ArgumentError, ~r/unknown option/, fn -> call.(modles: :all) end
      assert_raise ArgumentError, ~r/duplicate/, fn -> call.(files: [], files: []) end
    end
  end

  test "course export uses the native backend without a CLI" do
    workspace = ASPCourse.workspace()
    on_exit(fn -> File.rm_rf!(workspace) end)
    assert Clingo.Ground.to_string!("a.") =~ "asp 1 0 0"
    assert Clingo.Ground.to_string!("{a;b}.", format: :reify) =~ "rule(choice("
    refute function_exported?(ASPCourse, :cli, 3)
    refute function_exported?(ASPCourse, :native_shell, 2)
  end

  test "Livebook executable cells never invoke a CLI or shell" do
    for path <- Path.wildcard(Path.join(@root, "**/*.livemd")),
        [source] <-
          Regex.scan(~r/^```elixir\n(.*?)^```/ms, File.read!(path), capture: :all_but_first) do
      refute source =~
               ~r/(?:System\.(?:cmd|shell)|Port\.open|Clingo\.CLI\.|Course\.(?:cli|native_shell))/,
             "subprocess in #{path}"

      refute source =~ ~r/Course\.(?:solve|ground)\(/, "hidden solver API in #{path}"
      refute source =~ ~r/arguments: \["0"\]/, "CLI model limit in #{path}"
      refute source =~ ~r/~S"""\s*"""/, "empty heredoc in #{path}"
    end

    refute File.read!(Path.join(@root, "support/course.exs")) =~ "System.cmd"
  end

  test "expected native errors do not hide successful or unrelated failures" do
    assert %{expected_error: "parsing failed"} =
             ASPCourse.expect_error(fn -> Clingo.solve!("a(") end)

    assert_raise RuntimeError, ~r/unexpectedly succeeded/, fn ->
      ASPCourse.expect_error(fn -> Clingo.solve!("a.") end)
    end

    assert_raise ArgumentError, "unrelated", fn ->
      ASPCourse.expect_error(fn -> raise ArgumentError, "unrelated" end)
    end
  end

  test "topic navigation links every teaching notebook" do
    intro = File.read!(Path.join(@root, "README.md"))

    for path <- Path.wildcard(Path.join(@root, "*/*.livemd")) do
      assert intro =~ "](" <> Path.relative_to(path, @root) <> ")"
    end
  end

  test "model tables retain empty shown sets, costs and optimality independently" do
    result = %Clingo.Result{
      models: [
        %Clingo.Model{number: 1, shown: [], cost: [4, -2], optimality_proven: false},
        %Clingo.Model{number: 2, shown: ["a", "b"], cost: [0, -2], optimality_proven: true}
      ]
    }

    assert [
             %{model: 1, shown: "", cost: "[4, -2]", optimality_proven: false},
             %{model: 2, shown: "a b", cost: "[0, -2]", optimality_proven: true}
           ] = ASPCourse.table_data(result)

    assert ASPCourse.table_data(%Clingo.Result{status: :unsatisfiable}) == []
  end
end
