# Multiplatform builds and tests

The package installs a matching, checksum-verified clingo 5.8.2 runtime and NIF
without downloading upstream source or invoking a compiler. Requires 64-bit
Elixir 1.20.x and OTP 29+. Bundles include the pinned upstream fixes. Python
and Lua integrations are disabled; Elixir callbacks remain available.

## Platform status

This table records work in this workspace; a cross-build is not a native test.
Results below were recorded on 2026-10-17.

| Target | Bundle and validation |
| --- | --- |
| `linux-x86_64` | Debian 13, Elixir 1.20.4 / OTP 29: **162 checks passed**, including all 249 retained C operations; all **19 notebook cell checks and 19 actual Livebook runtime evaluations passed**. Compiler-free Hex installation and minimal-runtime chroot passed. |
| `linux-aarch64` | Cross-built; actual ARM64 OTP 29.1.1 / Elixir 1.20.4 under QEMU passed NIF smoke checks for solving, callbacks, integer boundaries, ASTs, model streams, ASPIF export/round-trip, and cleanup. CLI smoke check enumerated both expected models. Full suite/native hardware pending. |
| `windows-x86_64` | Windows OTP 29.1.1 / Elixir 1.20.4 under Wine 10: **161 checks passed, one Linux-only probe skipped**, including all 249 retained C operations; all **19 notebook cell checks passed**. Native Windows/MSYS2 validation pending. |
| `macos-x86_64` | Native build path prepared; no archive or macOS runner available. |
| `macos-aarch64` | Native build path prepared; no archive or macOS runner available. |

Linux bundles target glibc 2.38+; builds currently use Debian 13 / GCC 14 and
static GCC/C++ runtimes. This is a newer baseline than swi_elixir's glibc 2.31
bundle. Oldest-glibc runtime validation remains pending. Windows 10+ and macOS
12+ are intended baselines, subject to native validation. Alpine/musl, 32-bit
BEAM, Windows ARM64, and native hot upgrades are excluded. Match the running
BEAM's CPU, including under emulation. macOS cannot yet be advertised as
working out of the box: its archives must be built and tested on Macs.

## Build a complete bundle

From the project checkout:

```sh
tools/build-runtime.sh
mix clean
mix test
elixir tools/check_livebooks.exs
```

| Host | Prerequisites |
| --- | --- |
| Linux | GCC/G++, make, CMake, Ninja, binutils, patchelf, git, curl, tar, Elixir/OTP. |
| macOS | Xcode Command Line Tools, `brew install cmake ninja`, git, curl, make, Elixir/OTP. Use the target CPU natively; this path is unverified. |
| Windows | MSYS2 **MINGW64** Bash, POSIX MinGW-w64 GCC/G++, binutils, make, CMake, Ninja, git, curl, tar, and Windows Elixir/OTP on `PATH`. Native MSYS2 builds still need validation. |

The builder pins upstream v5.8.2, exports and patches a private source copy,
checks the vendored C header, and compiles the library, NIF, and CLI driver.
It downloads checksum-verified OTP 29.0 headers. Upstream files and build caches
live under `${XDG_CACHE_HOME:-$HOME/.cache}/clingo-elixir`, outside the repo.
An existing clean checkout can be selected with `CLINGO_SOURCE`.

Outputs are `native/clingo-5.8.2-<target>.tar.gz` and `.sha256`. Archives contain
one `clingo/` directory with native binaries, the header, target metadata,
upstream patch record, and licenses. Linux uses `$ORIGIN`; macOS rewrites
Mach-O dependencies and signs binaries after stripping; Windows keeps its DLL
beside the NIF/driver. Required notices, including static runtime terms, are in
[native/licenses](native/licenses).

Optional settings:

- `CLINGO_BUILD_ROOT=/absolute/path`: persistent cache for this target.
- `CLINGO_TARGET`: one of the target names above; defaults to the host.
- `BUILD_JOBS=4`: compilation parallelism.
- `CLINGO_BUILD_SYSROOT=/absolute/path`: compatible Linux development sysroot.
- `CFLAGS='-O3 -march=native'` on Intel/AMD or `CFLAGS='-O3 -mcpu=native'` on Apple Silicon: optional CPU tuning. Keep tuned archives on matching CPUs and measure improvements.

### Cross-builds from Linux x86-64

```sh
CLINGO_TARGET=linux-aarch64 tools/build-runtime.sh
CLINGO_TARGET=windows-x86_64 tools/build-runtime.sh
```

ARM64 needs `gcc-aarch64-linux-gnu`, `g++-aarch64-linux-gnu`, and binutils.
Windows needs the POSIX MinGW-w64 GCC/G++ toolchain and windres. Testing needs
QEMU or a target machine for ARM64, and Wine or Windows for Windows x64.
The workspace `Containerfile` installs these tools. macOS requires actual
Intel/Apple Silicon runners; this Linux container does not provide an Apple SDK.

## Bring your own binaries

Set `CLINGO_ELIXIR_BUNDLE` to a complete archive's absolute native path before
compiling or starting Livebook; keep its `.sha256` beside it. For example:

```sh
export CLINGO_ELIXIR_BUNDLE=/absolute/bundles/clingo-5.8.2-macos-aarch64.tar.gz
mix clean
mix test
```

Windows PowerShell:

```powershell
$env:CLINGO_ELIXIR_BUNDLE = 'C:\bundles\clingo-5.8.2-windows-x86_64.tar.gz'
mix clean
mix test
```

Target/checksum checks still apply. Restart the BEAM/Livebook runtime after
changing native binaries. Local builds allow CPU tuning and testing against
your actual OS; performance/reliability improvements are not automatic.

`CLINGO_PREFIX` remains the explicit source-development path. Install the
patched library using `CLINGO_INSTALL_DIR=/absolute/prefix tools/bootstrap.sh`,
then compile with `CLINGO_PREFIX=/absolute/prefix mix compile`. This path needs
a compiler and make, verifies the exact header and patch record, and bypasses
the prebuilt bundle. Use it for sanitizer and allocation-injection builds.

## Test procedure

Run `CLINGO_RETAINED_COVERAGE=1 mix test`, then
`elixir tools/check_livebooks.exs` on each target. The full suite checks solving,
model streams, integer boundaries, ASTs, observers/propagators, Elixir callbacks,
script lifecycle, cancellation, owner death, and cleanup. Coverage requires all
249 retained C operations to run. The Linux `LD_PRELOAD` pin probe is skipped
elsewhere: it depends on ELF symbol interposition, not portable clingo behavior.
Fresh child-VM tests use an explicit OS-process deadline on every target.

`test/runtime_test.exs` relocates a complete application to a path containing
spaces and exercises solving, callbacks, streams, integer boundaries, and CLI
loading. `python3 tools/check_package.py` builds the actual Hex archive, installs
it with compilers absent from `PATH`, relocates it, then tests inside a minimal
Linux chroot without build tools. It requires root for the chroot portion.
Also reject corrupted and wrong-target bundles before release, inspect native
dependencies, and check the final archive's size against the package host limit.

The cell checker evaluates all 19 lessons twice in one VM and includes the
non-executable launch guide in its inventory. Actual Livebook runtime evaluation
is a separate check; see [livebooks/VALIDATION.md](livebooks/VALIDATION.md).
Repeat compiler-free package and Livebook checks for every final target bundle.
Run minimum/current OTP and oldest advertised OS versions on native runners;
passing under emulation does not establish full native platform support.

### Emulation used in this workspace

Windows checks use the official Windows OTP 29.1.1 ZIP and portable Elixir
1.20.4 BEAM files, with a separate project copy and `PATH` restricted to
Windows Erlang and system tools. No clingo installation, compiler, or make
is available on that path. Wine executes the actual Windows NIF and DLL.

ARM checks use QEMU user emulation with Debian ARM64 OTP 29.1.1 and its runtime
libraries in an isolated directory. The ARM64 `beam.smp` loads the ARM64 NIF
and clingo library. Since this container has no binfmt registration, the
`erl_child_setup` and `inet_gethost` helpers use matching host executables;
this validates the ARM BEAM/NIF path, not a complete ARM operating system.
Full-system QEMU or native ARM hardware is still needed for the complete suite.

All emulation images, downloads, and detailed logs remain in the container
cache at `/root/.cache/clingo-elixir`, outside the repository. Only distributable
archives/checksums, source inputs, tests, and these instructions are kept here.

## Remaining release checks

- Build and validate both missing macOS archives on matching Mac runners.
- Complete the ARM64 suite on native hardware or a full-system VM; smoke checks already exercise the actual ARM64 BEAM/NIF.
- Repeat Windows/Wine coverage on actual Windows 10+ and validate native MSYS2 building.
- Validate the oldest advertised Linux/macOS/Windows baselines and OTP versions.
- Repeat actual Livebook runtime checks on the final archives for every target.
- Recheck package size and notices once both macOS archives are included.

The current three-bundle Hex archive is about 6.5 MiB. Generation determinism,
AST metadata comparison, intentional loader-drift rejection, corrupted archive
rejection, wrong-target rejection, and missing-file restoration also passed.
