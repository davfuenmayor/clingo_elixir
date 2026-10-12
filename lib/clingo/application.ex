defmodule Clingo.Application do
  @moduledoc false
  use Application
  def start(_, _), do: Supervisor.start_link([], strategy: :one_for_one, name: Clingo.Supervisor)

  def prep_stop(state) do
    Clingo.finalize_scripts()
    state
  end
end
