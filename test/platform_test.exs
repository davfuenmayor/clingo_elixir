defmodule Clingo.PlatformTest do
  use ExUnit.Case, async: true
  alias Mix.Tasks.Compile.ClingoElixir, as: Compiler

  test "selects the matching bundle for each supported 64-bit runtime" do
    for {os, arch, target} <- [
          {{:unix, :linux}, "x86_64-pc-linux-gnu", "linux-x86_64"},
          {{:unix, :linux}, "aarch64-unknown-linux-gnu", "linux-aarch64"},
          {{:unix, :darwin}, "x86_64-apple-darwin", "macos-x86_64"},
          {{:unix, :darwin}, "aarch64-apple-darwin", "macos-aarch64"},
          {{:unix, :darwin}, "arm64-apple-darwin", "macos-aarch64"},
          {{:win32, :nt}, "AMD64", "windows-x86_64"}
        ] do
      assert Compiler.target(os, arch) == target
    end
  end

  test "rejects unsupported runtimes instead of selecting another ABI" do
    for {os, arch} <- [
          {{:unix, :linux}, "x86_64-linux-musl"},
          {{:unix, :linux}, "aarch64-linux-musl"},
          {{:unix, :linux}, "i686-linux-gnu"},
          {{:win32, :nt}, "ARM64"},
          {{:unix, :freebsd}, "x86_64"}
        ] do
      assert_raise Mix.Error, fn -> Compiler.target(os, arch) end
    end
  end

  test "fixed-width values and counts retain their native 64-bit sizes" do
    for type <- ~w(uint64_t int64_t size_t clingo_symbol_t clingo_signature_t) do
      assert {8, _, _} = Clingo.type(type)
    end

    Clingo.with_session(fn s ->
      for type <- ~w(uint64_t size_t clingo_symbol_t) do
        cell = Clingo.array(s, type, [0xFEDCBA9876543210])
        assert Clingo.read(s, cell) == 0xFEDCBA9876543210
      end
    end)
  end
end
