defmodule ClingoElixir.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :clingo_elixir,
      version: "0.1.0",
      elixir: "~> 1.20.0",
      description: "Scoped Elixir interface and C NIF for clingo 5.8.2",
      package: [
        licenses: ["MIT"],
        build_tools: ["mix"],
        links: %{"Upstream clingo" => "https://github.com/potassco/clingo"},
        files: [
          ".formatter.exs",
          ".clang-format",
          "lib",
          "c_src",
          "tools/bootstrap.sh",
          "tools/build-runtime.sh",
          "native",
          "MULTIPLATFORM.md",
          "tools/patches",
          "tools/ast_constructors.json",
          "mix.exs",
          "Makefile",
          "README.md",
          "LICENSE",
          "CONTRIBUTING.md",
          "docs"
        ]
      ],
      test_ignore_filters: [~r/support/, ~r/fixtures/],
      compilers: [:clingo_elixir] ++ Mix.compilers(),
      deps: []
    ]

  def application, do: [extra_applications: [:logger, :crypto], mod: {Clingo.Application, []}]
end

defmodule Mix.Tasks.Compile.ClingoElixir do
  use Mix.Task.Compiler

  def run(_) do
    if prefix = System.get_env("CLINGO_PREFIX") do
      unless File.read(Path.join(prefix, "share/clingo_elixir/upstream.patch")) ==
               {:ok, File.read!("tools/patches/clingo-5.8.2.patch")},
             do: Mix.raise("CLINGO_PREFIX requires the pinned fixes; see MULTIPLATFORM.md")

      {output, status} = System.cmd("make", ["--no-print-directory"], stderr_to_stdout: true)
      if status != 0, do: Mix.raise(output)
      if output != "", do: Mix.shell().info(output)
      File.rm("priv/.bundle")
    else
      install_bundle()
    end

    Mix.Project.build_structure()
    app_priv = Path.join(Mix.Project.app_path(), "priv")
    # Windows can copy priv before custom compilers run instead of symlinking it.
    if File.read(Path.join(app_priv, ".bundle")) != File.read("priv/.bundle") or
         (:os.type() == {:win32, :nt} and System.get_env("CLINGO_PREFIX")) do
      File.cp_r!("priv", app_priv)
    end

    {:ok, []}
  end

  defp install_bundle do
    if :erlang.system_info(:wordsize) != 8,
      do: Mix.raise("clingo_elixir requires a 64-bit Erlang runtime")

    os = :os.type()

    arch =
      if os == {:win32, :nt},
        do: System.get_env("PROCESSOR_ARCHITECTURE", "unknown"),
        else: to_string(:erlang.system_info(:system_architecture))

    target = target(os, arch)
    archive = System.get_env("CLINGO_ELIXIR_BUNDLE") || "native/clingo-5.8.2-#{target}.tar.gz"

    unless File.regular?(archive),
      do: Mix.raise("Missing #{target} clingo bundle. See MULTIPLATFORM.md")

    {:ok, _} = Application.ensure_all_started(:crypto)
    expected = File.read!(archive <> ".sha256") |> String.trim()
    actual = :crypto.hash(:sha256, File.read!(archive)) |> Base.encode16(case: :lower)
    if actual != expected, do: Mix.raise("clingo runtime archive checksum mismatch")
    extension = if os == {:win32, :nt}, do: "dll", else: "so"
    executable = if os == {:win32, :nt}, do: "clingo.exe", else: "clingo"

    library =
      case os do
        {:win32, :nt} -> "libclingo.dll"
        {:unix, :darwin} -> "libclingo.4.dylib"
        _ -> "libclingo.so.4"
      end

    installed? = fn ->
      File.read("priv/.bundle") == {:ok, expected} and
        Enum.all?(
          ["clingo_elixir.#{extension}", executable, library],
          &File.regular?(Path.join("priv", &1))
        )
    end

    unless installed?.() do
      staging = "_build/.clingo-unpack-#{System.pid()}-#{System.unique_integer([:positive])}"
      File.mkdir_p!(staging)

      try do
        case :erl_tar.extract(String.to_charlist(archive), [
               :compressed,
               {:cwd, String.to_charlist(staging)}
             ]) do
          :ok -> :ok
          {:error, reason} -> Mix.raise("Cannot unpack clingo runtime: #{inspect(reason)}")
        end

        home = Path.join(staging, "clingo")

        unless File.read(Path.join(home, "target")) == {:ok, target <> "\n"},
          do: Mix.raise("clingo bundle does not match #{target}")

        File.write!(Path.join(home, ".bundle"), expected)

        unless installed?.() do
          File.rm_rf!("priv")

          case File.rename(home, "priv") do
            :ok ->
              :ok

            {:error, reason} ->
              unless File.read("priv/.bundle") == {:ok, expected},
                do: Mix.raise("Cannot install clingo runtime: #{inspect(reason)}")
          end
        end
      after
        File.rm_rf!(staging)
      end
    end
  end

  def clean do
    File.rm_rf!("priv")
    :ok
  end

  def target(os, arch) do
    cpu = arch |> String.split("-") |> hd()

    case {os, cpu, String.contains?(arch, "musl")} do
      {{:unix, :linux}, "x86_64", false} ->
        "linux-x86_64"

      {{:unix, :linux}, "aarch64", false} ->
        "linux-aarch64"

      {{:unix, :darwin}, "x86_64", false} ->
        "macos-x86_64"

      {{:unix, :darwin}, cpu, false} when cpu in ["aarch64", "arm64"] ->
        "macos-aarch64"

      {{:win32, :nt}, cpu, false} when cpu in ["AMD64", "amd64", "x86_64"] ->
        "windows-x86_64"

      _ ->
        Mix.raise("Unsupported clingo platform: #{inspect(os)} / #{arch}. See MULTIPLATFORM.md")
    end
  end
end
