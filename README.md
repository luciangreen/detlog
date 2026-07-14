# detlog

Detlog is an in-SWI-Prolog source converter for examining and reducing hidden nondeterminism while preserving ordinary Prolog semantics. It attempts to replace choicepoints with the splice predicate to combine outputs of nondeterministic predicates and convert cut into predicates.

## Showcase

From the repository root, these commands demonstrate the main workflows:

### Run a query through Detlog

```bash
swipl -q -g "use_module(prolog/detlog), once(detlog('test/fixtures/sample_program.pl', det_sum([1,2,3], S), [fallback(silent)])), format('S=~w~n', [S]), halt."
```

### Generate wrapper code for a source file

```bash
swipl -q -g "use_module(prolog/detlog), detlog_compile('test/fixtures/sample_program.pl', [code('generated.pl'), fallback(silent)]), halt."
sed -n '1,7p' generated.pl
```

### Print inferred modes and determinism

```bash
swipl -q -g "use_module(prolog/detlog), detlog_compile('test/fixtures/sample_program.pl', [modes(true), fallback(silent)]), halt."
```

### Inspect fallback diagnostics for predicates Detlog keeps conservative

```bash
swipl -q -g "use_module(prolog/detlog), use_module(prolog/detlog_diagnostics), detlog_compile('test/fixtures/sample_program.pl', [fallback(silent)]), diagnostics(Ds), writeln(Ds), halt."
```

### Run the bundled benchmark scenarios

```bash
swipl -q -s benchmark/run_benchmarks.pl
```

## REPL-first workflow

```prolog
?- [prolog/detlog].
?- detlog('test/fixtures/sample_program.pl', det_sum([1,2,3], S)).
```

Use options with `detlog/3`:

```prolog
?- detlog('test/fixtures/sample_program.pl', det_sum([1,2,3], S), [code(true)]).
?- detlog('test/fixtures/sample_program.pl', det_sum([1,2,3], S), [code('generated.pl')]).
?- detlog('test/fixtures/sample_program.pl', det_sum([1,2,3], S), [trace(true), modes(true)]).
```

Compile without executing a query:

```prolog
?- detlog_compile('test/fixtures/sample_program.pl', [code(true)]).
```

## Source Prolog vs converted Detlog vs fallback

- **Source Prolog** is the original program you provide.
- **Converted Detlog** is generated code where static analysis classifies a predicate as currently safe to convert.
- **Fallback predicate** is explicitly generated when conversion safety is not proved; it delegates to the original predicate and is reported through diagnostics.

This implementation prioritizes semantic safety: unsupported or uncertain constructs are handled by visible fallback.

## Implemented runtime building blocks

- Choice packets: `cp/1`, `member_cp/2`, nested packet normalisation.
- Splice helpers: `splice/2`, `splice_collect/2`, `splice_each/2`, `splice_first/2`, `splice_select/3`.
- Loop adapters: wrappers for `member/2`, `between/3`, `findall/3`, `bagof/3`, `setof/3`.
- Decision and cut helpers: `guard/1`, `decision/2`, `if_commit/3`, `first/2`, `once_det/1`, `loop_exit/1`.

## Diagnostics and source mapping

Detlog records:

- source file/module/predicate;
- source line;
- generated predicate;
- conversion status (`converted` or `fallback`).

Fallback diagnostics are available in `detlog_diagnostics:diagnostics/1`.

## Optional adapters

Loop2, PLOP, and Piglog adapters are provided as stubs in `prolog/adapters/` and are optional.

## Tests

Run all tests:

```bash
swipl -q -s test/run_tests.pl -g run_tests -t halt
```

## Benchmarks

Run benchmark scenarios:

```bash
swipl -q -s benchmark/run_benchmarks.pl
```

## Limitations

- Advanced whole-program rewrites are intentionally conservative.
- Unsupported attributed-variable and unsafe-cut cases remain in fallback.
- Incremental caching is currently in-memory (session-local).
