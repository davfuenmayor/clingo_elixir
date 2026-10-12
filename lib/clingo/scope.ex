defmodule Clingo.Scope do
  @moduledoc false

  # Cleanup failures must not replace an exception from the user's work. On a
  # successful body, cleanup errors still propagate rather than disappearing.
  def run(fun, cleanup) do
    result = on_error(fun, cleanup)
    cleanup.()
    result
  end

  # Initialization keeps its resource on success and retires it on any failure.
  def on_error(fun, cleanup) do
    try do
      fun.()
    catch
      kind, reason ->
        stack = __STACKTRACE__
        on_error(cleanup)
        :erlang.raise(kind, reason, stack)
    end
  end

  def on_error(cleanup) do
    try do
      cleanup.()
    catch
      _, _ -> :ok
    end
  end
end
