# Reproducible wrapper sample: mix run tools/benchmark.exs [report.json]
# Timings include dispatch and solver work. Arena counts exclude upstream,
# temporary scratch and BEAM allocations; they are not process RSS estimates.
alias Clingo.{Control, ModelView, Statistics, Symbol}
n = String.to_integer(System.get_env("CLINGO_BENCH_ITERATIONS", "100"))
true = n > 0

retained = fn c ->
  state = :sys.get_state(c.session.dispatcher)
  :erlang.garbage_collect()
  :erlang.garbage_collect(c.session.dispatcher)
  :erlang.garbage_collect(state.workers)
  Clingo.memory(c.session) |> Tuple.to_list()
end

measure = fn name, program, opts, run ->
  Clingo.with_control([models: :all], fn c ->
    Control.add!(c, program)
    Control.ground!(c)
    if name == "grounding_context", do: Control.add!(c, "part", ["n"], "a(n,@value()).")
    before = retained.(c)
    {elapsed, _} = :timer.tc(fn -> for _ <- 1..n, do: run.(c, opts) end)
    after_use = retained.(c)

    %{
      name: name,
      iterations: n,
      elapsed_us: elapsed,
      arena_before: before,
      arena_after: after_use
    }
  end)
end

{one_shot, _} = :timer.tc(fn -> for _ <- 1..n, do: Clingo.solve!("a.") end)

rows = [
  %{
    name: "one_shot",
    iterations: n,
    elapsed_us: one_shot,
    arena: "each call owns and closes its session"
  },
  measure.("repeated_solve", "{a;b}.", [], &Control.solve!/2),
  measure.("enumerate_256_models", "{a(1..8)}.", [], fn c, _ -> Enum.count(Control.models(c)) end),
  measure.("structured_symbols", "a(f(42),\"text\").", [symbols: true], &Control.solve!/2),
  measure.("finish_hook", "a.", [on_finish: fn _ -> :ok end], &Control.solve!/2),
  measure.(
    "statistics_hook",
    "a.",
    [on_statistics: fn step, _ -> Statistics.put!(step, ["custom"], 42) end],
    &Control.solve!/2
  ),
  measure.(
    "live_model_hook",
    "a.",
    [
      on_model_view: fn view ->
        ModelView.snapshot!(view)
        :cont
      end
    ],
    &Control.solve!/2
  ),
  measure.("grounding_context", "", [], fn c, _ ->
    Control.ground!(c, [{"part", [Symbol.number(1)]}],
      context: %{"value" => fn [] -> Symbol.number(42) end}
    )
  end)
]

# Stateless leaves use copied Elixir data. Complex formatting still delegates to
# clingo; record its cost explicitly instead of hiding it in the model benchmark.
leaf = Symbol.number(42)
nested = Symbol.parse!("f(g(h(42)),\"text\")")

symbol_rows =
  for {name, fun} <- [
        {"number_leaf", fn -> Symbol.number(42) end},
        {"string_leaf", fn -> Symbol.string("text") end},
        {"parse_number", fn -> Symbol.parse!("42") end},
        {"format_number", fn -> to_string(leaf) end},
        {"format_nested", fn -> to_string(nested) end}
      ] do
    {elapsed, _} = :timer.tc(fn -> for _ <- 1..n, do: fun.() end)
    %{name: name, iterations: n, elapsed_us: elapsed}
  end

rows =
  rows ++
    symbol_rows ++
    [
      measure.("bulk_100_facts", "p(1..100).", [symbols: true], &Control.solve!/2),
      measure.("inspect_100_atoms", "p(1..100).", [], fn c, _ ->
        Clingo.Inspection.symbolic_atoms!(c)
      end)
    ]

report = %{
  generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
  elixir: System.version(),
  otp: System.otp_release(),
  clingo: Tuple.to_list(Clingo.version()),
  memory_scope:
    "wrapper arena after collecting caller/dispatcher/callback supervisor resources; excludes upstream, scratch, BEAM and RSS",
  cases: rows
}

json = JSON.encode!(report)

case System.argv() do
  [] ->
    IO.puts(json)

  [file] ->
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, json <> "\n")
    IO.puts("Wrote #{file}")
end
