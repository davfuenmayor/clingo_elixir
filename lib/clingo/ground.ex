defmodule Clingo.Ground do
  @moduledoc """
  Export a grounded program through clingo's native backend, without a subprocess.
  `to_string!/2` returns ASPIF or reified ASP facts; the temporary output file is
  removed on every exit. The source program is grounded, not searched.
  """
  alias Clingo.Control

  @doc "Ground ASP text or `files:` options and return ASPIF or reified ASP."
  def to_string!(program_or_options, opts \\ [])
  def to_string!(opts, []) when is_list(opts), do: to_string!("", opts)

  def to_string!(program, opts) when is_binary(program) do
    Clingo.Options.export(opts)
    format = Keyword.get(opts, :format, :aspif)

    directory =
      Path.join(System.tmp_dir!(), "clingo-ground-#{System.unique_integer([:positive])}")

    File.mkdir!(directory)
    path = Path.join(directory, "ground")

    try do
      Clingo.with_control(Clingo.Options.constructor_options(opts), fn control ->
        true =
          Clingo.Internal.API.control_register_backend(
            control.session,
            control.handle,
            backend(format),
            path,
            true
          )

        Control.prepare!(control, program, opts)
        # end_step flushes the backend; replacement leaves an empty solver.
        Control.solve!(control, collect: false)
      end)

      # Native Windows text streams emit CRLF; ASPIF string parsing expects LF.
      File.read!(path) |> String.replace("\r\n", "\n")
    after
      File.rm_rf!(directory)
    end
  end

  defp backend(:aspif), do: :clingo_backend_type_aspif
  defp backend(:reify), do: :clingo_backend_type_reify
end
