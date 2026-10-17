defmodule Clingo.LivebookCheck do
  @moduledoc false

  # Discover executable material directly; no parallel content manifest.
  def inventory(root) do
    root = Path.expand(root)
    directory = Path.join(root, "livebooks")

    for path <- Path.wildcard(Path.join(directory, "**/*.livemd")) do
      text = File.read!(path)

      cells =
        Regex.scan(~r/^```elixir\n(.*?)^```/ms, text, capture: :all_but_first) |> List.flatten()

      %{
        "livebook" => Path.relative_to(path, directory),
        "code_cells" => length(cells),
        "policies" => Enum.map(Enum.drop(cells, 1), &policy/1)
      }
    end
  end

  defp policy(cell) do
    cond do
      cell =~ "if exercise_runs" -> "pending_exercise"
      cell =~ "Course.expect_error(" -> "expected_error"
      cell =~ "File.rm_rf!(workdir)" -> "cleanup"
      true -> "native_example"
    end
  end

  # Livebook's parser distinguishes executable cells from illustrative fences.
  def validate_cells!(cells, expected) do
    unless length(cells) == expected and
             Enum.all?(cells, &(&1.language == :elixir and String.trim(&1.source) != "")) do
      raise "expected #{expected} nonempty Elixir executable cells"
    end
  end

  def status(evals) do
    cond do
      Enum.any?(evals, &(&1.errored or &1.interrupted or &1.validity == :aborted)) -> :failed
      evals != [] and Enum.all?(evals, &(&1.validity == :evaluated)) -> :passed
      true -> :pending
    end
  end

  def fingerprints(root) do
    root = Path.expand(root)
    paths =
      [
        "livebooks/**/*.livemd",
        "livebooks/support/*",
        "livebooks/assets/**/*",
        "lib/**/*",
        "c_src/**/*",
        "priv/*",
        "mix.exs",
        "mix.lock",
        "Makefile",
        "tools/api_scope.json",
        "tools/check_livebooks.exs",
        "tools/index_livebooks.py",
        "test/**/*",
        "tools/livebook_check.exs",
        "tools/livebook_runtime_check.exs",
        "tools/check_livebooks_runtime.py",
        "tools/check_livebooks_runtime.exs"
      ]
      |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
      |> Enum.filter(&File.regular?/1)
      |> Enum.uniq()
      |> Enum.sort()

    Map.new(paths, fn path ->
      hash = File.read!(path) |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
      {Path.relative_to(path, root), hash}
    end)
  end
end
