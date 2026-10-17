# Pinned upstream fixes

`clingo-5.8.2.patch` applies to upstream commit
`a99ffb2a58293c68b28fcc283a1d1c9ccad900fe` (v5.8.2). The upstream files retain
their original MIT licenses and copyright notices. This is a local
correction maintained by clingo_elixir, not an upstream release or accepted fix.

The release lexer accumulates into signed integers. Parsing `-2147483648`
overflows before unary minus is applied; negating the resulting minimum also
overflows in constant unary evaluation. The patch uses unsigned 32-bit accumulation and unsigned negation,
then converts back to the signed native representation. It preserves clingo's
existing modulo-2^32 literal behavior on our supported GCC/Clang Linux x86_64
platform, including out-of-range text and minimum-number negation/absolute value.
`Symbol.number/1` continues to reject out-of-range Elixir values. This does not
claim to fix arbitrary overflowing arithmetic or variable-pattern matching in
upstream clingo.

Boundary review also found that both octal lexer rules exclude the digit zero.
The patch accepts `0o[0-7]+`; corresponding checked-in generated tables are
updated so builds without re2c have the same behavior.
Bootstrap uses those vendored lexer tables for reproducible release builds.

`tools/bootstrap.sh` verifies the clean pinned checkout, exports it into its own
build directory, applies the patch, and records the exact patch in the installed
prefix. It never changes the original checkout. The bundle builder includes
the same patch record; an explicit `CLINGO_PREFIX` must carry the matching patch
record. Changing the patch invalidates the private source export and requires
rebuilding distributed bundles. Upstream
version upgrades must review/remove this patch and reset the build directories.

`test/integer_literals_test.exs` exercises every radix, both signs, boundaries,
very long literals, malformed input, nested symbols, canonical print/parse,
program grounding, AST output and ASPIF round trips. Run it in the full
upstream/wrapper ASan/UBSan suite; no additional suppression is permitted.
When contributing the fix upstream, include a small `clingo_parse_term` UBSan
reproducer and the octal-zero cases. No upstream issue has been filed here.

Standalone reproduction (substitute the installation under test):

```sh
cc -Ic_src -fsanitize=address,undefined tools/reproduce_integer_literals.c \
  -L_upstream-address-undefined/lib -lclingo \
  -Wl,-rpath,"$PWD/_upstream-address-undefined/lib" -o /tmp/clingo-integer
ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS="halt_on_error=1:suppressions=$PWD/tools/ubsan.supp" \
  /tmp/clingo-integer -2147483648
```

The unpatched release reports signed overflow at `lexerstate.hh:304`. The patched
build returns `-2147483648`. Repeat with `-0o20000000000`, `0x80000000`,
`0x100000000` and `--2147483648` to cover the adjacent paths.

## Parallel-control preprocessing

TSan found concurrent writes to the global `Clasp::Asp::trueAtom_g` sentinel
when independent controls prepare their programs. Preprocessing calls
`clearSupports`, `clearLiteral`, `markRemoved` and `setInUpper` on this object.
The patch makes it a `LogicProgram` member, initialized with the same equivalent
atom-zero state. It follows the program across native threads; thread-local
storage would be incorrect because controls migrate between dirty schedulers.
Each program skips its own sentinel during atom deletion, and ordinary member
destruction releases the sentinel. No global solve lock or suppression is added.

`tools/reproduce_parallel_controls.c` reproduces the race with two ordinary C
controls, outside BEAM. Build it against the TSan installation:

```sh
cc -D_XOPEN_SOURCE=700 -g -O1 -fsanitize=thread -Ic_src \
  tools/reproduce_parallel_controls.c -L_upstream-thread/lib -lclingo -pthread \
  -Wl,-rpath,"$PWD/_upstream-thread/lib" -o /tmp/clingo-parallel-controls
TSAN_OPTIONS=halt_on_error=1 /tmp/clingo-parallel-controls
```

The previous literal-only patch produces a `trueAtom_g` race; the corrected
build must print `PARALLEL_CONTROLS_PASS`. No upstream issue or PR is submitted
automatically. The one installed `upstream.patch` record covers all fixes.

### Default solver configuration

TSan also found that `SharedContext::setConfiguration(nullptr)` prepares a
process-global `BasicSatConfig`, mutating its solver/search parameters from
independent controls. The patch makes the default configuration a member of
`SharedContext`. The existing non-owning `config_` reference points at that
member; explicitly supplied configurations retain their existing ownership.
Reset/destruction follow the context lifetime. This avoids a global preparation
lock and preserves independent solving. The same parallel-control regression
covers this path; run the complete TSan suite as well as the standalone probe.

### Asynchronous interrupt flag

Sequential solving previously used a `volatile int` for the flag written by
`clingo_control_interrupt` and read by the solver thread's `InterruptHandler`.
Volatile does not provide thread synchronization; TSan detected this during
owner-death cleanup. The patch uses Clasp's existing `Atomic_t<int>::type` for
the flag and handler pointer, preserving the interrupt states and operations.
The threaded build uses native atomic operations; the existing single-thread
abstraction remains available. Owner-death and cancel/close tests exercise it.

### Solve-strategy publication versus interrupt

TSan caught `clingo_control_interrupt` reading `SolveData.active` while a solve
publishes a new strategy. A per-`SolveData` mutex now protects publication,
removal and the nonblocking interrupt's access to that strategy. Reset removes
its pointer under the lock, then cancels/releases outside it. Ordinary shutdown
also unlocks before its waiting cancellation; ordinary operations remain caller
serialized, as required by clingo. Strategy startup runs outside the lock so
solver callbacks can deliver pending interrupts. The lock is per control, not
process-wide, and introduces no public C ABI change.

### Statistics registration

The statistics type registry lazily adds vtables to a global vector while other
controls can query it. Registration and lookup now share a narrow mutex. The
lookup returns an immutable process-lived vtable and releases the lock before
calling it, so recursive statistics access cannot hold that mutex. Solver work
remains independent across controls; this lock only protects registry access.

Cross-process cancellation belongs to the wrapper: it first signals through
`clingo_control_interrupt`, then drains the handle through the session's normal
call mutex. The public C cancellation method is not assumed to be safe alongside
synchronous model retrieval or model copying. No upstream synchronous-wait patch
is needed. The callback regression verifies that cancellation drains active search.

### MinGW cross-build header spelling

The private patch uses `<windows.h>` instead of `<Windows.h>` in Gringo's
shared mutex header. The lowercase spelling supports MinGW cross-compilation
on case-sensitive Linux filesystems and preserves native Windows semantics.
