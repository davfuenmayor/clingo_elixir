# clingo_elixir

An Elixir C NIF for clingo 5.8.2, with copied model/result values, scoped
controls, model streams and decoded extension hooks. The public interface follows
clingo capabilities; generated C adapters are private implementation details.

```elixir
Clingo.solve!("a. b :- a.").models |> Enum.map(& &1.shown)
# [["a", "b"]]

Clingo.models("{a;b;c}.", models: :all) |> Enum.take(2)
```

For repeated solving, keep a scoped control:

```elixir
alias Clingo.Control

Clingo.with_control(fn c ->
  Control.add!(c, "#external enabled. answer :- enabled.")
  Control.ground!(c)
  Control.assign_external!(c, "enabled", true)
  Control.solve!(c)
end)
```

Start with [the Elixir interface](docs/ELIXIR_API.md).

Long-lived controls reclaim temporary grounding, solve-hook and copied-inspection
storage, including transient Elixir callback registrations. Escaped native views
remain invalid after their scope ends; their identities survive until outstanding
references disappear. Persistent registrations and acquired ASTs retain their
own lifetimes. See [native ownership](docs/NATIVE_OWNERSHIP.md) for allocation
scopes and limits.
The selected release is **5.8.2**, commit `a99ffb2a58293c68b28fcc283a1d1c9ccad900fe`, verified against the [stable releases](https://github.com/potassco/clingo/releases) on 3 October 2026. The exact [release header](https://github.com/potassco/clingo/blob/v5.8.2/libclingo/clingo.h) is vendored and authoritative. The NIF refuses another clingo version. The [5.8 C documentation](https://potassco.org/clingo/c-api/5.8/) explains semantics, but its version macros describe 5.8.0; the pinned header determines this binding's inventory.

## Platforms and installation

Requires **64-bit Elixir 1.20.x and OTP 29+**. Mix selects and verifies a bundled
clingo 5.8.2 runtime and NIF. Available bundles need no system clingo, compiler,
or source download, including in Livebook.

| Platform | Status |
| --- | --- |
| Linux x86-64 | glibc 2.38+; bundled; full suite and all 19 Livebooks pass natively |
| Linux ARM64 | glibc 2.38+; bundled; NIF and CLI smoke checks pass under QEMU; full suite pending |
| Windows x86-64 | Windows 10+ intended; bundled; full suite and notebook cell checks pass under Wine; native Windows validation pending |
| macOS Intel / Apple Silicon | macOS 12+ intended; build path prepared; bundles and native validation pending |

Musl/Alpine, 32-bit BEAM, and Windows ARM64 are excluded. macOS is not yet
available out of the box. See [MULTIPLATFORM.md](MULTIPLATFORM.md) for build
and test instructions, recorded results, and remaining work.

```sh
mix test
CLINGO_RETAINED_COVERAGE=1 mix test
```

From another project, add `{:clingo_elixir, path: "/path/to/clingo_elixir"}`.
The package includes a small CLI driver for specialized application use;
Livebooks use the NIF directly. Python and Lua are disabled in bundles;
Elixir scripting hooks remain available. Restart the VM after native upgrades.

### Build or bring your own bundle

Run `tools/build-runtime.sh`, then `mix clean` and `mix test`. On macOS install
Xcode Command Line Tools and CMake/Ninja; on Windows use MSYS2 MINGW64 with the
POSIX MinGW toolchain and Windows Erlang/Elixir on `PATH`. CPU tuning permits
local performance experiments, but reliability and speed must be tested.

Set `CLINGO_ELIXIR_BUNDLE` to a complete archive’s absolute native path before
compiling or starting Livebook, with its matching `.sha256` alongside it.
The same checksum and target checks apply. `CLINGO_PREFIX` retains the explicit
source-development route for custom/sanitizer builds; it requires the exact
patched header and matching patch record. See [the full build guide](MULTIPLATFORM.md).

## Capabilities and compatibility

Use the managed modules for solving, configuration/statistics, AST transformation,
backend construction, atom inspection, and propagation/observer hooks. Native
application and scripting adapters remain specialized process-level capabilities.
The retained C dependencies and exclusions are explicit in
[api_scope.json](tools/api_scope.json); adding a header declaration no longer adds
an Elixir product feature automatically. The coverage gate exercises that inventory.

The managed capability modules define the supported API. `Clingo.Internal.API`
and pointer/session helpers are implementation details without a compatibility
promise.

`Clingo.Ground.to_string!(program, format: :aspif | :reify)` uses clingo's native
backend to export grounding, with deterministic temporary-file cleanup.
`Clingo.Dimacs.solve!` translates CNF examples to ASP and returns `Clingo.Result`.
All Livebook clingo examples use the wrapper; no notebook executes a CLI or shell.

## Lifetimes and limits

Controls, solve handles and owned/acquired AST references are tracked and released on session close. Explicit internal output cells and retained strings stay in the session arena until close; expired borrowed pointers are rejected. Pointer-valued cells retain their target's lifetime identity, so rereading a cell cannot revive a freed object, including when clingo reuses its address. Borrowed const storage rejects direct writes and native calls that require writable pointers; casts preserve read-only status. If a session owner dies, its dispatcher releases the session asynchronously. Callback workers are supervised and monitored: session shutdown terminates blocked workers, and a killed worker becomes a native error.

Native model views expire on resume/close, callback objects expire on callback return, and atom views expire on grounding/cleanup. Copied Elixir models and results remain usable. Acquiring an AST makes its reference survive callback return. Arrays retain their own storage; reading symbols or numbers copies values into Elixir. Follow the upstream lifecycle and state contracts for all other borrowed views.

Callers must use valid native IDs, operation ordering and flags. The internal bridge uses explicit C counts and output cells. `cast/4` exists for typed `void*` callback payloads; the C API does not describe their allocation sizes, so the caller must supply the correct type and bounds. Resource provenance, integer ranges, required pointers and owned-buffer bounds are checked, but this is not a sandbox for arbitrary violations of C preconditions.

The default per-allocation limit is 64 MiB; rebuild with `make MAX_ALLOC=...` to change it. `Clingo.open(max_arena: bytes, max_queue: count, max_callbacks: count)` controls the aggregate wrapper arena (default 256 MiB), waiting operations (1,024) and pending callback workers (1,024). `Clingo.memory/1` reports arena reservation and limit. The quota excludes ERTS, temporary scratch and upstream allocations. Pointer and slot lookups use hash indexes. A single managed cleanup worker drains destructor requests without allocating or invoking clingo on ordinary schedulers. Managed operation payloads retire at grounding/query completion, callback return or native solve-handle close. Expired identities remain while aliases or saved cells reference them and are reclaimed after BEAM resource collection. Deliberate internal arena allocations remain until session close. Fixed-quota regressions cover repeated hooks and copied inspection. Close sessions when they are no longer needed. A callback must eventually return; interrupting native solving cannot terminate arbitrary Elixir callback code.

Clingo registers scripting languages globally and has no unregister API. Registered script sessions therefore live for the process lifetime and cannot be individually closed. `Clingo.finalize_scripts/0` runs each script's `free` hook once and releases native objects before shutdown; it permanently ends scripting for this VM. Stopping the `:clingo_elixir` application invokes this finalizer automatically. Abrupt VM termination cannot run Elixir cleanup; native exit hooks suppress callbacks into a stopped runtime. The retained registry storage remains until process exit because upstream retains its pointers.

`clingo_main` preserves native exit codes and process-level I/O. It can read standard input and write directly to native stdout/stderr. Applications must coordinate their use of this process-wide interface and the scripting registry.

File-only jobs accept options directly: `Clingo.solve!(files: [path], models: :all)`.
`Clingo.models/1` and `Clingo.Ground.to_string!/1` accept the same form.

See [validation](docs/VALIDATION.md) and [contributor guidance](CONTRIBUTING.md).

`mix hex.build` includes the available native bundles and their notices. Installing the package extracts a checked bundle without compiling upstream. Contributor checks cover native generation, allocation probes, sanitizers, and compiler-free packaging; see [validation](docs/VALIDATION.md). No package is published automatically.

Callback transport accepts at most 4,096 structural steps and nesting depth 32 per native job or reply. Oversized terms fail promptly; array writes inside callbacks are submitted in bounded chunks so they can progress even when every dirty CPU scheduler is waiting on a callback. Deeply nested job arguments and large callback return terms can still exceed this transport limit.

## Livebooks

Start with the [Livebook launch guide](livebooks/intro.livemd) for first-time setup.
The [ASP and Elixir course](livebooks/README.md) contains 19 notebooks across five topic folders, bringing worked examples and exercises together. Start with [facts and rules](livebooks/language/01-facts-and-rules.livemd) to learn ASP, or [Getting started](livebooks/elixir/01-getting-started.livemd) for the wrapper API. See the course README for setup and testing.

## License

Licensed under [MIT](LICENSE). Upstream material retains its original copyrights
and licenses, as described in that file.
