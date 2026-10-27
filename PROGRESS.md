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
- Removed operational implementation cuts from converter/runtime modules and replaced them with explicit decision flow.
- Added cut-free repository invariant checker: `detlog_verify_cut_free/0`.
- Refactored cut classification and code generation to use explicit condition/status models.
- Added cut-free regression and runtime determinism-focused tests.
- Propagated unproved determinism and effects through local predicate calls, with multi-level regression tests.
- Added a feature guide with interface/options, component status, runnable tests, and an explicit remaining-work list.

## Current conservative decisions

- Unsafe or uncertain transformations use explicit predicate-level fallback.
- Converted predicates now emit source clause bodies directly when safety conditions are proved; fallback wrappers remain explicit.
- Determinism and mode inference are heuristic and designed to avoid unsafe claims.

## Known limitations and unresolved issues

- Full structural rewrites (deep disjunction lowering, broad cut elimination, DCG transformation, loop fusion) are not yet exhaustive.
- Converted predicates currently emit their original clause bodies; generated deterministic loops, packets, and splice structures are not yet synthesized from general source control flow.
- Mode/determinism/effect analysis remains heuristic around meta-calls, dynamic predicates, modules, and built-ins.
- Incremental recompilation currently uses in-memory cache and does not persist between sessions.
- Optional adapters are placeholders pending external dependency integration.
- Benchmarks are smoke measurements only; source-versus-generated runtime and memory comparisons remain to be implemented.
