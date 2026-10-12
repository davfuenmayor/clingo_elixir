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
        links: %{"Upstream clingo" => "https://github.com/potassco/clingo"},
        files: [
          ".formatter.exs",
          ".clang-format",
          "lib",
          "c_src",
          "tools/bootstrap.sh",
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

  def application, do: [extra_applications: [:logger], mod: {Clingo.Application, []}]
end

defmodule Mix.Tasks.Compile.ClingoElixir do
  use Mix.Task.Compiler

  def run(_) do
    prefix = System.get_env("CLINGO_PREFIX", "_upstream")

    patched? =
      File.read(Path.join(prefix, "share/clingo_elixir/upstream.patch")) ==
        {:ok, File.read!("tools/patches/clingo-5.8.2.patch")}

    if is_nil(System.get_env("CLINGO_PREFIX")) and
         (not File.exists?(Path.join(prefix, "lib/libclingo.so.4")) or not patched?) do
      {output, status} = System.cmd("bash", ["tools/bootstrap.sh"], stderr_to_stdout: true)
      if status != 0, do: Mix.raise(output)
      Mix.shell().info(output)
    end

    if System.get_env("CLINGO_PREFIX") && not patched?,
      do:
        Mix.raise(
          "CLINGO_PREFIX needs the pinned upstream fixes; build it with CLINGO_INSTALL_DIR=#{prefix} tools/bootstrap.sh"
        )

    {output, status} = System.cmd("make", ["--no-print-directory"], stderr_to_stdout: true)
    if status != 0, do: Mix.raise(output)
    if output != "", do: Mix.shell().info(output)
    # Native compilation can create priv after Mix first builds the app structure.
    Mix.Project.build_structure()
    {:ok, []}
  end

  def clean, do: System.cmd("make", ["clean"])
end
