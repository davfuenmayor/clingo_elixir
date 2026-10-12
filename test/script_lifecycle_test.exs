defmodule Clingo.ScriptLifecycleTest do
  use ExUnit.Case, async: true

  for mode <- ["concurrent", "owner", "dispatcher", "restart"] do
    @mode mode
    test "global script lifecycle: #{@mode}" do
      {output, status} =
        System.cmd(
          "timeout",
          [
            "-k",
            "2",
            if(System.get_env("CLINGO_TSAN_RUNTIME"), do: "60", else: "15"),
            "elixir",
            "-pa",
            Path.dirname(:code.which(Clingo.Native)),
            "-r",
            "test/support.ex",
            "test/fixtures/script_lifecycle.exs",
            @mode
          ],
          env: [{"ERL_FLAGS", "+S 4:4 +SDcpu 4 +SDio 1"}],
          stderr_to_stdout: true
        )

      assert status == 0, "exit #{status}:\n#{output}"
      assert output =~ "SCRIPT_LIFECYCLE_OK"
    end
  end
end
