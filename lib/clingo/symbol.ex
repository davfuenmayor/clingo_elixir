defmodule Clingo.Symbol do
  @moduledoc """
  An ASP symbol as Elixir data, independent of a native session. Names and string
  values are binaries. Use `parse!/1` for ASP text, `number/1`, `string/1` or
  `function/3` to construct values. Text parsing preserves clingo’s modulo-2^32
  integer literals; `number/1` requires a signed 32-bit value. Elixir term
  ordering is not clingo ordering.
  """
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]
  defstruct [:type, :value, :name, arguments: [], positive: true]

  def parse!(text) when is_binary(text),
    do: session(fn s -> decode(s, Clingo.values(s, :values_symbol_parse, [text])) end)

  def number(value) when is_integer(value) and value >= -2_147_483_648 and value <= 2_147_483_647,
    do: %__MODULE__{type: :number, value: value}

  def number(_), do: raise(ArgumentError, "symbol number must fit a signed 32-bit integer")

  def string(value) when is_binary(value) do
    if :binary.match(value, <<0>>) != :nomatch,
      do: raise(ArgumentError, "symbol strings cannot contain NUL")

    %__MODULE__{type: :string, value: value}
  end

  def function(name, arguments \\ [], positive \\ true)
      when is_binary(name) and is_list(arguments) and is_boolean(positive) do
    session(fn s ->
      decode(
        s,
        Clingo.values(s, :values_symbol_function, [
          name,
          Enum.map(arguments, &encode(s, &1)),
          positive
        ])
      )
    end)
  end

  def infimum, do: %__MODULE__{type: :infimum}
  def supremum, do: %__MODULE__{type: :supremum}

  @doc false
  def encode(s, %__MODULE__{type: :number, value: n}),
    do: Clingo.values(s, :values_symbol_number, [n])

  def encode(s, %__MODULE__{type: :string, value: text}),
    do: Clingo.values(s, :values_symbol_string, [text])

  def encode(s, %__MODULE__{type: :function, name: name, arguments: args, positive: sign}),
    do: Clingo.values(s, :values_symbol_function, [name, Enum.map(args, &encode(s, &1)), sign])

  def encode(s, %__MODULE__{type: :infimum}), do: value(A.symbol_create_infimum(s))
  def encode(s, %__MODULE__{type: :supremum}), do: value(A.symbol_create_supremum(s))
  def encode(s, text) when is_binary(text), do: Clingo.values(s, :values_symbol_parse, [text])

  @doc false
  def decode(s, native) do
    data = Clingo.values(s, :values_symbol_data, [native])
    struct!(__MODULE__, %{data | arguments: Enum.map(data.arguments, &decode(s, &1))})
  end

  defp session(fun) do
    case Process.get({Clingo, :session}) do
      nil -> Clingo.with_session(fun)
      s -> fun.(s)
    end
  end

  @doc "Format the current semantic fields using clingo’s canonical ASP printer."
  def format!(%__MODULE__{} = symbol) do
    session(fn s -> Clingo.values(s, :values_symbol_format, [encode(s, symbol)]) end)
  end
end

defimpl String.Chars, for: Clingo.Symbol do
  def to_string(symbol), do: Clingo.Symbol.format!(symbol)
end

defimpl Inspect, for: Clingo.Symbol do
  import Inspect.Algebra
  def inspect(symbol, _opts), do: concat(["#Clingo.Symbol<", Clingo.Symbol.format!(symbol), ">"])
end
