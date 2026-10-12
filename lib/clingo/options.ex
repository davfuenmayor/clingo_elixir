defmodule Clingo.Options do
  @moduledoc false

  @constructor [:arguments, :models, :logger, :session]
  @snapshot [:show, :symbols]
  @cursor @snapshot ++
            [:models, :assumptions, :async, :on_finish, :on_unsat, :on_statistics, :on_model_view]
  @solve @cursor ++ [:collect, :on_model]
  @ground [:context]
  @session [:max_arena, :max_queue, :max_callbacks]

  def propagator(opts), do: validate!(opts, [:sequential])
  def observer(opts), do: validate!(opts, [:replace])
  def rule(opts), do: validate!(opts, [:choice])
  def cli(opts), do: validate!(opts, [:cd, :env])
  def cli_option(opts), do: validate!(opts, [:multi, :argument])
  def export(opts), do: validate!(opts, @constructor ++ @ground ++ [:files, :format])
  def constructor(opts), do: validate!(opts, @constructor)
  def ground(opts), do: validate!(opts, @ground)
  def snapshot(opts), do: validate!(opts, @snapshot)
  def cursor(opts), do: validate!(opts, @cursor)
  def solve(opts), do: validate!(opts, @solve)
  def session(opts), do: validate!(opts, @session)
  def constructor_options(opts), do: Keyword.take(opts, @constructor)
  def cursor_options(opts), do: Keyword.take(opts, @cursor)
  def solve_options(opts), do: Keyword.take(opts, @solve)

  def program(opts, mode) when mode in [:solve, :models],
    do: validate!(opts, @constructor ++ @ground ++ [:files] ++ allowed(mode))

  defp allowed(:solve), do: @solve
  defp allowed(:models), do: @cursor

  defp validate!(opts, allowed) do
    unless Keyword.keyword?(opts), do: raise(ArgumentError, "options must be a keyword list")
    keys = Keyword.keys(opts)
    unless length(keys) == length(Enum.uniq(keys)), do: raise(ArgumentError, "duplicate options")

    for {key, value} <- opts do
      unless key in allowed, do: raise(ArgumentError, "unknown option #{inspect(key)}")

      unless valid?(key, value),
        do: raise(ArgumentError, "invalid #{key} option: #{inspect(value)}")
    end

    opts
  end

  defp valid?(:format, value), do: value in [:aspif, :reify]
  defp valid?(:models, value), do: value == :all or (is_integer(value) and value > 0)
  defp valid?(key, value) when key in [:arguments, :files], do: strings?(value)
  defp valid?(:session, value), do: session(value) == value
  defp valid?(key, value) when key in @session, do: is_integer(value) and value >= 0

  defp valid?(key, value)
       when key in [:symbols, :async, :collect, :sequential, :replace, :choice, :multi],
       do: is_boolean(value)

  defp valid?(key, value) when key in [:cd, :argument], do: is_binary(value)

  defp valid?(:env, value),
    do:
      is_list(value) and
        Enum.all?(value, fn
          {name, text} -> is_binary(name) and (is_binary(text) or is_nil(text))
          _ -> false
        end)

  defp valid?(:logger, value), do: is_nil(value) or is_function(value, 2)
  defp valid?(:on_statistics, value), do: is_function(value, 2)

  defp valid?(key, value) when key in [:on_model, :on_finish, :on_unsat, :on_model_view],
    do: is_function(value, 1)

  defp valid?(:show, value) when is_integer(value), do: value >= 0 and value <= 63

  defp valid?(:show, value),
    do:
      value in [
        :clingo_show_type_shown,
        :clingo_show_type_atoms,
        :clingo_show_type_terms,
        :clingo_show_type_theory,
        :clingo_show_type_all,
        :clingo_show_type_complement
      ]

  defp valid?(:context, value),
    do:
      is_map(value) and
        Enum.all?(value, fn {name, fun} -> is_binary(name) and is_function(fun, 1) end)

  defp valid?(:assumptions, value),
    do:
      is_list(value) and
        Enum.all?(value, fn
          literal when is_integer(literal) ->
            literal >= -2_147_483_648 and literal <= 2_147_483_647

          {symbol, sign} ->
            (is_binary(symbol) or is_struct(symbol, Clingo.Symbol)) and is_boolean(sign)

          _ ->
            false
        end)

  defp strings?(value), do: is_list(value) and Enum.all?(value, &is_binary/1)
end
