defmodule Clingo.Result do
  @moduledoc """
  A solve outcome. `status` is independent of search exhaustion and interruption.
  Satisfiability does not establish optimality; inspect each model's cost and
  `optimality_proven` flag. Models are copied values and survive control closure.
  """
  import Bitwise
  defstruct status: :unknown, exhausted: false, interrupted: false, native_flags: 0, models: []

  @doc false
  def from_native(flags, models \\ []) do
    %__MODULE__{
      status:
        cond do
          (flags &&& 1) != 0 -> :satisfiable
          (flags &&& 2) != 0 -> :unsatisfiable
          true -> :unknown
        end,
      exhausted: (flags &&& 4) != 0,
      interrupted: (flags &&& 8) != 0,
      native_flags: flags,
      models: models
    }
  end
end
