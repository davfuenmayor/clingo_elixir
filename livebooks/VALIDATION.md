# Livebook validation

The course contains a launch guide and 19 executable notebooks in five topic folders, with 409
executable cells and 60 supporting files. Tests reject unlinked assets and duplicate
contents. Each lesson has one dependency setup cell and a real solver readiness
check in its Preliminaries section; file-based sections use isolated,
editable workspaces and generate downloads from current edits.

Run from the project root:

```sh
CLINGO_RETAINED_COVERAGE=1 mix test
elixir tools/check_livebooks.exs
python3 tools/check_livebooks_runtime.py
```

Use Elixir 1.20.x, OTP 29.x, Kino 0.19.0 and Livebook 0.19.9. See [setup](README.md).

The native suite checks notebook structure, links, syntax, isolated writes,
file-only inputs, streams, export, expected-error handling and copied-model tables.
Worked answers include complete model-set comparisons for six modeling references,
every Hanoi plan, workload arithmetic, bike configurations and Latin squares.
Expected-answer JSON stores sorted shown atom sets, search completion and optional
proven optimal costs; see [answer conventions](README.md#exercise-files-and-expected-answers).

The cell checker evaluates each lesson twice in one VM, retaining its aliases
and bindings between cells as Livebook does. It separates examples,
expected errors, pending exercises and cleanup. It exercises actual Kino archive
download events and checks their bytes after workspace deletion. Its report is
`_build/validation/livebook-cells.json`.

The runtime checker owns an isolated Livebook server, imports disposable copies
and evaluates fresh sessions. It rejects parser warnings, executable-language
changes, errors, interruptions, aborted cells and timeouts, then closes each session
and stops the server. Its report is `_build/validation/livebook-runtime.json`.

Both reports record source fingerprints, versions and timestamps. A subset run
replaces its report and does not establish whole-course coverage. Generated
reports stay in the ignored build tree; they are not teaching assets.

No notebook executes a CLI or shell. Unfinished encodings remain learner exercises
and gated runs report them explicitly. Theory syntax alone does not enforce
arithmetic. Browser layout is outside these checks. Native sanitizer and package
checks have separate scopes; see [project validation](../docs/VALIDATION.md).
