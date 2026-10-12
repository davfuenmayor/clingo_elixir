# Maintaining clingo_elixir

Keep the C wrapper thin and preserve clingo's concepts and state contracts.
The managed capability modules define the public Elixir API; tutorials demonstrate
it without defining its full scope. ASP remains the modeling language. Add
behavioral ExUnit tests instead of Dialyzer specs or redundant abstraction layers.

## Build and generation

Start with the [build instructions](README.md#build-and-test). The library has no
runtime Hex dependencies or libffi dependency. Python and clang are contributor
tools. Handwritten Elixir follows `.formatter.exs`; handwritten C follows
`.clang-format`. Edit generators rather than generated files.

```sh
make generate
mix format --check-formatted
CLINGO_RETAINED_COVERAGE=1 mix test
python3 tools/check_generation.py
```

`tools/generate.py` reads the pinned header through clang and generates typed C
thunks, internal Elixir adapters, conversion metadata, `tools/api.json` and
[the operation inventory](docs/COVERAGE.md). Native `sizeof` and `offsetof`
determine layouts. Elixir metadata contains only reachable conversion facts;
ABI declarations remain in the contributor inventory, outside runtime `priv` assets. Generation rejects drift and
the loader verifies AST constructor metadata.

Review these inputs when changing a binding:

- `tools/api_scope.json` selects relevant dependencies, exclusions and native-only
  helpers. Header growth does not automatically expand the Elixir API.
- `tools/api_policy.json` defines direction, ownership, nullability, array sizes
  and invalidation for each declaration.
- `tools/callback_sites.json` identifies userdata and callback registration sites;
  `tools/callback_policy.json` defines Elixir hook conversions.
- `tools/ast_constructors.json` pins the finite AST constructor signatures.

Regenerate after adding tests: the inventory includes test-file references.
The coverage gate requires every retained native operation to execute, but does
not establish exhaustive parameter/state coverage. Literal C boundary probes
live in `tools/raw_probe.exs`; they are test support, not a public facade.

For an upstream upgrade, verify and pin the release commit in `tools/bootstrap.sh`,
replace the header, review the policies and update the native version check and
user documentation together. Review the [local upstream patch](tools/patches/README.md)
and remove fixes accepted upstream. Never replace a fix with a broad sanitizer rule.

## Ownership and callbacks

Read [native ownership](docs/NATIVE_OWNERSHIP.md) before lifetime changes. Normal calls
serialize per session; nested callback jobs execute on their originating C thread.
Interrupt/cancel use a separate pinned path. Close handles before controls and
keep callbacks alive through native completion. Destructor enqueueing must remain
allocation-free; the cleanup worker is joined at unload.

The dispatcher attaches a managed cursor when its native open completes, before
replying to the caller. Preserve cleanup when an opening consumer dies or a queued
open is abandoned. Do not add another attachment handshake.

Global script registrations outlive unrelated controls. Upstream has no unregister
operation; permanent finalization runs `free` hooks before closing script sessions.
Never call Elixir after VM teardown. A callback must return and cannot wait for
another ordinary operation in its own session.

## Validation and release

Run the [release checks](docs/VALIDATION.md) sequentially when they rebuild native
libraries. Allocation probes and sanitizer scripts restore the normal delivery
build. Package acceptance tests the actual source archive, clean bootstrap,
relocation and a minimal runtime; it never publishes. The Hex archive includes
build inputs, library sources and documentation, with maintainer probes and run
logs left out. Use the repository checkout for contributor checks.

Generated reports belong in `_build/validation/`, not source directories.
`tools/check_package.py` requires root for its minimal-runtime chroot and retains
the accepted archive under `_release/` with a checksum report. Preserve the
sanitizer limitations documented in validation; passing tests are not proof of
race freedom or arbitrary native-state safety.

For tutorial changes, edit `.livemd` files directly and run:

```sh
python3 tools/index_livebooks.py
elixir tools/check_livebooks.exs
python3 tools/check_livebooks_runtime.py
```

See [Livebook setup](livebooks/README.md). All notebooks use the wrapper; no CLI or
shell execution. Keep incomplete exercises explicit and distinguish theory syntax
from implemented semantics. Tests reject orphaned assets and duplicate contents.

## Deferred improvements

Recursive `Symbol.decode/2` crosses the boundary for each nested symbol. Profile
nested model workloads before adding a bounded copied decode reply; preserve
transport limits and callback progress. Add no cached sessions or ASP formatter.
`mix run tools/benchmark.exs _build/validation/benchmark.json` records workflow
timings and retained arena reservation after resource collection.

Submitting the local upstream fixes is optional; include the standalone integer
and parallel-control reproducers. Broader arithmetic hardening, prebuilt binaries,
additional platforms and optional Python/Lua builds require separate validation.
Native upgrades require a VM restart; global script finalization is permanent.
