# Detlog architecture (v0.1)

Pipeline:

1. `detlog_reader` reads terms, source module information, and line mappings.
2. `detlog_analysis` computes dependencies, modes, effects, recursion, and cut classes.
3. `detlog_codegen` emits a generated module and records source-map entries.
4. `detlog` loads and executes generated predicates from the REPL.
5. `detlog_verify` enforces repository-wide operational cut-free implementation checks.

Safety policy:

- Convert only where current proof heuristics classify a predicate as safe.
- Otherwise generate explicit fallback wrappers and diagnostics.
- Ordered control selection uses `decision/2`; explicit alternative combination uses splice operations.
- Source programs may contain cut, but Detlog implementation and converted output do not operationally invoke cut.
