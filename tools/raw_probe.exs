# Literal C calls for native boundary tests and fault probes, never a library API.
defmodule Clingo.TestSupport.Raw do
  @moduledoc false
  manifest = File.read!(Path.expand("api.json", __DIR__)) |> JSON.decode!()

  for function <- manifest["functions"] do
    operation = String.to_atom(function["name"])
    name = function["name"] |> String.replace_prefix("clingo_", "") |> String.to_atom()
    args = Macro.generate_arguments(length(function["args"]), __MODULE__)

    if function["variadic"] do
      def unquote(name)(session, unquote_splicing(args), varargs),
        do: Clingo.call(session, unquote(operation), [unquote_splicing(args)], varargs)
    else
      def unquote(name)(session, unquote_splicing(args)),
        do: Clingo.call(session, unquote(operation), [unquote_splicing(args)])
    end
  end
end
