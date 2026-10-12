defmodule Clingo.Statistics do
  @moduledoc """
  Statistics snapshots are maps, lists and numbers. Inside on_statistics callbacks,
  scoped views support `put!/3`; modifying a snapshot does not modify the solver.
  """
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]
  defstruct [:session, :handle, :key]

  def snapshot!(%Clingo.Control{} = c),
    do:
      Clingo.scoped(c.session, fn ->
        snapshot!(view(c.session, value(A.control_statistics(c.session, c.handle))))
      end)

  def snapshot!(%__MODULE__{} = view), do: read(view, view.key)

  @doc false
  def view(s, handle),
    do: %__MODULE__{session: s, handle: handle, key: value(A.statistics_root(s, handle))}

  def put!(%__MODULE__{} = view, path, data) do
    key = descend(view, view.key, path, data)
    write(view, key, data)
    :ok
  end

  defp read(v, key) do
    case value(A.statistics_type(v.session, v.handle, key)) do
      1 ->
        value(A.statistics_value_get(v.session, v.handle, key))

      2 ->
        for i <- indices(value(A.statistics_array_size(v.session, v.handle, key))),
            do: read(v, value(A.statistics_array_at(v.session, v.handle, key, i)))

      3 ->
        Map.new(indices(value(A.statistics_map_size(v.session, v.handle, key))), fn i ->
          name = value(A.statistics_map_subkey_name(v.session, v.handle, key, i))
          {name, read(v, value(A.statistics_map_at(v.session, v.handle, key, name)))}
        end)

      0 ->
        nil
    end
  end

  defp write(v, key, n) when is_number(n) do
    ensure(v, key, 1)
    A.statistics_value_set(v.session, v.handle, key, n)
  end

  defp write(v, key, map) when is_map(map) do
    ensure(v, key, 3)

    Enum.each(map, fn {name, data} ->
      child = map_key(v, key, name, type(data))

      write(v, child, data)
    end)
  end

  defp write(v, key, list) when is_list(list) do
    ensure(v, key, 2)
    size = value(A.statistics_array_size(v.session, v.handle, key))
    if length(list) < size, do: raise(ArgumentError, "native statistics arrays cannot shrink")

    Enum.each(Enum.with_index(list), fn {data, index} ->
      child =
        if index < size,
          do: value(A.statistics_array_at(v.session, v.handle, key, index)),
          else: value(A.statistics_array_push(v.session, v.handle, key, type(data)))

      write(v, child, data)
    end)
  end

  defp descend(_v, key, [], _data), do: key

  defp descend(v, key, [name | tail], data) when is_binary(name) do
    ensure(v, key, 3)

    kind =
      case tail do
        [] -> type(data)
        [next | _] when is_integer(next) -> 2
        _ -> 3
      end

    child = map_key(v, key, name, kind)

    descend(v, child, tail, data)
  end

  defp descend(v, key, [index | tail], data) when is_integer(index) and index >= 0 do
    ensure(v, key, 2)

    if index >= value(A.statistics_array_size(v.session, v.handle, key)),
      do: raise(ArgumentError, "statistics index out of bounds")

    descend(v, value(A.statistics_array_at(v.session, v.handle, key, index)), tail, data)
  end

  defp map_key(v, key, name, kind) do
    if value(A.statistics_map_has_subkey(v.session, v.handle, key, name)),
      do: value(A.statistics_map_at(v.session, v.handle, key, name)),
      else: value(A.statistics_map_add_subkey(v.session, v.handle, key, name, kind))
  end

  defp ensure(v, key, kind) do
    if value(A.statistics_type(v.session, v.handle, key)) != kind,
      do: raise(ArgumentError, "statistics path has an incompatible type")
  end

  defp type(n) when is_number(n), do: 1
  defp type(list) when is_list(list), do: 2
  defp type(map) when is_map(map), do: 3
  defp indices(0), do: []
  defp indices(n), do: 0..(n - 1)
end
