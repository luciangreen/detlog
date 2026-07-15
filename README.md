# detlog

Detlog is an in-SWI-Prolog source converter for examining and reducing hidden nondeterminism while preserving ordinary Prolog semantics.

Detlog appears to aim to:

1. Replace backtracking choicepoints with deterministic execution where possible.
    * Instead of repeatedly exploring alternatives through Prolog’s choicepoint mechanism, Detlog collects or computes the required alternatives deterministically.
2. Use a splice-style operation to combine outputs of nondeterministic predicates.
    * Rather than repeatedly calling predicates through backtracking, the idea is to materialise or combine their outputs once and then iterate over the combined result deterministically.
    * For example, instead of

a(X),
b(Y),
c(X,Y).

relying on nested choicepoints, Detlog can conceptually produce the outputs of a/1 and b/1, splice them into deterministic structures, and continue from there.
3. Convert many uses of cut (!) into deterministic predicates or control structures.
    * The intention is not merely to remove !, but to replace its operational effect with explicit deterministic logic.
    * Typical cases include:
        * if-then-else
        * deterministic comparison predicates
        * loop termination predicates
        * explicit branch-selection predicates
    * This makes control flow more declarative and easier for a compiler to analyse.

There are, however, two caveats.

* Not every choicepoint can necessarily be replaced. Some Prolog programs depend on unrestricted backtracking or dynamic control flow that may require retaining Prolog semantics or generating more specialised deterministic code.
* Not every cut has a simple deterministic equivalent. Green cuts (used only for efficiency) are generally much easier to eliminate than red cuts (whose removal changes the program’s meaning). SWI-Prolog itself treats cuts as a low-level control mechanism rather than something that should normally be reimplemented directly.

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
