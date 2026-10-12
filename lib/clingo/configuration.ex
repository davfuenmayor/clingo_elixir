defmodule Clingo.Configuration do
  @moduledoc "Configuration paths use binary names and zero-based array indices. Values remain native strings."
  import Bitwise
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]

  def get!(control, path) do
    Clingo.scoped(control.session, fn ->
      {s, config, key} = at(control, path)

      ensure(s, config, key, 1)

      if value(A.configuration_value_is_assigned(s, config, key)),
        do: value(A.configuration_value_get(s, config, key))
    end)
  end

  def put!(control, path, text) when is_binary(text) do
    Clingo.scoped(control.session, fn ->
      {s, config, key} = at(control, path)
      ensure(s, config, key, 1)
      true = A.configuration_value_set(s, config, key, text)
      :ok
    end)
  end

  def description!(control, path) do
    Clingo.scoped(control.session, fn ->
      {s, config, key} = at(control, path)
      value(A.configuration_description(s, config, key))
    end)
  end

  defp at(c, path) do
    s = c.session
    config = value(A.control_configuration(s, c.handle))

    key =
      Enum.reduce(path, value(A.configuration_root(s, config)), fn
        name, key when is_binary(name) ->
          ensure(s, config, key, 4)

          unless value(A.configuration_map_has_subkey(s, config, key, name)),
            do: raise(ArgumentError, "unknown configuration path #{inspect(path)}")

          value(A.configuration_map_at(s, config, key, name))

        index, key when is_integer(index) and index >= 0 ->
          ensure(s, config, key, 2)

          if index >= value(A.configuration_array_size(s, config, key)),
            do: raise(ArgumentError, "configuration index out of bounds")

          value(A.configuration_array_at(s, config, key, index))
      end)

    {s, config, key}
  end

  defp ensure(s, config, key, kind) do
    if (value(A.configuration_type(s, config, key)) &&& kind) == 0,
      do: raise(ArgumentError, "configuration path has an incompatible type")
  end
end
