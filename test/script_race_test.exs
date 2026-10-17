defmodule Clingo.ScriptRaceTest do
  use ExUnit.Case, async: true

  test "registration racing global finalization neither deadlocks nor loses free hooks" do
    for _ <- 1..3 do
      {output, status} =
        Clingo.TestSupport.vm(
          [
            "-pa",
            Path.dirname(:code.which(Clingo.Native)),
            "test/fixtures/script_race.exs"
          ],
          10_000,
          [{"ERL_FLAGS", "+S 2:2 +SDcpu 2 +SDio 1"}]
        )

      assert status == 0, output
      assert output =~ "SCRIPT_RACE_OK"
    end
  end
end
