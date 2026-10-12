defmodule Clingo.Binding do
  @moduledoc false
  alias Clingo.BindingMetadata, as: M

  def value({result, value}) when result in [true, :ok], do: value

  def call(session, operation, supplied) do
    meta = M.function(operation)
    args = meta["arguments"]
    values = Map.new(Enum.zip(meta["inputs"], supplied))

    unless length(supplied) == length(meta["inputs"]),
      do: raise(ArgumentError, "invalid argument count for #{operation}")

    counts =
      Map.new(meta["input_arrays"], fn {name, size} ->
        {size, length(Map.fetch!(values, name))}
      end)

    counts =
      if meta["size_query"] do
        {_, count} = call(session, meta["size_query"], supplied)

        Map.merge(
          counts,
          Map.new(meta["output_sizes"], &{&1, count})
        )
      else
        counts
      end

    cells =
      Map.new(
        for a <- args, a["direction"] == "out" do
          count = Map.get(counts, a["size"], 1)
          {a["name"], Clingo.alloc(session, target(a["type"]), count)}
        end
      )

    native =
      Enum.map(args, fn a ->
        cond do
          a["direction"] == "out" -> Map.fetch!(cells, a["name"])
          Map.has_key?(counts, a["name"]) -> counts[a["name"]]
          true -> prepare(session, a["type"], Map.fetch!(values, a["name"]))
        end
      end)

    result = Clingo.call(session, operation, native)

    outputs =
      for index <- meta["outputs"] do
        a = Enum.at(args, index)
        cell = cells[a["name"]]

        cond do
          is_nil(a["size"]) ->
            Clingo.read(session, cell)

          Map.has_key?(counts, a["size"]) ->
            if target(a["type"]) == "char",
              do: Clingo.string(session, cell, counts[a["size"]]),
              else: Clingo.read_array(session, cell, counts[a["size"]])

          true ->
            Clingo.read_array(
              session,
              Clingo.read(session, cell),
              Clingo.read(session, cells[a["size"]])
            )
        end
      end

    case outputs do
      [] -> result
      [value] -> {result, value}
      values -> {result, List.to_tuple(values)}
    end
  end

  defp resolved(type), do: M.resolved(type)

  defp target(type), do: type |> resolved() |> Map.fetch!("target")

  defp prepare(_s, _type, nil), do: nil

  defp prepare(s, type, value) do
    case {resolved(type), value} do
      {%{"kind" => "callback"}, fun} when is_function(fun) ->
        Clingo.callback(s, type, fun)

      {%{"kind" => "pointer"}, list} when is_list(list) ->
        element = target(type)
        Clingo.array(s, element, Enum.map(list, &prepare(s, element, &1)))

      {%{"kind" => "pointer"}, map} when is_map(map) ->
        element = target(type)
        Clingo.array(s, element, [prepare(s, element, map)])

      {%{"kind" => "record", "fields" => fields}, map} when is_map(map) ->
        map =
          if Enum.any?(fields, &(&1["name"] == "params")) and is_list(get(map, "params")),
            do: Map.put(map, :size, length(get(map, "params"))),
            else: map

        Map.new(fields, fn field ->
          name = field["name"]
          {String.to_atom(name), prepare(s, field["type"], get(map, name))}
        end)

      {%{"kind" => kind}, atom} when kind in ["signed", "unsigned"] and is_atom(atom) ->
        Clingo.constant(atom)

      _ ->
        value
    end
  end

  defp get(map, name), do: Map.get(map, String.to_atom(name), Map.get(map, name))
end
