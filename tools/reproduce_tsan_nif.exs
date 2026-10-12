defmodule ClingoTsanPositiveControl do
  @on_load :load
  def load, do: :erlang.load_nif(System.argv() |> hd() |> String.to_charlist(), 0)
  def race, do: :erlang.nif_error(:not_loaded)
end

ClingoTsanPositiveControl.race()
