# Validation

The supported target is Linux x86_64 with glibc, Elixir 1.20.x, OTP 29.x and
pinned, patched clingo 5.8.2. Release checks run on Debian 13 / glibc 2.41,
Elixir 1.20.4, OTP 29 and GCC 14.2. Other platforms and optional Python/Lua
builds are unvalidated.

## Reproduce checks

Run native rebuild checks sequentially: allocation and sanitizer tools temporarily
replace the delivery library and restore the normal build afterward.

```sh
CLINGO_RETAINED_COVERAGE=1 mix test
mix format --check-formatted
python3 tools/check_generation.py
python3 tools/check_allocations.py
./tools/check_sanitizers.sh
CLINGO_SANITIZERS=thread ./tools/check_sanitizers.sh
python3 tools/check_package.py
mix run tools/benchmark.exs _build/validation/benchmark.json
elixir tools/check_livebooks.exs
python3 tools/check_livebooks_runtime.py
```

Reports are generated under `_build/validation/`, rather than committed or shipped.
The package checker retains its accepted archive at `_release/clingo_elixir.tar`
and records its checksum in `_build/validation/package.json`. It requires root
for its isolated minimal-runtime check and never publishes a package.
The Livebook launcher requires Livebook 0.19.9; see [setup](../livebooks/README.md).

## Scope

The suite exercises all 249 retained native operations. Coverage means an entry
point ran; it does not prove every argument combination or native state safe.
Tests cover copied symbols/models/results, incremental solving, streams, backend
construction, ASTs, configuration/statistics, inspection, callbacks and specialized
applications/scripts. Lifecycle regressions cover owner death, callback failures,
expired aliases, cancellation, abandoned solve opens and bounded transient storage.
See the [operation inventory](COVERAGE.md) and [ownership rules](NATIVE_OWNERSHIP.md).

Generation runs twice and compares outputs, checks exported AST tables, then
requires the VM to reject an isolated NIF with deliberately mismatched metadata.
Allocation probes inject wrapper heap, ERTS environment/resource and upstream
construction failures in separate VMs, checking failure propagation and recovery.
These are bounded probes, not exhaustive allocation-failure coverage.

Package acceptance builds the actual Hex source archive, compiles it through a
clean upstream bootstrap, relocates the application and exercises native solving,
parallel controls, integer boundaries, grounding callbacks, ASTs, ASPIF/reification,
DIMACS and application output. The minimal runtime has no libffi, Mix, compiler,
CMake or Python. Build tools are required only when compiling the source package.

The 19 Livebooks span five topics with 390 executable cells and 60 linked assets.
Native tests check lesson claims, model sets and links. Separate tools evaluate
cells and import/evaluate fresh real Livebook sessions. Their reports record
content fingerprints, versions and full versus subset coverage. See
[Livebook validation](../livebooks/VALIDATION.md). No notebook invokes a CLI or shell.

## Sanitizer limits

The sanitizer script instruments both the wrapper and upstream clingo. BEAM
itself is uninstrumented. ASan leak detection and signal interception are disabled
for runtime compatibility. UBSan retains three narrow upstream rules in
`tools/ubsan.supp`:

- `vptr:clingocontrol.cc`: the base constructor accesses `clasp_` before its construction.
- `vptr:control.cc`: opaque C handles use casts to derived marker types.
- `nonnull-attribute:pod_vector.h`: an empty POD-vector copy passes a null
  destination to zero-length `memcpy`.

All other checks remain enabled. A passing suppressed run is not an unsuppressed
upstream result. The pinned [upstream patch](../tools/patches/README.md) corrects
integer-literal and concurrency defects independently of these rules.

The launcher preloads TSan into BEAM through the Linux loader, leaving shell
launchers and build tools uninstrumented. It sets `ignore_noninstrumented_modules=1` and
`detect_deadlocks=0`, excludes uninstrumented BEAM accesses and models VM resource
ownership transfers with test-only annotations. It checks a deliberately racy NIF
before running the suite. There is no wrapper/clingo race suppression; a passing
run is not a BEAM race check, deadlock proof or external peer review. The
[ownership guide](NATIVE_OWNERSHIP.md) records locking and teardown invariants.

Benchmark arena measurements follow caller/dispatcher/callback-supervisor garbage
collection. They exclude upstream solver allocations, BEAM heaps, scratch buffers
and total RSS. Fixed-quota tests also repeat operations without forced collection.
