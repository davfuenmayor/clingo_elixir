# Elixir cell evaluator; the optional RPC checker uses Livebook's actual parser/runtime.
root = Path.expand("..", __DIR__)
Mix.install([{:clingo_elixir, path: root}, {:kino, "== 0.19.0"}])
Code.require_file(Path.join(root, "livebooks/support/course.exs"))
Code.require_file(Path.join(root, "tools/livebook_check.exs"))

defmodule CourseCheck do
  def run(root) do
    notebooks = Clingo.LivebookCheck.inventory(root)

    check_downloads!()

    results =
      Enum.map(notebooks, fn notebook ->
        path = Path.join([root, "livebooks", notebook["livebook"]])
        parent = self()

        {pid, ref} =
          spawn_monitor(fn -> send(parent, {:result, self(), evaluate(path, notebook)}) end)

        result =
          receive do
            {:result, ^pid, result} ->
              Process.demonitor(ref, [:flush])
              result

            {:DOWN, ^ref, :process, ^pid, reason} ->
              %{path: notebook["livebook"], failure: inspect(reason)}
          after
            120_000 ->
              Process.exit(pid, :kill)
              %{path: notebook["livebook"], failure: "120 second notebook deadline exceeded"}
          end

        IO.puts(:json.encode(result))
        result
      end)

    File.mkdir_p!(Path.join(root, "_build/validation"))

    File.write!(
      Path.join(root, "_build/validation/livebook-cells.json"),
      [
        :json.encode(%{
          generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          elixir: System.version(),
          otp: System.otp_release(),
          kino: Application.spec(:kino, :vsn) |> to_string(),
          complete_inventory: true,
          fingerprints: Clingo.LivebookCheck.fingerprints(root),
          notebooks: results,
          widget_checks: ["archive download after cleanup"]
        }),
        "\n"
      ]
    )

    failures = Enum.filter(results, &(Map.has_key?(&1, :failure) or &1.failures != []))
    if failures != [], do: raise("Livebook cell checks failed: #{inspect(failures)}")

    IO.puts("PASS #{length(results)} notebooks; pending exercises are reported separately.")
  end

  # Exercise the real pinned Kino event protocol, including the deferred read.
  # This checks download behavior, not browser layout or JavaScript rendering.
  defp check_downloads!() do
    dir = ASPCourse.workspace()
    ASPCourse.write(dir, "answer.lp", "a.\n")
    archive = ASPCourse.archive(dir, "answers.zip")

    try do
      File.rm_rf!(dir)
      {:ok, entries} = :zip.extract(download_content!(archive), [:memory])
      unless {~c"answer.lp", "a.\n"} in entries, do: raise("archive lost edited exercise file")
      IO.puts("PASS archive download event after workspace cleanup")
    after
      File.rm_rf!(dir)
      GenServer.stop(archive.pid)
    end
  end

  defp download_content!(%{pid: pid, ref: ref}) do
    origin = "course-checker"
    send(pid, {:connect, self(), %{origin: origin}})

    receive do
      {:connect_reply, _, %{ref: ^ref}} -> :ok
    after
      5_000 -> raise("Kino download connection timed out")
    end

    send(pid, {:event, "download", %{}, %{origin: origin}})

    receive do
      {:event, "download_content", {:binary, %{}, content}, %{ref: ^ref}} -> content
    after
      5_000 -> raise("Kino download event timed out")
    end
  end

  defp evaluate(path, notebook) do
    cells =
      Regex.scan(~r/^```elixir\n(.*?)^```/ms, File.read!(path), capture: :all_but_first)
      |> List.flatten()

    Enum.each(cells, &Code.string_to_quoted!/1)

    policies = notebook["policies"]
    # Dependencies match notebook setup. Each file-based section now creates
    # its own workspace explicitly; retain those paths for failure cleanup.
    executable = Enum.drop(cells, 1)

    {_, counts, failures, workspaces} =
      Enum.zip(executable, policies)
      |> Enum.with_index(1)
      |> Enum.reduce({[], %{}, [], MapSet.new()}, fn {{source, policy}, index},
                                                     {binding, counts, failures, workspaces} ->
        try do
          {_, next} =
            Code.eval_string(
              "alias ASPCourse, as: Course; alias Clingo.Control\n" <> source,
              binding,
              file: path
            )

          workspaces =
            case Keyword.get(next, :workdir) do
              nil -> workspaces
              dir -> MapSet.put(workspaces, dir)
            end

          {next, Map.update(counts, policy, 1, &(&1 + 1)), failures, workspaces}
        rescue
          error ->
            {binding, counts, failures ++ [%{cell: index, error: Exception.message(error)}],
             workspaces}
        end
      end)

    Enum.each(workspaces, &File.rm_rf!/1)
    %{path: notebook["livebook"], counts: counts, failures: failures}
  end
end

CourseCheck.run(root)
