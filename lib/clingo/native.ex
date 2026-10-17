defmodule Clingo.Native do
  @moduledoc false
  @on_load :load
  def load do
    path =
      :code.priv_dir(:clingo_elixir)
      |> :filename.join(~c"clingo_elixir")
      |> :filename.nativename()

    case :erlang.load_nif(path, 0) do
      {:error, {reason, message}} = error ->
        IO.warn(
          "clingo_elixir could not load #{path}: #{reason}: #{message}. " <>
            "Requires a matching 64-bit bundle, Elixir 1.20/OTP 29, clingo 5.8.2. " <>
            "Rebuild the package for this runtime and restart the VM; see README.md."
        )

        error

      result ->
        result
    end
  end

  def open(_dispatcher), do: :erlang.nif_error(:not_loaded)
  def open(_dispatcher, _limit), do: :erlang.nif_error(:not_loaded)
  def run(_session, _operation, _args), do: :erlang.nif_error(:not_loaded)
  def run(_session, _operation, _args, _scope), do: :erlang.nif_error(:not_loaded)
  def nested(_session, _request, _operation, _args), do: :erlang.nif_error(:not_loaded)
  def nested(_session, _request, _operation, _args, _scope), do: :erlang.nif_error(:not_loaded)
  def reply(_request, _value), do: :erlang.nif_error(:not_loaded)
  def abort(_session), do: :erlang.nif_error(:not_loaded)
  def close(_session), do: :erlang.nif_error(:not_loaded)
  def cancel(_session, _handle), do: :erlang.nif_error(:not_loaded)
  def interrupt(_session, _control), do: :erlang.nif_error(:not_loaded)
  def interrupt(_control), do: :erlang.nif_error(:not_loaded)
  def finalize_scripts, do: :erlang.nif_error(:not_loaded)
  def coverage, do: :erlang.nif_error(:not_loaded)
  def constants, do: :erlang.nif_error(:not_loaded)
  def types, do: :erlang.nif_error(:not_loaded)
  def cleanup_wait, do: :erlang.nif_error(:not_loaded)
  def callback_arity(_type), do: :erlang.nif_error(:not_loaded)
end
