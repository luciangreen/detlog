# Detlog architecture (v0.1)

Pipeline:

1. `detlog_reader` reads terms, source module information, and line mappings.
2. `detlog_analysis` computes dependencies, modes, effects, recursion, and cut classes.
3. `detlog_codegen` emits a generated module and records source-map entries.
4. `detlog` loads and executes generated predicates from the REPL.

Safety policy:

- Convert only where current proof heuristics classify a predicate as safe.
- Otherwise generate explicit fallback wrappers and diagnostics.
