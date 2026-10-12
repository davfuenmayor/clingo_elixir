defmodule Clingo.AST do
  @moduledoc """
  Scoped AST construction and functional transformation using upstream attributes.
  Use `with_ast/1` for standalone parsing, or `new!/3` with a control's session.
  AST handles expire at session close. `update!/2` reconstructs a node from updated
  attributes; `walk!/2` visits children before applying a function to each parent.
  """
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]
  defstruct [:session, :handle, :type]
  @external_resource Path.expand("../../tools/ast_constructors.json", __DIR__)
  @constructors File.read!(@external_resource) |> :json.decode()

  @attributes Map.new(
                for ctor <- @constructors,
                    arg <- ctor["arguments"],
                    do: {arg["name"], String.to_atom(arg["name"])}
              )

  def with_ast(fun), do: Clingo.with_session(fun)

  def new!(s, type, attributes) do
    index =
      if is_integer(type),
        do: type,
        else: Enum.find_index(@constructors, &(&1["name"] == to_string(type)))

    if not is_integer(index) or index < 0 or index >= length(@constructors),
      do: raise(ArgumentError, "unknown AST constructor #{inspect(type)}")

    allowed =
      Enum.map(Enum.at(@constructors, index)["arguments"], &Map.fetch!(@attributes, &1["name"]))

    unknown = Map.keys(attributes) -- allowed
    if unknown != [], do: raise(ArgumentError, "unknown AST attributes #{inspect(unknown)}")

    args = Map.new(attributes, fn {key, data} -> {key, unwrap(s, data)} end)

    %__MODULE__{
      session: s,
      handle: Clingo.scoped(s, fn -> build(s, index, args) end),
      type: index
    }
  end

  for {constructor, index} <- Enum.with_index(@constructors) do
    name = constructor["name"] |> Macro.underscore() |> Kernel.<>("!") |> String.to_atom()
    def unquote(name)(s, attributes), do: new!(s, unquote(index), attributes)
  end

  def parse!(s, text) do
    parent = self()
    token = make_ref()

    Clingo.scoped(s, fn ->
      Clingo.Scope.on_error(
        fn ->
          true =
            A.ast_parse_string(
              s,
              text,
              fn handle, _ ->
                :ok = A.ast_acquire(s, handle)

                send(
                  parent,
                  {token,
                   %__MODULE__{session: s, handle: handle, type: value(A.ast_get_type(s, handle))}}
                )

                true
              end,
              nil,
              nil,
              nil,
              nil,
              20
            )

          gather(token, [])
        end,
        fn -> Enum.each(gather(token, []), &release/1) end
      )
    end)
  end

  def to_string!(ast),
    do: Clingo.scoped(ast.session, fn -> value(A.ast_to_string(ast.session, ast.handle)) end)

  def release(ast), do: A.ast_release(ast.session, ast.handle)

  def get!(ast, name), do: Clingo.scoped(ast.session, fn -> get_attribute(ast, name) end)

  defp get_attribute(ast, name) do
    {type, enum} = attribute(ast, name)
    args = [ast.session, ast.handle, enum]

    case type do
      0 ->
        value(apply(A, :ast_attribute_get_number, args))

      1 ->
        Clingo.Symbol.decode(ast.session, value(apply(A, :ast_attribute_get_symbol, args)))

      2 ->
        value(apply(A, :ast_attribute_get_location, args))

      3 ->
        value(apply(A, :ast_attribute_get_string, args))

      n when n in [4, 5] ->
        op = if n == 4, do: :ast_attribute_get_ast, else: :ast_attribute_get_optional_ast
        wrap(ast.session, value(apply(A, op, args)))

      n when n in [6, 7] ->
        size_op =
          if n == 6, do: :ast_attribute_size_string_array, else: :ast_attribute_size_ast_array

        get_op = if n == 6, do: :ast_attribute_get_string_at, else: :ast_attribute_get_ast_at

        for i <- indices(value(apply(A, size_op, args))) do
          result = value(apply(A, get_op, args ++ [i]))
          if n == 6, do: result, else: wrap(ast.session, result)
        end
    end
  end

  def update!(ast, changes) when is_map(changes) and map_size(changes) == 0, do: ast

  def update!(ast, changes) when is_map(changes) do
    attributes =
      Map.new(Enum.at(@constructors, ast.type)["arguments"], fn arg ->
        key = Map.fetch!(@attributes, arg["name"])
        {key, Map.get_lazy(changes, key, fn -> get!(ast, key) end)}
      end)

    new!(ast.session, ast.type, Map.merge(attributes, changes))
  end

  def walk!(ast, fun) do
    changes =
      for arg <- Enum.at(@constructors, ast.type)["arguments"],
          arg["type"] in [4, 5, 7],
          key = Map.fetch!(@attributes, arg["name"]),
          old = get!(ast, key),
          new = walk_child(old, fun),
          old != new,
          into: %{},
          do: {key, new}

    fun.(update!(ast, changes))
  end

  defp walk_child(nil, _fun), do: nil
  defp walk_child(list, fun) when is_list(list), do: Enum.map(list, &walk!(&1, fun))
  defp walk_child(child, fun), do: walk!(child, fun)

  # Constructor metadata is release-pinned and checked against clingo at load.
  # The generic native converter already handles locations and child arrays.
  defp build(s, index, attributes) do
    varargs =
      Enum.flat_map(Enum.at(@constructors, index)["arguments"], fn arg ->
        data = Map.fetch!(attributes, Map.fetch!(@attributes, arg["name"]))

        case arg["type"] do
          0 ->
            [{"int", data}]

          1 ->
            [{"clingo_symbol_t", data}]

          2 ->
            [{"clingo_location_t*", Clingo.array(s, "clingo_location_t", [data])}]

          3 ->
            [{"char*", data}]

          n when n in [4, 5] ->
            [{"clingo_ast_t*", data}]

          n when n in [6, 7] ->
            type = if n == 6, do: "char*", else: "clingo_ast_t*"
            [{type <> "*", Clingo.array(s, type, data)}, {"size_t", length(data)}]
        end
      end)

    output = Clingo.alloc(s, "clingo_ast_t*")
    true = Clingo.call(s, :clingo_ast_build, [index, output], varargs)
    Clingo.read(s, output)
  end

  defp attribute(ast, name) do
    case Enum.find(
           Enum.at(@constructors, ast.type)["arguments"],
           &(&1["name"] == to_string(name))
         ) do
      nil -> raise ArgumentError, "AST has no attribute #{inspect(name)}"
      arg -> {arg["type"], arg["attribute"]}
    end
  end

  defp unwrap(s, %__MODULE__{session: s, handle: handle}), do: handle
  defp unwrap(_s, %__MODULE__{}), do: raise(ArgumentError, "AST belongs to another session")
  defp unwrap(s, %Clingo.Symbol{} = symbol), do: Clingo.Symbol.encode(s, symbol)
  defp unwrap(s, values) when is_list(values), do: Enum.map(values, &unwrap(s, &1))
  defp unwrap(_s, value), do: value
  defp wrap(_s, nil), do: nil

  defp wrap(s, handle),
    do: %__MODULE__{session: s, handle: handle, type: value(A.ast_get_type(s, handle))}

  defp gather(token, acc) do
    receive do
      {^token, ast} -> gather(token, [ast | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp indices(0), do: []
  defp indices(n), do: 0..(n - 1)
end
