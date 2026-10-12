# Internal C adaptation (contributors)

This is an implementation reference, not the supported product API. Start with
[ELIXIR_API.md](ELIXIR_API.md) for public capabilities. The selected operation inventory is in [COVERAGE.md](COVERAGE.md). The [pinned public header](../c_src/clingo.h) defines signatures, parameters and state/lifetime contracts; use those contracts with the conversions below.

| C declaration/concept | Elixir representation |
|---|---|
| `clingo_x(a, b)` | `Clingo.Internal.API.x(session, a, b)` |
| Integer, enum, bitset, symbol, signature, iterator | Elixir integer; widths/ranges are checked |
| `bool` | `true` / `false` |
| `double` | Float, or an integer converted to double |
| `void` result | `:ok` |
| `NULL` | `nil` |
| Input C string | NUL-free Elixir binary, copied into the current operation/callback scope (session arena for explicit internal calls) |
| Returned C string | Elixir binary, or `nil` |
| Struct input | Map using C field names; optional callback/pointer fields default to `nil`; part parameter counts are derived |
| Input array | Elixir list; count is derived |
| Output scalar `T*` | Returned as `{native_result, value}` |
| Output object `T**` | Returned opaque native resource |
| Output array pointer `T const**` | Returned list; associated output count is omitted |
| Caller-allocated output array | Capacity queried internally; returned list |
| String output buffer | Capacity queried internally; returned binary |
| Function pointer input | Elixir function matching the C callback arity |
| Callback pointer supplied by clingo | Opaque resource; call with `Clingo.call_pointer(session, pointer, args)` |
| Error code/message | `Clingo.Error` with `code` and `message`; diagnostics are copied at failure; session error polling is not exposed |
| Named enum constant | `Clingo.constant(:clingo_...)` |
| Version macros | `Clingo.version/0`, `Clingo.constant(:CLINGO_VERSION)` and the three numeric version constants |
| Type/struct layout | `Clingo.type("clingo_part_t")` returns `{size, kind, fields}`; each field maps to `{type_name, offset}` |
| AST exported variables | `Clingo.global(session, :g_clingo_ast_constructors)` / `:g_clingo_ast_attribute_names`; read as structs |

NIF resources never expose integer memory addresses. Type names accept atoms or strings and insignificant whitespace. Const qualification is erased for ABI matching; upstream mutability contracts still apply. All ABI layout and integer sizes come from the native compiler.

Literal C boundary tests use `tools/raw_probe.exs`; there is no shipped Raw facade. `Clingo.alloc/read/write/cast`, metadata globals and received function pointers are private ABI implementation tools. Ordinary `Clingo.Internal.API` calls need no output cells. Calls with multiple outputs return `{native_result, output_tuple}`; calls without outputs return the native result.

Boolean return values are preserved. A failing native operation with an error code raises `Clingo.Error`. Predicates that legitimately return false do not raise, and a successful operation can write `false` to an output cell (for example a propagation result). These cases remain distinct. `solve_handle_get` returns its original bitset through the output cell: satisfiable `1`, unsatisfiable `2`, exhausted `4`, interrupted `8`. Zero represents no conclusive result. Exhaustion, model availability and `model_optimality_proven` must be inspected separately.

## Callback interfaces

Logger, grounding, solve-event, AST parsing/unpooling, symbol injection, propagator, observer, application, option-parser and script callbacks all use the same mechanism. Named callback typedefs are accepted directly. Pass callback functions directly in observer, propagator, application and script maps; the binding derives their native types. Optional pointer/callback fields default to `nil`. Callback arguments retain C arity and opaque callback payloads retain upstream contracts; typed payload casts and writes to callback output pointers use the advanced ABI helpers below.

Callback arity matches the C declaration, including user data, output arguments and callback-provided function pointers. Return a boolean for a boolean callback, `:ok` for void, an integer for an integer callback, or a binary for a string-returning callback. Registration checks the function arity. Callback exceptions become native errors with formatted Elixir stack context; an existing `Clingo.Error` preserves its native code. A killed callback worker becomes an error through its process monitor. Managed solve cursors capture event failures and relay them at a handle boundary, because returning false from unsat/statistics/finish callbacks aborts upstream; literal internal C calls retain their native contracts. Void callback exceptions are logged by the dispatcher. Void callbacks, including loggers and undo hooks, cannot signal native failure by a return value; obey the upstream restrictions on these callbacks.

Pointers supplied by a callback have that callback's lifetime and can be used through its originating callback request or a nested descendant request. Copy values or call `ast_acquire` while the callback is running if they must survive. Saving a borrowed pointer into an ordinary cell does not extend its lifetime. All nested calls must target the same session. Native operations and memory reads/writes inside callbacks are queued back to the originating C thread. Creating another callback inside a callback is supported. Closing/finalizing a session from inside a callback is rejected because it would destroy the active native call. Ordinary operations wait in the Elixir session queue before entering a dirty NIF; a callback must not wait for another process to complete an ordinary operation in that same session.

Const qualifiers from function declarations, callback signatures and struct fields are recorded separately from ABI types. Read-only borrowed buffers reject `Clingo.write/4`, including through cast views, and reject native operations requiring writable storage. Pointer cells retain the target resource generation; expired contents raise `ArgumentError` when read rather than being reinterpreted as a fresh native object.

Solve-event `event` is a `void*`. For model events, cast its pointee to `"clingo_model_t"`; for finish events use `"clingo_solve_result_bitset_t"`; for statistics events use an array of two `"clingo_statistics_t*"` entries. For unsat events follow the header's optimization-bound payload contract. Always write `goon` according to the C callback contract. See [callback tests](../test/callback_test.exs) and [statistics tests](../test/inspection_test.exs) for executable unit-test usage.

## Variadic AST construction

`Clingo.AST.new!/3` and the named AST constructors build nodes from attribute
maps. Their finite constructor metadata is pinned in `tools/ast_constructors.json`
and verified against the native library at load. Construction lives in the AST
module; the generic Binding layer has no AST-specific branch or runtime metadata
walk. Locations and child/string arrays use the existing native array converter.

Internally, `Clingo.call(session, :clingo_ast_build, [type, output], varargs)`
receives typed `{C_type, value}` pairs. Number attributes use promoted `"int"`,
symbols `"clingo_symbol_t"`, locations `"clingo_location_t*"`, strings `"char*"`,
children `"clingo_ast_t*"`, and arrays `"char**"` / `"clingo_ast_t**"` followed by
`{"size_t", count}`. Native validation checks the constructor signature.

## Upstream modules

| Public module | Official reference | Behavioral tests |
|---|---|---|
| Basic types/errors/version | [BasicTypes](https://potassco.org/clingo/c-api/5.8/group__BasicTypes.html) | symbol, lifecycle, inventory |
| Symbols/signatures | [Symbols](https://potassco.org/clingo/c-api/5.8/group__Symbols.html) | symbol |
| Symbolic atoms | [SymbolicAtoms](https://potassco.org/clingo/c-api/5.8/group__SymbolicAtoms.html) | inspection, solve, callback |
| Theory atoms | [TheoryAtoms](https://potassco.org/clingo/c-api/5.8/group__TheoryAtoms.html) | backend |
| Assignment/propagation | [Propagator](https://potassco.org/clingo/c-api/5.8/group__Propagator.html) | callback, propagation |
| Backend directives | [ProgramBuilder](https://potassco.org/clingo/c-api/5.8/group__ProgramBuilder.html) | backend, observer |
| Configuration | [Configuration](https://potassco.org/clingo/c-api/5.8/group__Configuration.html) | inspection |
| Statistics | [Statistics](https://potassco.org/clingo/c-api/5.8/group__Statistics.html) | inspection |
| Models/solve control | [Model](https://potassco.org/clingo/c-api/5.8/group__Model.html) | solve, callback, propagation |
| Solve handles | [SolveHandle](https://potassco.org/clingo/c-api/5.8/group__SolveHandle.html) | solve, lifecycle |
| Observer callbacks | [ProgramInspection](https://potassco.org/clingo/c-api/5.8/group__ProgramInspection.html) | observer |
| Controls/multi-shot | [Control](https://potassco.org/clingo/c-api/5.8/group__Control.html) | solve, lifecycle |
| AST/program builder | [AST](https://potassco.org/clingo/c-api/5.8/group__AST.html) | AST |
| Applications/options/scripts | [ExtendingClingo](https://potassco.org/clingo/c-api/5.8/group__ExtendingClingo.html) | application |

The 5.8 documentation and examples were reviewed for semantics; declarations are matched to the 5.8.2 header rather than to its 5.8.0 version macros. Python/C++ convenience APIs and private clingo implementation types are outside this library's scope. The experimental `control_clasp_facade` export is excluded: it is an unstable C++ implementation pointer, not a supported Elixir capability.

## Small helpers and admission limits

`Clingo.output(session, :clingo_symbol_number, [symbol], "int")` returns `{true, number}`. Pass a list of output types to receive a tuple of values. It appends outputs in C argument order; calls with interleaved output arguments still use explicit cells.

`array/3`, `read_array/3` and `write_array/4` process whole arrays in one call. Bulk writes validate bounds before writing but may write a prefix before a bad element fails. `open/1` accepts `max_arena` (256 MiB), `max_queue` (1,024) and `max_callbacks` (1,024). Queue exhaustion raises an argument error with `:busy`; callback admission exhaustion becomes a native error. `memory/1` returns `{reserved_bytes, limit}` for wrapper arena allocations. External libraries and process-global registry storage are outside this quota.
