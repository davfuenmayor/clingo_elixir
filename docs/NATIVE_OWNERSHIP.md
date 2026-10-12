# Native ownership and locking

`c_src/clingo_elixir.c` owns resources, conversion, dispatch and callbacks;
`values.inc` owns scratch symbol/model values and managed cursors. Generated
`api.inc` and `adapters.inc` contain typed ABI calls, not lifetime policy.
Format handwritten C with `clang-format-19 -i c_src/clingo_elixir.c c_src/values.inc c_src/clingo_main.c`.
Do not format the upstream header or generated files by hand.

A Pointer keeps the session resource alive. Its Node is a session-owned identity;
casts and pointer-cell round trips share the canonical identity. Expiry checks
use scope/generation/parent identity; an escaped pointer must remain a safe
expired resource. A Slot records identity for a pointer stored in native memory.
Temporary payloads belong to operation/callback scopes. Retirement frees their
allocated data and owned slots, but escaped pointers retain expired identities.
Pointers count their Node resources. A nonallocating sweep under `Session.nodes`
marks roots (persistent/active Nodes and live Pointer resources), follows canonical
identity/parent/origin and saved-cell edges, then removes unreferenced retired
Nodes from both list and address index. Scope roots include active operations,
context resources and referenced Nodes; ancestry never crosses session ownership.
Scope/Node identity can be reclaimed only after all those references disappear.
Persistent explicit allocations remain session-owned; acquiring an AST promotes
it out of the callback scope before retirement.

A managed scope context is transported with each native/nested job, rather than
stored as mutable session-wide state. Synchronous grounding/queries retire it in
exception-preserving cleanup. A solve Cursor retains its registration scope until
native handle close drains callbacks. Failed initialization and abandoned context
resources retire their scopes; the next managed boundary collects them. Native
retirement sends dispatcher unregister messages using an environment reserved at
scope creation, so allocation failure during cleanup cannot retain Elixir hooks.
Persistent callback bundles and closures remain session/control-lived; scripts
remain global. Callback reply environments are released at callback completion,
even when an escaped Request resource remains in BEAM.

BEAM GC controls release of resource references, including arguments in dispatcher
and callback-supervisor heaps. Retained-byte checks drain workers and collect
those heaps before measuring; fixed-quota operation loops do not force collection.
The sweep only frees memory and sends unregister notifications: it never calls
clingo or waits for native work while holding the nodes mutex.

Managed cursors also capture solve-event failures before returning to clingo:
upstream terminates on a false unsat/statistics/finish callback return. A failed
hook stops continuation but returns success to that upstream callback, stores the
first error atomically in a preallocated 4,096-byte buffer, and reports it at the
next managed handle operation (including close). Close still drains/releases all
resources. Later events are skipped after failure. No heap allocation is needed
to capture the error, including on asynchronous solver threads.

A managed Cursor keeps its session alive. The active cursor list owns another
reference until close. Cancellation increments `users`; close sets `closed`,
drains users, closes the native solve handle and unlinks/releases the list
reference. Cleanup closes cursors, generic solve handles, acquired ASTs, then
controls. Native session destruction queues the heap Session for the dedicated
cleanup worker; it does not run clingo destruction on an ordinary scheduler.

Normal jobs hold `Session.calls`. Short identity/index mutations and every
cursor-list traversal, insertion and unlink hold `Session.nodes`. Callback
threads share these lists even when ordinary calls are serialized. Cursor cleanup
retains the selected resource under `nodes`, then releases that mutex before
closing the native handle; close may invoke a nested finish callback. Control
free's outstanding-handle scan also holds `nodes` so callback sweeping cannot
invalidate its iteration. Session teardown likewise selects and pins one owned
node under `nodes`, then drains it outside the lock. Raw asynchronous handles
can still have callbacks retiring nodes while teardown starts.

Interrupt pins a canonical identity with an atomic user count while close drains.
Cross-process cancellation first interrupts the owning control under that pin,
then drops it before taking `calls`, rechecks validity and drains the handle.
Never retain an interrupt user count while waiting for `calls`: close holds that
mutex while draining users. Serializing handle cancellation also protects model
copying and synchronous yield advancement. Calls that wait for upstream work or
dispatch callbacks must never hold
`nodes`. The shutdown abort path holds it only across the pinned clingo 5.8.2
nonblocking `control_interrupt` operation (signal 65, not the waiting cancel
signal). Nested callback jobs execute on their originating C thread without
reacquiring `Session.calls`.
The Request mutex protects replies/jobs. Callback processing releases it before
executing a nested job because cursor cleanup can invoke another callback.

Script registration takes `Session.calls` before the global `scripts_mutex`.
Finalization publishes its permanent transition and snapshots registrations
under `scripts_mutex`, releases that mutex, then takes session locks. Never wait
for a callback or session lock while holding the registry mutex. Global scripts
pin sessions until VM shutdown; upstream has no unregister operation.

The cleanup queue mutex protects queue state only; the worker releases it before
native destruction. `Scope.active`, object user counts and closed flags are
atomic because callback/interrupt/cleanup threads can observe them concurrently.
Atomics do not replace the ownership and lock ordering above.

Errors are copied immediately into `Clingo.Error`; there is no session error
polling cache. Predicates clear stale thread-local native diagnostics before
calling upstream. Do not add global or process-cached native Symbol sessions.
