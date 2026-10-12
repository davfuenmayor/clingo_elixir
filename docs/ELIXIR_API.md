# Elixir interface

Use ASP text as the modeling language. The library adds ownership and data
conversion, without a modeling DSL. Generated C adapters and session/pointer
plumbing are private; use the capability modules described here.

```elixir
result = Clingo.solve!("{a;b}.", models: :all, symbols: true)
result.status # :satisfiable, :unsatisfiable or :unknown
Enum.map(result.models, & &1.shown)

Clingo.models("{a;b;c}.", models: :all) |> Enum.take(2)

Clingo.with_control([models: :all], fn c ->
  Clingo.Control.add!(c, "#external enabled. answer :- enabled.")
  Clingo.Control.ground!(c)
  Clingo.Control.assign_external!(c, Clingo.Symbol.parse!("enabled"), true)
  Clingo.Control.solve!(c)
end)
```

For file-only jobs, pass options directly: `Clingo.solve!(files: [path], models: :all)`.
The same form works with `Clingo.models/1` and `Clingo.Ground.to_string!/1`.
Files and inline ASP can also be combined: `Clingo.solve!(program, files: [path])`.
Relative `#include` directives resolve against the loaded file as in clingo.

## Supported options

| Entry point | Options |
|---|---|
| `Control.new!` / `with_control` | `models`, native `arguments`, two-argument `logger`, session limits in `session: [...]` |
| `Clingo.solve!` / `Clingo.models` | Control options plus `files`, grounding `context`, and solve options below |
| `Ground.to_string!` | Control options, `files`, `context`, `format: :aspif` (default) or `:reify` |
| `Control.ground!` | `context: %{binary_name => fn symbol_list -> symbol_or_list end}` |
| `Control.solve!` | `models`, `assumptions`, `show`, `symbols`, `async`, `collect`, snapshot `on_model` and native solve hooks |
| `Control.models` / `with_solve!` | `models`, `assumptions`, `show`, `symbols`, `async`, native solve hooks; consume models explicitly |

Native solve hooks are `on_model_view`, `on_unsat`, `on_statistics` and
`on_finish`. `on_model_view` returns `:cont` or `:halt`; the other notification
hook return values are ignored. `on_statistics` mutations go through the supplied
views. `on_model` consumes copied snapshots in the solving caller; native hooks
run in supervised callback workers. `files` is handled by the standalone entry
points; scoped controls use `Control.load!` explicitly. Unknown/duplicate options and invalid option values raise `ArgumentError` before
allocation or a solve lease. Stream option validation happens at construction;
solver errors occur during enumeration.

The native default is one model. Use `models: :all` to enumerate all models;
`exhausted` distinguishes completed search from a model limit. SAT with an
empty shown list is still SAT. Optimization snapshots include cost and proof
status; intermediate models need not be optimal. `show:` accepts the native
show bitset or a constant name. `symbols: true` adds decoded symbol structs.
Models, symbols and result structs survive control closure.

`Control.new!/1` requires explicit `Control.close/1`; prefer `with_control`.
Mutation returns `:ok`; native failures raise `Clingo.Error`. `solve!` collects
snapshots by default. `collect: false` discards them after delivery to
`on_model: fn snapshot -> :cont | :halt end`. Callback exceptions propagate.
Grounding context maps use binary function names and functions receiving a
list of decoded symbols, returning one symbol or a list of symbols.

`Control.models/2` streams on an existing control. Each enumeration takes an
exclusive solve lease. Finishing, early halt and exceptions close the cursor;
a killed consumer triggers dispatcher cleanup. Mutation and a second solve
are rejected while a solve is active. `Control.with_solve!/3` provides explicit
resume, model, wait, result, last, core and cancellation operations. With
`async: true`, resume is nonblocking; model retrieval waits for progress.
Interrupt and cancellation can be requested from another process. Closing an
owned control interrupts native solving before waiting for cleanup; arbitrary
Elixir hooks must still return. Close is idempotent. Closed controls raise
ArgumentError on use.

Configuration uses explicit binary/index paths and native string values:
`Configuration.put!(c, ["solve", "models"], "0")`. Statistics snapshots are
ordinary maps/lists/numbers. The `on_statistics` callback receives two scoped
writable `Statistics` views. `on_unsat` receives a copied lower-bound list;
`on_finish` receives a `Result`. Advanced `on_model_view` receives a scoped
`ModelView` for clause addition and extension; take a snapshot to retain data.

`Backend.with_backend/2` brackets begin/end. `Inspection` returns copied
symbolic/theory atom information. Propagator and observer registrations accept
hook maps, omit userdata and decode arrays. `View` provides named conveniences
and a complete scoped operation escape hatch. Propagator decide returns the
chosen literal; ordinary extension hooks return `:ok`.

`AST.with_ast/1` owns a session for parsing, named constructors and attribute
access. Functional updates reconstruct through the constructor, preserving the
original; postorder walks operate on acquired scoped references. ASTs
remain native objects and must stay inside their owning session. Use text or
copied attributes to retain results after closure. No extra AST DSL is added.

`Ground.to_string!/2` exports ASPIF or reified facts through clingo's native
backend. It grounds the source without searching its models, returns copied text,
and removes its temporary file on errors too. Use `files:` for source paths,
then `Control.load!` or `Clingo.solve!` for the returned ASPIF/reified text.
`Dimacs.solve!/2` handles DIMACS CNF and shows true variables as `v(N)`.

Tutorials use native export and managed solving. Starter encodings remain
learner exercises; advanced project briefs do not imply implemented applications.

For specialized applications outside notebooks, `CLI.run!/2` explicitly runs
a child process and `CLI.run_native!/2` embeds clingo's application hooks with
process-level I/O. Application/script main hooks receive borrowed controls.
`Script.register!/2` registers global language hooks until permanent
`Clingo.finalize_scripts/0`; coordinate this process-wide lifecycle.

Native hooks execute in supervised Elixir workers, with nested native calls
marshaled back to the original C callback thread. Avoid waiting synchronously
for ordinary same-session work from a hook. `SolveHandle.cancel!/1` waits for
search and rejects calls from native hooks; use `Control.interrupt!/1` there
(or return `:halt` from a model hook). Cross-process cancellation signals first,
then serializes draining with model copying and close; an in-flight model may
complete before cancellation takes effect. Callback views expire on return.
Managed solve-event failures stop continuation and become `Clingo.Error` at the
next handle operation, including close. The first failure is preserved (up to
4,095 diagnostic bytes); later events are skipped. This avoids clingo's fatal
false-return behavior for unsat/statistics/finish events, including async solves.
Pointer/count/output contracts are internal implementation details.

Managed grounding, solve hooks and copied symbolic/theory inspection release
transient payloads at operation completion, callback return or native solve-handle
close. The dispatcher unregisters transient Elixir functions. Copied configuration/
statistics queries, backend brackets and AST preparation use the same mechanism.
Persistent observer/propagator/logger registrations survive unrelated operations;
global scripts remain process-lived. Acquired ASTs survive callback retirement.

Expired identities remain while an escaped pointer or saved cell refers to them,
so address reuse cannot revive a stale view. BEAM garbage collection releases
those references; intentionally retaining expired views consumes bookkeeping.
Explicit internal arena allocations remain session-scoped. There is no need to
rotate controls merely to reclaim managed transient hooks or inspection cells.
This does not bound solver memory, BEAM heaps, temporary scratch or total RSS.

`mix run tools/benchmark.exs _build/validation/benchmark.json` records timings and
wrapper arena reservation after collecting caller/dispatcher/callback-supervisor
resources. Fixed-quota tests also exercise hundreds of operations without forced
GC in their loops. Benchmark samples are measurements, not universal performance or memory guarantees.

## Capability map

| Python/upstream concept | Supported Elixir interface |
|---|---|
| Control, solve, SolveHandle | Clingo, Control, SolveHandle |
| Symbol, Model, SolveResult | Symbol, copied Model, Result |
| Configuration, Statistics | Configuration paths, Statistics snapshots/views |
| Backend | Backend.with_backend |
| Symbolic/theory atoms | Inspection |
| Propagator, Observer | Control.register_propagator!/register_observer!, View |
| AST construction/transformation | AST.with_ast, constructors, get!/update!/walk! |
| ASPIF/reification | Ground.to_string! |
| DIMACS CNF | Dimacs.solve! |
| Specialized application/options, scripts | CLI, Script (outside notebook workflows) |

`Clingo.API` and `Clingo.Raw` have been removed from the public contract and
renamed under `Clingo.Internal` without aliases. Migrate control/solve/output
extraction to the managed modules. `Control.native/1` and root session/pointer
helpers remain undocumented internals for implementation and regression tests.
The selected C inventory is in `tools/api_scope.json`, not a promise to expose
every C declaration.

Symbol semantic fields are authoritative: editing a struct changes formatting
and encoding together. There is no cached `text` field. Numbers, strings and
bounds are constructed as copied Elixir data. Formatting delegates to clingo's
canonical printer in a temporary session (or the current callback session);
complex formatting still crosses the native boundary. Prefer `Model.shown`
when only display text is needed rather than decoding/reformatting symbols.
