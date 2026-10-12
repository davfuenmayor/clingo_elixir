defmodule Clingo.Extensions do
  @moduledoc false
  alias Clingo.BindingMetadata, as: M

  @views %{
    "propagate_init" => :propagate_init,
    "propagate_control" => :propagate_control,
    "assignment" => :assignment
  }

  def adapt(s, type, hooks) do
    inventory = M.hooks(type)

    Map.new(hooks, fn {name, fun} ->
      plan =
        Map.get(inventory, to_string(name)) ||
          raise ArgumentError, "unknown #{type} hook #{inspect(name)}"

      expected = length(plan["plan"])

      unless is_function(fun, expected),
        do: raise(ArgumentError, "#{name} callback must have arity #{expected}")

      wrapped =
        callback(plan["arity"], fn args ->
          converted =
            Enum.map(plan["plan"], fn item ->
              value = Enum.at(args, item["index"])

              case item["conversion"] do
                "value" ->
                  value

                "symbol" ->
                  Clingo.Symbol.decode(s, value)

                kind when kind in ["array", "symbols"] ->
                  values = Clingo.read_array(s, value, Enum.at(args, item["index"] + 1))

                  if kind == "symbols",
                    do: Enum.map(values, &Clingo.Symbol.decode(s, &1)),
                    else: values

                kind ->
                  %Clingo.View{session: s, handle: value, kind: Map.fetch!(@views, kind)}
              end
            end)

          result = apply(fun, converted)

          if index = plan["decision"] do
            Clingo.write(s, Enum.at(args, index), result)
          else
            unless result == :ok,
              do:
                raise(ArgumentError, "#{name} callback must return :ok, got: #{inspect(result)}")
          end

          if plan["void"], do: :ok, else: true
        end)

      {name, wrapped}
    end)
  end

  for arity <- 0..12 do
    args = Macro.generate_arguments(arity, __MODULE__)

    def callback(unquote(arity), fun),
      do: fn unquote_splicing(args) -> fun.([unquote_splicing(args)]) end
  end
end
