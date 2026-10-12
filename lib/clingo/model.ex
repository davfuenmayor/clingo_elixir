defmodule Clingo.Model do
  @moduledoc "A copied model. It remains usable after solving resumes or its control closes."

  defstruct shown: [],
            symbols: nil,
            cost: [],
            optimality_proven: false,
            number: nil,
            type: :stable_model

  @doc false
  def snapshot(s, native, opts \\ []) do
    Clingo.Options.snapshot(opts)
    from_native(s, Clingo.values(s, :values_snapshot, [native | snapshot_options(opts)]))
  end

  @doc false
  def snapshot_options(opts) do
    show = Keyword.get(opts, :show, :clingo_show_type_shown)
    show = if is_atom(show), do: Clingo.constant(show), else: show
    [show, Keyword.get(opts, :symbols, false)]
  end

  @doc false
  def from_native(s, map) do
    symbols = if map.symbols, do: Enum.map(map.symbols, &Clingo.Symbol.decode(s, &1))
    struct!(__MODULE__, %{map | shown: Enum.sort(map.shown), symbols: symbols})
  end
end
