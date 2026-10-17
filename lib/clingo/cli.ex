defmodule Clingo.CLI do
  @moduledoc """
  Isolated command-line output using the packaged driver. Compilation happens at
  package build time. `run!/2` captures output; run_native!/2 uses native process
  I/O and is intended for command-line applications, not notebook output capture.
  """
  def executable do
    name = if :os.type() == {:win32, :nt}, do: "clingo.exe", else: "clingo"
    :clingo_elixir |> :code.priv_dir() |> to_string() |> Path.join(name)
  end

  def run!(arguments, opts \\ []) do
    Clingo.Options.cli(opts)
    Clingo.Options.constructor(arguments: arguments)

    {output, code} =
      System.cmd(
        executable(),
        arguments,
        Keyword.take(opts, [:cd, :env]) ++ [stderr_to_stdout: true]
      )

    if code not in [0, 10, 20, 30],
      do: raise(Clingo.Error, code: code, message: "clingo CLI exited #{code}: #{output}")

    %{output: output, exit_code: code}
  end

  @doc "Run a complete native application map with process-level stdin/stdout."
  def run_native!(callbacks, arguments \\ []) do
    Clingo.Options.constructor(arguments: arguments)
    # Upstream's default single-shot main releases the logic program before
    # printing. A custom main keeps it alive, as in libpyclingo applications.
    callbacks =
      if Map.has_key?(callbacks, :printer) do
        Map.put_new(callbacks, :main, fn control, files ->
          Enum.each(if(files == [], do: ["-"], else: files), &Clingo.Control.load!(control, &1))
          Clingo.Control.ground!(control)
          Clingo.Control.solve!(control, collect: false)
          :ok
        end)
      else
        callbacks
      end

    Clingo.with_session(fn s ->
      app =
        Map.new(callbacks, fn
          {:main, fun} ->
            {:main,
             fn control, files, count, _ ->
               files = Clingo.read_array(s, files, count)
               fun.(%Clingo.Control{session: s, handle: control, owned: false}, files)
               true
             end}

          {:register_options, fun} ->
            {:register_options,
             fn options, _ ->
               fun.(%Clingo.View{session: s, handle: options, kind: :options})
               true
             end}

          {:printer, fun} ->
            {:printer,
             fn model, printer, data, _ ->
               fun.(%Clingo.ModelView{session: s, handle: model}, fn ->
                 Clingo.call_pointer(s, printer, [data])
               end)

               true
             end}

          {:logger, fun} ->
            {:logger,
             fn code, message, _ ->
               fun.(code, message)
               :ok
             end}

          {name, fun} when name in [:program_name, :version, :message_limit] ->
            {name, fn _ -> fun.() end}

          {:validate_options, fun} ->
            {:validate_options, fn _ -> fun.() end}

          {name, _} ->
            raise ArgumentError, "unknown application hook #{inspect(name)}"
        end)

      Clingo.Internal.API.main(s, app, arguments, nil)
    end)
  end

  def option!(%Clingo.View{kind: :options} = v, group, name, description, parser, opts \\ []) do
    Clingo.Options.cli_option(opts)

    true =
      Clingo.Internal.API.options_add(
        v.session,
        v.handle,
        group,
        name,
        description,
        fn text, _ -> parser.(text) end,
        nil,
        Keyword.get(opts, :multi, false),
        Keyword.get(opts, :argument)
      )

    :ok
  end
end
