defmodule Clingo.Script do
  @moduledoc """
  Register a global scripting language with Elixir closures. Native clingo has no
  unregister operation: registrations live until `Clingo.finalize_scripts/0`.
  Hooks are execute(location, code), call(location, name, symbols), callable(name),
  main(borrowed_control), and free(). call returns a symbol or list of symbols;
  execute/main/free return :ok, callable returns a boolean. version is a binary.
  """
  def register!(name, callbacks) do
    s = Clingo.open()

    Clingo.Scope.on_error(
      fn ->
        script =
          Map.new(callbacks, fn
            {:version, text} when is_binary(text) ->
              {:version, text}

            {:execute, fun} ->
              {:execute,
               fn location, code, _ ->
                 :ok = fun.(Clingo.read(s, location), code)
                 true
               end}

            {:call, fun} ->
              {:call,
               fn location, name, args, count, emit, data, _ ->
                 symbols =
                   Clingo.read_array(s, args, count) |> Enum.map(&Clingo.Symbol.decode(s, &1))

                 result = fun.(Clingo.read(s, location), name, symbols)
                 Clingo.Control.emit(s, emit, data, result)
               end}

            {:callable, fun} ->
              {:callable,
               fn name, result, _ ->
                 Clingo.write(s, result, fun.(name))
                 true
               end}

            {:main, fun} ->
              {:main,
               fn control, _ ->
                 :ok = fun.(%Clingo.Control{session: s, handle: control, owned: false})
                 true
               end}

            {:free, fun} ->
              {:free, fn _ -> :ok = fun.() end}

            {key, _} ->
              raise ArgumentError, "unknown script hook #{inspect(key)}"
          end)

        true = Clingo.Internal.API.register_script(s, name, script, nil)
        :ok
      end,
      fn -> Clingo.close(s) end
    )
  end
end
