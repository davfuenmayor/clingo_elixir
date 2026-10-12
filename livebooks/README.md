# Learn ASP with Elixir and clingo

Nineteen notebooks in five topic folders bring worked examples, prediction exercises and larger projects together. Start with [facts and rules](language/01-facts-and-rules.livemd) to learn ASP, or [Getting started](elixir/01-getting-started.livemd) if you already know ASP and want the Elixir API. Use the [concept and API index](CONCEPTS.md) to find a particular technique.

## Choose a route

For a first course, follow the six language notebooks in order, then graphs, grids and planning. The classification and configuration notebook applies the same ideas to different search spaces. The Elixir notebooks cover inputs, results, streams, incremental controls and inspection. Continue to extensions when you need callbacks, theory constraints, meta-programming or preferences.

Each notebook starts with its section list. Work through the small complete examples before attempting its larger exercises. Predict answer sets before evaluation and change one rule at a time. Compare models as sets, rather than relying on enumeration order. Starter encodings remain exercises; a satisfiable partial template does not establish that its missing constraints work. Keep the stated instance vocabulary and output predicates when comparing your solution with reference data.

<!-- topics:start -->

## ASP language

- [Facts, rules and alternatives](language/01-facts-and-rules.livemd)

- [Negation, recursion and support](language/02-negation-and-recursion.livemd)

- [Choices, cardinalities and constraints](language/03-choices-and-constraints.livemd)

- [Domains, grounding and arithmetic](language/04-domains-and-grounding.livemd)

- [Aggregates and conditional literals](language/05-aggregates-and-conditionals.livemd)

- [Optimization and projection](language/06-optimization-and-projection.livemd)

## Modeling problems

- [Graphs, sets and Boolean clauses](modeling/01-graphs-and-sets.livemd)

- [Grids and spatial puzzles](modeling/02-grids-and-puzzles.livemd)

- [Learning and product configuration](modeling/03-learning-and-configuration.livemd)

## Planning and scheduling

- [Actions, state transitions and robots](planning/01-actions-and-robots.livemd)

- [Scheduling, staffing and resources](planning/02-scheduling-and-resources.livemd)

## Elixir integration

- [Getting started with clingo_elixir](elixir/01-getting-started.livemd)

- [Inputs, symbols, results and streams](elixir/02-inputs-results-and-streams.livemd)

- [Incremental solving and changing inputs](elixir/03-incremental-solving.livemd)

- [Inspection, ASPIF and native export](elixir/04-inspection-and-export.livemd)

## Solver extensions and meta-programming

- [Observers, propagators and search agents](extensions/01-observers-and-propagators.livemd)

- [Theory constraints and solver evaluation](extensions/02-theory-constraints.livemd)

- [Meta-programming and program transformations](extensions/03-meta-programming.livemd)

- [Preference solving with repeated search](extensions/04-preference-solving.livemd)

<!-- topics:end -->

## Exercise files and expected answers

Each exercise bundle lives directly under `assets/<exercise>/`, with an encoding,
`instances/` and, where available, `solutions/`. Scheduling shares one input.
Workspace cells copy only the bundle being edited; downloads snapshot your edits.

Expected-answer JSON contains only `status`, `exhausted`, `models` and
`optimal_cost`. Each model is a sorted list of shown atoms, and the outer list is
sorted too. `models: []` means no model; `[[]]` includes a valid model with no
shown atoms. `optimal_cost: null` makes no optimality claim. A cost vector means
all listed models attain that proven optimum; intermediate candidates are omitted.
Compare complete shown model sets after exhausting the search. For optimization,
use `--opt-mode=optN`, compare only models with `optimality_proven: true`, and
check their costs against `optimal_cost`. Enumeration order is irrelevant. The
configuration lesson demonstrates the ordinary model-set comparison.

## Run locally

Keep the repository layout intact. Use a local Elixir 1.20 / OTP 29 Livebook runtime and the native build tools listed in the [project README](../README.md). Each notebook has one setup cell installing this checkout and Kino 0.19.0. The first installation needs network access.

Evaluate top to bottom. Edit ASP in a code cell, predict the result and reevaluate dependent cells. Worked examples check their stated answers; update those checks when changing a program. Exercise comparison tables keep independent variations in one editable list and show each program’s answer sets, status and exhaustion flag.

`Clingo.solve!` returns ordinary Elixir data; the display pipeline only presents it. `models: :all` enumerates models, and `files: [...]` loads files directly. All solving uses the wrapper. No notebook executes a CLI or shell. Theory syntax inspection does not install a theory solver.

File-based sections create their own disposable workspace. Run that section’s workspace cell before its file cells, download your edits before cleanup, and rerun the workspace cell for fresh files. The small `assets/` directory contains only linked lesson inputs, starter encodings and selected expected answers. Scheduling lessons share one instance; files written in cells are generated in the workspace. The shared `support/course.exs` handles files and presentation.

## Edit and test

Edit the `.livemd` files directly. After adding, renaming or moving a notebook, refresh the Markdown navigation:

```sh
python3 tools/index_livebooks.py
CLINGO_RETAINED_COVERAGE=1 mix test
elixir tools/check_livebooks.exs
```

The cell checker discovers notebooks directly, evaluates native examples, reports gated exercises separately, and verifies generated archive download bytes after cleanup. Native tests check worked answers, exercise predictions, links and complete Hanoi plans.

For actual Livebook imports and fresh-session evaluation:

```sh
mix escript.install hex livebook 0.19.9 --force
python3 tools/check_livebooks_runtime.py
```

The launcher owns an isolated local server and stops it afterward. The checker uses disposable copies and fresh sessions, rejects parser warnings, errors and timeouts, and closes every session. [Validation](VALIDATION.md) explains both checks. Reports are generated under `_build/validation/`; they are not part of the tutorial assets.
