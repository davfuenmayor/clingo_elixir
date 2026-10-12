defmodule Clingo.Dispatch do
  @moduledoc false

  # Only normal teardown and a missing server mean "closed". Crashes and
  # timeouts must retain their reason and stack for callers to diagnose.
  def stop(pid) do
    try do
      GenServer.stop(pid)
    catch
      :exit, {reason, _} when reason in [:noproc, :normal, :shutdown] -> :ok
    end
  end

  def call(pid, message, timeout \\ 5_000) do
    try do
      GenServer.call(pid, message, timeout)
    catch
      :exit, {reason, {GenServer, :call, _}} when reason in [:noproc, :normal, :shutdown] ->
        {:error, :closed}
    end
  end
end
