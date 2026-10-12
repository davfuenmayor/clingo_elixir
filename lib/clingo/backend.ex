defmodule Clingo.Backend do
  @moduledoc "Scoped ASPIF construction. Use with_backend/2; rule bodies are signed literals."
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]
  defstruct [:session, :handle]

  def with_backend(control, fun) do
    :ok = Clingo.Control.idle!(control)
    s = control.session

    Clingo.scoped(s, fn ->
      backend = %__MODULE__{session: s, handle: value(A.control_backend(s, control.handle))}
      true = A.backend_begin(s, backend.handle)

      Clingo.Scope.run(fn -> fun.(backend) end, fn -> A.backend_end(s, backend.handle) end)
    end)
  end

  def add_atom!(b, symbol \\ nil),
    do:
      value(
        A.backend_add_atom(
          b.session,
          b.handle,
          if(symbol, do: [Clingo.Symbol.encode(b.session, symbol)])
        )
      )

  def rule!(b, head, body \\ [], opts \\ []) do
    Clingo.Options.rule(opts)
    ok(A.backend_rule(b.session, b.handle, Keyword.get(opts, :choice, false), head, body))
  end

  def weight_rule!(b, head, bound, body, opts \\ []) do
    Clingo.Options.rule(opts)

    ok(
      A.backend_weight_rule(
        b.session,
        b.handle,
        Keyword.get(opts, :choice, false),
        head,
        bound,
        weighted(body)
      )
    )
  end

  def minimize!(b, priority, literals),
    do: ok(A.backend_minimize(b.session, b.handle, priority, weighted(literals)))

  defp weighted(items),
    do: Enum.map(items, fn {literal, weight} -> %{literal: literal, weight: weight} end)

  defp ok(true), do: :ok
end
