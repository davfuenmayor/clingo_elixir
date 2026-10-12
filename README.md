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

Supported environment: Linux x86_64 with glibc, Elixir 1.20.x and Erlang/OTP 29.x. Release validation targets Debian 13 (glibc 2.41), Elixir 1.20.4, OTP 29 / ERTS 17.1, GCC 14.2 and patched clingo 5.8.2. Other Linux distributions/toolchains are unvalidated. Other operating systems and architectures are not supported in this iteration. NIF hot upgrades while resources or registered scripts are alive are unsupported; restart the VM for native code upgrades. Python and Lua are disabled by default; `CLINGO_PYTHON=ON` / `CLINGO_LUA=ON` enable optional upstream builds when their development dependencies are installed (not validated here); the specialized scripting adapter remains available.

## Build and test

Build prerequisites on Debian:

```sh
apt-get update
apt-get install -y build-essential cmake git pkg-config
cd clingo_elixir
./tools/bootstrap.sh
mix test
CLINGO_RETAINED_COVERAGE=1 mix test
```

`bootstrap.sh` reuses the adjacent `clingo-5.8.2` checkout when present, otherwise clones upstream, and verifies the pinned commit, applies the [documented upstream fixes](tools/patches/README.md) to a private source export, builds its shared library and installs it locally. The original checkout remains unchanged. To reuse the provided release checkout, run `CLINGO_SOURCE=/workspace/clingo-5.8.2 ./tools/bootstrap.sh`. `BUILD_JOBS` controls parallel compilation. The Mix compiler runs Make, verifies the installed header and copies `libclingo.so.4` into `priv`; the NIF loads that copy using `$ORIGIN`. Running the library requires the usual C/C++ runtime libraries. There is no libffi dependency; typed generated adapters cover callbacks, function pointers and AST constructors. A CLI driver is built for specialized application use; Livebooks never invoke it. No Hex packages are needed.

For use from another Mix project, add `{:clingo_elixir, path: "/path/to/clingo_elixir"}` to its dependencies after bootstrapping. `CLINGO_PREFIX` can select another local installation of **exactly 5.8.2**, with the identical public header and matching upstream patch record. Build such a prefix with `CLINGO_INSTALL_DIR=/path/to/prefix tools/bootstrap.sh`. Changing build flags requires `make clean` before rebuilding. Remove `_native` when switching upstream checkout paths.

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

`mix hex.build` creates a source package; installing it automatically bootstraps the pinned upstream library when no `CLINGO_PREFIX` is supplied. CI covers GCC/Clang, scheduler configurations, allocation probes, packaging and a full upstream sanitizer build. No package is published automatically.

Callback transport accepts at most 4,096 structural steps and nesting depth 32 per native job or reply. Oversized terms fail promptly; array writes inside callbacks are submitted in bounded chunks so they can progress even when every dirty CPU scheduler is waiting on a callback. Deeply nested job arguments and large callback return terms can still exceed this transport limit.

## Livebooks

The [ASP and Elixir course](livebooks/README.md) contains 19 notebooks across five topic folders, bringing worked examples and exercises together. Start with [facts and rules](livebooks/language/01-facts-and-rules.livemd) to learn ASP, or [Getting started](livebooks/elixir/01-getting-started.livemd) for the wrapper API. See the course README for setup and testing.

## License

Licensed under [MIT](LICENSE). Upstream material retains its original copyrights
and licenses, as described in that file.
