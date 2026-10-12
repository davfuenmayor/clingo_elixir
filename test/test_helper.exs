ExUnit.start()
Code.require_file("support.ex", __DIR__)

ExUnit.after_suite(fn result ->
  coverage = Clingo.Native.coverage()

  rows =
    coverage |> Enum.sort() |> Enum.map_join("\n", fn {name, count} -> "#{name}\t#{count}" end)

  File.mkdir_p!("_build/validation")

  File.write!(
    "_build/validation/coverage.tsv",
    "C function\tNative invocations\n" <> rows <> "\n"
  )

  if result.failures == 0 and System.get_env("CLINGO_RETAINED_COVERAGE") == "1" do
    missing = for {name, 0} <- coverage, do: name
    if missing != [], do: raise("Retained C operations not exercised: #{inspect(missing)}")
  end
end)
