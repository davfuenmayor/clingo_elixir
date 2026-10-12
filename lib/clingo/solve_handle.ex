defmodule Clingo.SolveHandle do
  @moduledoc """
  Scoped solve operations, obtained with `Clingo.Control.with_solve!/3`.
  Models are snapshots. Use `async: true` for nonblocking resume and `wait!/2`
  to await progress. Cancellation can be requested from another process.
  """
  defstruct [:control, :handle, :lease, options: []]
  def resume!(h), do: call(h, :values_resume)
  def cancel!(h), do: Clingo.cancel_cursor(h.control.session, h.handle)

  def close(h) do
    try do
      call(h, :values_close)
    after
      if Process.alive?(h.control.session.dispatcher),
        do:
          Clingo.Dispatch.call(
            h.control.session.dispatcher,
            {:release_lease, h.control.handle, h.lease}
          )
    end
  end

  def wait!(h, timeout \\ -1), do: call(h, :values_wait, [timeout])
  def result!(h), do: Clingo.Result.from_native(call(h, :values_result))
  def core!(h), do: call(h, :values_core)

  def model!(h) do
    if Keyword.get(h.options, :async, false), do: wait!(h)
    snapshot(h, :values_model)
  end

  @doc false
  def next!(h) do
    resume!(h)
    model!(h)
  end

  @doc false
  def stream(open, close \\ &__MODULE__.close/1) do
    Stream.resource(
      open,
      fn handle ->
        case next!(handle) do
          nil -> {:halt, handle}
          model -> {[model], handle}
        end
      end,
      close
    )
  end

  def last!(h), do: snapshot(h, :values_last)

  defp snapshot(h, operation) do
    case call(h, operation, Clingo.Model.snapshot_options(h.options)) do
      nil ->
        nil

      map ->
        Clingo.Model.from_native(h.control.session, map)
    end
  end

  defp call(h, operation, args \\ []),
    do: Clingo.values(h.control.session, operation, [h.handle | args])
end
