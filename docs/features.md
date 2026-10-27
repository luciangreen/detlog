# Detlog feature guide

Detlog is an SWI-Prolog source reader, conservative analyzer, and REPL-facing
converter. Its current safety rule is to emit a predicate's source clauses
only when the analysis proves the predicate deterministic, pure, and free of
unsupported cuts or uncertain recursion. Other predicates get explicit
fallback wrappers that call the source module; fallback is not a conversion.

## User-facing interfaces

Load the entry module and execute a query:

```prolog
?- [prolog/detlog].
?- detlog('test/fixtures/sample_program.pl', det_sum([1,2,3], Sum)).
```

`detlog/3` accepts these options:

| Option | Default | Behavior |
|---|---:|---|
| `code(false)` | yes | Do not display or write generated source. |
| `code(true)` | no | Display generated source before execution. |
| `code(File)` | no | Write generated source to `File`; the input is not overwritten automatically. |
| `trace(true)` | no | Print a predicate-level analysis and conversion summary. |
| `modes(true)` | no | Print heuristic argument-mode and determinism information. |
| `benchmarks(true)` | no | Print a basic elapsed-runtime measurement. This is not a source-versus-converted performance comparison. |
| `fallback(warn)` | yes | Emit a warning for each fallback predicate. `silent` suppresses warnings; `error` raises on fallback. |

For example:

```prolog
?- detlog('test/fixtures/sample_program.pl',
          det_sum([1,2,3], Sum),
          [code('generated.pl'), trace(true), modes(true), fallback(silent)]).
```

Compile without running a query with `detlog_compile/2`:

```prolog
?- detlog_compile('test/fixtures/sample_program.pl', [code(true)]).
```

## Implemented components

| Component | Current behavior |
|---|---|
| Source reader | Reads ordinary SWI-Prolog terms and records line numbers, source module, clauses, and predicate signatures. |
| Analysis | Builds a local dependency graph; estimates argument modes and determinism; classifies direct effects, recursion, and cuts. Locally called predicates propagate unproved determinism and effects transitively, so callers conservatively fall back too. |
| Code generation | Creates and loads a generated module, emits source clauses for predicates classified safe, and emits explicit wrappers for predicates requiring fallback. |
| Diagnostics and source maps | Records fallback reasons and source-to-generated predicate metadata for the current compilation; query them with `detlog_diagnostics:diagnostics/1` and `detlog_source_map:source_map/1` or `/2`. |
| Session cache | Caches generated modules in memory using source content and fallback policy as part of the key; it does not persist between SWI-Prolog sessions. |
| Choice helpers | `cp/1`, `normalize_cp/2`, `member_cp/2`, and packet validation helpers provide nested packet representation and flattening. |
| Splice helpers | `splice/2`, `splice_collect/2`, `splice_each/2`, `splice_first/2`, `splice_select/3`, and `splice_estimated_size/2` provide eager Cartesian-product and row-selection helpers. |
| Runtime control helpers | `guard/1`, `decision/2`, `call_indexed_goal/2`, `if_commit/3`, `first/2`, `once_det/1`, `loop_exit/1`, `cut_free_mode/1`, and `detlog_commitment_audit/1` are explicit control/runtime utilities. |
| Loop adapters | `loop_member/2`, `loop_between/3`, `loop_findall/3`, `loop_bagof/3`, and `loop_setof/3` delegate to the corresponding SWI-Prolog operations. They are helpers, not source-to-source loop transformations. |
| Cut-free checker | `detlog_verify_cut_free/0` scans implementation modules for operational cut syntax. It does not prohibit cuts in user source or fallback predicates. |
| Optional adapters | Loop2 and PLOP availability modules are stubs; Piglog currently exposes only placeholder metadata. No external integration is performed. |

The generated predicate body is not yet a general deterministic rewrite: safe
predicates currently retain their source clause bodies. The analysis is
heuristic and does not prove arbitrary Prolog programs correct. Treat output
as an experimental conversion and inspect fallback diagnostics and generated
code for the program being tested.

## Tests and checks

Install SWI-Prolog 9.0 or later, then run these commands from the repository
root:

```sh
# Complete PL-Unit suite
swipl -q -s test/run_tests.pl -g run_tests -t halt

# Focused analysis tests, including transitive safety propagation
swipl -q -s test/run_tests.pl -g "run_tests(detlog_analysis)" -t halt

# Cut-free implementation invariant
swipl -q -s test/test_cut_free_implementation.pl -g run_tests -t halt

# Benchmark smoke run (illustrative only; not a comparative benchmark)
swipl -q -s benchmark/run_benchmarks.pl
```

The full suite covers choice packets, splice helpers, analysis, converter
status and cut classification, REPL execution and code output, answer-order
equivalence for selected predicates, fallback visibility, and the cut-free
implementation invariant. The current benchmark runner reports elapsed
runtime and answer counts for fixture queries; it does not compare source and
converted execution or measure memory.

## Remaining work

The highest-priority implementation gaps are:

- Structural deterministic rewrites: disjunction lowering, clause factoring,
  safe cut elimination, and loop/choice-packet generation are not exhaustive.
- More reliable whole-program mode, determinism, and effect analysis,
  especially around meta-calls, dynamic predicates, modules, and built-ins.
- Recursive DCG transformation and tail-recursion conversion.
- Persistent incremental recompilation and precise per-clause source maps.
- Comparative runtime and memory benchmarks with representative workloads.
- Real external Loop2/PLOP integration. Piglog parallelisation is out of
  scope for the current version.

Unsupported or unproved cases should remain on fallback until these features
have dedicated transformations and semantic-equivalence tests.
