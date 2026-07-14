# Detlog Progress

## Completed work

- Implemented REPL interfaces: `detlog/2`, `detlog/3`, `detlog_compile/2`.
- Added option parsing for `code/1`, `trace/1`, `modes/1`, `benchmarks/1`, `fallback/1`.
- Implemented source reading with line tracking and predicate extraction.
- Added compiler pipeline scaffolding: analysis, code generation, diagnostics, source maps, cache hooks.
- Implemented analysis passes for dependency graph, mode/determinism heuristics, effect classification, recursion properties, and cut classification.
- Added runtime helpers for choice packets, splices, loops, decisions, and cut wrappers.
- Added optional adapter stubs for Loop2, PLOP, and Piglog metadata.
- Added tests across unit/integration/equivalence/regression folders.
- Added benchmark runner and README documentation updates.
- Added `pack.pl` and imported `PROGRAM_REQUIREMENTS.md` into this branch.

## Current conservative decisions

- Unsafe or uncertain transformations use explicit predicate-level fallback.
- Conversion currently keeps semantics by delegating generated predicates to source predicates.
- Determinism and mode inference are heuristic and designed to avoid unsafe claims.

## Known limitations and unresolved issues

- Full structural rewrites (deep disjunction lowering, broad cut elimination, DCG transformation, loop fusion) are not yet exhaustive.
- Incremental recompilation currently uses in-memory cache and does not persist between sessions.
- Optional adapters are placeholders pending external dependency integration.
