defmodule ASPCourseRuntimeCheck do
  def run(root, options) do
    copy =
      Path.join(System.tmp_dir!(), "asp-livebooks-check-#{System.unique_integer([:positive])}")

    version = Application.spec(:livebook, :vsn) |> to_string()
    unless version == "0.19.9", do: raise("checker requires Livebook 0.19.9, got #{version}")
    fingerprints = Clingo.LivebookCheck.fingerprints(root)
    entries = Clingo.LivebookCheck.inventory(root)
    File.mkdir_p!(copy)

    try do
      File.cp_r!(Path.join(root, "livebooks"), Path.join(copy, "livebooks"))
      File.cp_r!(Path.join(root, "priv"), Path.join(copy, "priv"))

      for name <- ["mix.exs", "Makefile", "lib", "c_src", "tools", "native"] do
        File.ln_s!(Path.join(root, name), Path.join(copy, name))
      end

      paths = Path.wildcard(Path.join(copy, "livebooks/**/*.livemd"))

      paths =
        if "downloads" in options,
          do: Enum.filter(paths, &(File.read!(&1) =~ ~r/Course\.(archive|download)\(/)),
          else: paths

      expected_paths = Enum.map(entries, & &1["livebook"]) |> Enum.sort()

      actual_paths =
        Path.wildcard(Path.join(copy, "livebooks/**/*.livemd"))
        |> Enum.map(&Path.relative_to(&1, Path.join(copy, "livebooks")))
        |> Enum.sort()

      unless actual_paths == expected_paths,
        do: raise("Livebook inventory differs from the checked working tree")

      results =
        for path <- paths do
          {notebook, %{warnings: []}} =
            Livebook.LiveMarkdown.notebook_from_livemd(File.read!(path))

          source = Path.relative_to(path, Path.join(copy, "livebooks"))
          entry = Enum.find(entries, &(&1["livebook"] == source))

          expected = entry["code_cells"]

          cells =
            for section <- Livebook.Notebook.all_sections(notebook),
                %{__struct__: Livebook.Notebook.Cell.Code} = cell <- section.cells,
                String.trim(cell.source) != "",
                do: cell

          Clingo.LivebookCheck.validate_cells!(cells, expected)

          if expected == 0 do
            IO.puts("REFERENCE " <> source)
            {:reference_only, Path.relative_to(path, copy)}
          else
            file = Livebook.FileSystem.File.local(path)

            {:ok, session} =
              Livebook.Sessions.create_session(
                notebook: notebook,
                file: file,
                origin: {:file, file}
              )

            try do
              Livebook.Session.queue_full_evaluation(session.pid, [])
              await(session.pid, System.monotonic_time(:millisecond) + 120_000)
              result = Path.relative_to(path, copy)
              IO.puts("PASS " <> result)
              {:evaluated, result}
            after
              Livebook.Session.close(session.pid)
            end
          end
        end

      report_path = Path.join(root, "_build/validation/livebook-runtime.json")
      File.mkdir_p!(Path.dirname(report_path))

      unless fingerprints == Clingo.LivebookCheck.fingerprints(root),
        do: raise("sources changed during Livebook validation; rerun on a stable tree")

      # A subset run is its own evidence, never a merge with historical passes.
      File.write!(
        report_path,
        :json.encode(%{
          livebook: version,
          elixir: System.version(),
          otp: System.otp_release(),
          checked_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          complete: options == [],
          selection: options,
          passed: for({:evaluated, path} <- results, do: path),
          reference_only: for({:reference_only, path} <- results, do: path),
          fingerprints: fingerprints
        })
      )

      results
    after
      File.rm_rf!(copy)
    end
  end

  defp await(pid, deadline) do
    data = Livebook.Session.get_data(pid)
    evals = for {_, %{eval: eval}} <- data.cell_infos, do: eval

    case Clingo.LivebookCheck.status(evals) do
      :failed ->
        errors =
          for section <- Livebook.Notebook.all_sections(data.notebook),
              %{outputs: outputs} <- section.cells,
              {_, %{type: :error} = error} <- outputs,
              do: error

        raise "Livebook evaluation failed: #{inspect(errors)}"

      :passed ->
        :ok

      :pending ->
        if System.monotonic_time(:millisecond) >= deadline,
          do: raise("Livebook evaluation deadline exceeded")

        Process.sleep(100)
        await(pid, deadline)
    end
  end
end
