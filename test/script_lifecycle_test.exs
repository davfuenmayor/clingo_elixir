defmodule Clingo.ScriptLifecycleTest do
  use ExUnit.Case, async: true

  for mode <- ["concurrent", "owner", "dispatcher", "restart"] do
    @mode mode
    test "global script lifecycle: #{@mode}" do
      {output, status} =
        Clingo.TestSupport.vm(
          [
            "-pa",
            Path.dirname(:code.which(Clingo.Native)),
            "-r",
            "test/support.ex",
            "test/fixtures/script_lifecycle.exs",
            @mode
          ],
          if(System.get_env("CLINGO_TSAN_RUNTIME"), do: 60_000, else: 15_000),
          [{"ERL_FLAGS", "+S 4:4 +SDcpu 4 +SDio 1"}]
        )

      assert status == 0, "exit #{status}:\n#{output}"
      assert output =~ "SCRIPT_LIFECYCLE_OK"
    end
  end
end
