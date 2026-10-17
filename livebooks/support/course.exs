defmodule ASPCourse do
  @moduledoc false
  @compile {:no_warn_undefined, [Kino.Download, Kino.DataTable, Kino.Layout, Kino.Markdown]}

  # Every notebook gets a writable copy. Re-evaluation cannot overwrite the course.
  def workspace(source \\ nil) do
    target = Path.join(System.tmp_dir!(), "asp-course-#{System.unique_integer([:positive])}")
    if source, do: File.cp_r!(source, target), else: File.mkdir_p!(target)
    target
  end

  def write(dir, name, text) do
    path = Path.join(dir, name)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, text)
    IO.puts("Wrote #{name} (#{byte_size(text)} bytes)")
  end

  def read(dir, name), do: File.read!(Path.join(dir, name))

  # Presentation is separate from solving: callers keep the original result.
  def table_data(%{models: models}) do
    Enum.map(models, fn model ->
      %{
        model: model.number,
        shown: Enum.join(model.shown, " "),
        cost: inspect(model.cost),
        optimality_proven: model.optimality_proven
      }
    end)
  end

  def display(result) do
    summary =
      Kino.Markdown.new("""
      **#{result.status}** · #{length(result.models)} models collected ·
      search exhausted: **#{result.exhausted}** · interrupted: **#{result.interrupted}**

      Each row is a copied model; an empty shown column is a valid result.
      Satisfiability alone does not establish optimality.
      """)

    views =
      if result.models == [],
        do: [summary],
        else: [summary, Kino.DataTable.new(table_data(result))]

    Kino.Layout.grid(views, columns: 1)
  end

  def expect_error(fun) do
    try do
      fun.()
      raise "The deliberately invalid example unexpectedly succeeded"
    rescue
      error in Clingo.Error ->
        if error.message in ["grounding stopped because of errors", "parsing failed"] do
          %{expected_error: error.message, code: error.code}
        else
          reraise error, __STACKTRACE__
        end
    end
  end

  def archive(dir, name) do
    dir = Path.expand(dir)
    files =
      Path.wildcard(Path.join(dir, "**/*"))
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&(Path.relative_to(&1, dir) |> String.to_charlist()))

    {:ok, {_, binary}} =
      :zip.create(String.to_charlist(name), files, [:memory, cwd: String.to_charlist(dir)])

    Kino.Download.new(fn -> binary end, filename: name)
  end
end
