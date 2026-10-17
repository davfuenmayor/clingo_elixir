defmodule Clingo.PinTest do
  use ExUnit.Case, async: true
  @moduletag skip: :os.type() != {:unix, :linux}

  test "control/handle aliases pin destruction through casts and cells" do
    dir = Path.join(System.tmp_dir!(), "clingo-pin-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    try do
      library = Path.join(dir, "pin.so")

      {output, 0} =
        System.cmd(
          "cc",
          [
            "-shared",
            "-fPIC",
            "-O0",
            "-Wall",
            "-Wextra",
            "-o",
            library,
            "tools/pin_probe.c",
            "-ldl"
          ],
          stderr_to_stdout: true
        )

      assert output == ""
      preload = Enum.join(Enum.reject([System.get_env("LD_PRELOAD"), library], &is_nil/1), ":")

      {output, status} =
        System.cmd(
          "timeout",
          [
            "-k",
            "2",
            "20",
            "elixir",
            "-pa",
            Path.dirname(:code.which(Clingo.Native)),
            "-r",
            "test/support.ex",
            "test/fixtures/pin_probe.exs"
          ],
          env: [
            {"LD_PRELOAD", preload},
            {"CLINGO_PIN_DIR", dir},
            {"ERL_FLAGS", "+S 2:2 +SDcpu 2 +SDio 2"}
          ],
          stderr_to_stdout: true
        )

      assert status == 0, "exit #{status}:\n#{output}"
      assert output =~ "PIN_PROBE_OK"
    after
      File.rm_rf!(dir)
    end
  end
end
