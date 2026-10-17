defmodule Clingo.BundleTest do
  use ExUnit.Case, async: true

  setup do
    root = Path.join(System.tmp_dir!(), "clingo-bundle-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    File.cp!("mix.exs", Path.join(root, "mix.exs"))
    on_exit(fn -> File.rm_rf!(root) end)
    os = :os.type()

    arch =
      if os == {:win32, :nt},
        do: "AMD64",
        else: to_string(:erlang.system_info(:system_architecture))

    target = Mix.Tasks.Compile.ClingoElixir.target(os, arch)

    files =
      case os do
        {:win32, :nt} -> ~w(clingo_elixir.dll clingo.exe libclingo.dll)
        {:unix, :darwin} -> ~w(clingo_elixir.so clingo libclingo.4.dylib)
        _ -> ~w(clingo_elixir.so clingo libclingo.so.4)
      end

    %{root: root, target: target, files: files}
  end

  test "custom bundles install and missing native files are restored", ctx do
    archive = bundle(ctx, ctx.target)
    [file | _] = ctx.files

    {output, status} =
      run(ctx, archive, """
      true = File.regular?("priv/#{file}")
      File.rm!("priv/#{file}")
      Mix.Task.rerun("compile.clingo_elixir")
      true = File.regular?("priv/#{file}")
      IO.puts("BUNDLE_RESTORED")
      """)

    assert status == 0, output
    assert output =~ "BUNDLE_RESTORED"
  end

  test "corrupted archives are rejected before extraction", ctx do
    archive = bundle(ctx, ctx.target)
    File.write!(archive, "corrupt", [:append])
    {output, status} = run(ctx, archive)
    assert status != 0
    assert output =~ "checksum mismatch"
    refute File.exists?(Path.join(ctx.root, "priv/.bundle"))
  end

  test "a valid checksum cannot override the archive target", ctx do
    archive = bundle(ctx, "another-target")
    {output, status} = run(ctx, archive)
    assert status != 0
    assert output =~ "bundle does not match"
    refute File.exists?(Path.join(ctx.root, "priv/.bundle"))
  end

  defp bundle(ctx, target) do
    archive = Path.join(ctx.root, "custom.tar.gz")

    files =
      [{~c"clingo/target", target <> "\n"}] ++
        Enum.map(ctx.files, &{String.to_charlist("clingo/#{&1}"), "fixture"})

    :ok = :erl_tar.create(String.to_charlist(archive), files, [:compressed])
    checksum = :crypto.hash(:sha256, File.read!(archive)) |> Base.encode16(case: :lower)
    File.write!(archive <> ".sha256", checksum <> "\n")
    archive
  end

  defp run(ctx, archive, after_compile \\ "") do
    script = Path.join(ctx.root, "check.exs")

    File.write!(script, """
    File.cd!(#{inspect(ctx.root)})
    System.delete_env("CLINGO_PREFIX")
    System.put_env("CLINGO_ELIXIR_BUNDLE", #{inspect(archive)})
    Mix.CLI.main(["compile"])
    #{after_compile}
    """)

    Clingo.TestSupport.vm([script])
  end
end
