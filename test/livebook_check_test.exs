Code.require_file("../tools/livebook_check.exs", __DIR__)

defmodule Clingo.LivebookCheckTest do
  use ExUnit.Case, async: true
  alias Clingo.LivebookCheck

  test "aborted and interrupted evaluations fail rather than time out" do
    ready = %{errored: false, interrupted: false, validity: :evaluated}
    assert LivebookCheck.status([ready]) == :passed
    assert LivebookCheck.status([]) == :pending
    assert LivebookCheck.status([%{ready | validity: :fresh}]) == :pending

    for failure <- [
          %{ready | validity: :aborted},
          %{ready | interrupted: true},
          %{ready | errored: true}
        ] do
      assert LivebookCheck.status([ready, failure]) == :failed
    end
  end

  test "executable cells cannot silently disappear or use another language" do
    cell = %{language: :elixir, source: ":ok"}
    assert LivebookCheck.validate_cells!([cell], 1) == nil

    for cells <- [[], [%{cell | language: :python}], [%{cell | source: " "}]] do
      assert_raise RuntimeError, ~r/nonempty Elixir/, fn ->
        LivebookCheck.validate_cells!(cells, 1)
      end
    end
  end

  test "fingerprints change when notebook or helper content changes" do
    root =
      Path.join(System.tmp_dir!(), "livebook-fingerprint-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(root, "livebooks/support"))
    on_exit(fn -> File.rm_rf!(root) end)
    notebook = Path.join(root, "livebooks/example.livemd")
    helper = Path.join(root, "livebooks/support/course.exs")
    File.write!(notebook, "# Example")
    File.write!(helper, ":ok")
    original = LivebookCheck.fingerprints(root)
    File.write!(helper, ":changed")
    assert LivebookCheck.fingerprints(root) != original
    File.write!(helper, ":ok")
    File.write!(notebook, "# Changed")
    assert LivebookCheck.fingerprints(root) != original
  end
end
