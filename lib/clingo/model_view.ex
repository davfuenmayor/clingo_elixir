defmodule Clingo.ModelView do
  @moduledoc "A live model view valid only inside on_model_view. Use snapshot!/2 to retain data."
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]
  defstruct [:session, :handle]
  def snapshot!(v, opts \\ []), do: Clingo.Model.snapshot(v.session, v.handle, opts)

  def extend!(v, symbols) do
    true =
      A.model_extend(v.session, v.handle, Enum.map(symbols, &Clingo.Symbol.encode(v.session, &1)))

    :ok
  end

  def add_clause!(v, literals) do
    control = value(A.model_context(v.session, v.handle))
    true = A.solve_control_add_clause(v.session, control, literals)
    :ok
  end
end
