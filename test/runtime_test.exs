defmodule Clingo.RuntimeTest do
  use ExUnit.Case, async: false

  test "the complete app relocates to a path with spaces without a clingo installation" do
    root = Path.join(System.tmp_dir!(), "clingo relocated #{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    app = Path.join(root, "clingo_elixir")
    File.mkdir_p!(app)
    File.cp_r!(Path.dirname(:code.which(Clingo)), Path.join(app, "ebin"))
    File.cp_r!("priv", Path.join(app, "priv"))
    path = Path.join(root, "check.exs")

    File.write!(path, """
    %Clingo.Result{status: :satisfiable, models: [%{shown: ["a"]}]} = Clingo.solve!("a.")
    %Clingo.Result{models: [%{shown: ["a(42)"]}]} = Clingo.solve!("a(@answer()).", context: %{"answer" => fn [] -> Clingo.Symbol.number(42) end})
    %Clingo.Result{models: [%{shown: ["a(-2147483648)"]}]} = Clingo.solve!("a(-0o20000000000).")
    [%{shown: [_]}] = Clingo.models("1 {a;b} 1.", models: :all) |> Enum.take(1)
    %{exit_code: 0, output: output} = Clingo.CLI.run!(["--version"])
    true = output =~ "5.8.2"
    IO.puts("RELOCATED_RUNTIME_PASS")
    """)

    {output, status} = Clingo.TestSupport.vm(["-pa", Path.join(app, "ebin"), path])
    assert status == 0, output
    assert output =~ "RELOCATED_RUNTIME_PASS"
  end
end
