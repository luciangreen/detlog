# Detlog Prolog Program Requirements

## 1. Purpose

Detlog is an in-SWI-Prolog source converter that transforms ordinary Prolog into a more explicit, examinable, and efficient deterministic form.

Its purpose is to:

- expose and reduce hidden nondeterminism;
- convert suitable choicepoints into deterministic loops, choice packets, splices, and decision structures;
- preserve ordinary Prolog meaning, answer order, and effects where conversion is safe;
- prepare algorithms for clearer examination, optimisation, and later use with Manual Neural Networks (MNNs);
- execute converted code directly inside the SWI-Prolog REPL;
- optionally display or write the generated Detlog Prolog source.

Version 1 targets SWI-Prolog only. It does not target C, BASIC, 6502, Apple IIe, BASIClog, or automatic parallel execution.

---

## 2. Primary User Experience

Detlog must be usable from a running SWI-Prolog REPL.

The normal workflow is:

```prolog
?- detlog(File, Query).
```

This must:

1. read the ordinary Prolog source file;
2. analyse and convert the relevant predicates;
3. load the converted predicates into a generated temporary module;
4. execute the supplied query immediately;
5. return the query result in the REPL;
6. avoid displaying generated source unless requested.

The options form must be:

```prolog
?- detlog(File, Query, Options).
```

Required options:

```prolog
code(false).          % Default: run without displaying generated code
code(true).           % Display generated Detlog code before execution
code(File).           % Write generated Detlog code to File, then execute
trace(false).         % Default: do not display transformation trace
trace(true).          % Display a readable transformation trace
modes(false).         % Default: do not display inferred modes/determinism
modes(true).          % Display inferred modes and determinism
benchmarks(false).    % Default
benchmarks(true).     % Display source-versus-generated measurements
fallback(warn).       % Default predicate-level fallback policy
```

Examples:

```prolog
?- detlog('example.pl', main(Result)).
?- detlog('example.pl', main(Result), [code(true)]).
?- detlog('example.pl', main(Result),
          [code('example_detlog.pl'), trace(true), modes(true)]).
```

A separate conversion-only interface must also be available:

```prolog
?- detlog_compile(File, Options).
```

Examples:

```prolog
?- detlog_compile('example.pl', [code(true)]).
?- detlog_compile('example.pl', [code('example_detlog.pl')]).
```

The converter must never overwrite the original source file.

---

## 3. Scope

### 3.1 Included

Version 1 must provide:

- ordinary Prolog source parsing through SWI-Prolog;
- predicate dependency analysis;
- mode and determinism inference;
- cut classification and attempted conversion;
- choicepoint identification;
- deterministic loop generation;
- choice-packet generation;
- splice generation;
- streaming splice execution;
- conversion of suitable `member/2`, `between/3`, `findall/3`, `bagof/3`, and `setof/3` uses;
- handling of multiple clauses;
- handling of ordinary disjunction;
- structural recursion analysis;
- tail-recursion conversion;
- recursive DCG support;
- common-prefix and common-suffix factoring;
- source-location mappings;
- predicate-level fallback;
- semantic-equivalence tests;
- performance and memory benchmarks;
- incremental recompilation;
- optional Loop2 and PLOP integration points.

### 3.2 Excluded

Version 1 must not implement:

- a separate Detlog interpreter;
- compilation to C, BASIC, 6502, or assembly;
- Apple IIe facilities;
- BASIClog;
- automatic Piglog parallelisation;
- robot-specific libraries;
- automatic execution-time enforcement;
- CLP(FD) or attributed-variable conversion;
- speculative Loop2, PLOP, or Piglog APIs.

---

## 4. Language Model

### 4.1 Input language

Detlog accepts ordinary SWI-Prolog syntax.

It must analyse source terms without requiring programmers to rewrite their programs into a separate Detlog grammar.

Unsupported or unsafe predicates are excluded from the fully converted Detlog subset and handled through the fallback policy described below.

### 4.2 Output language

Fully converted predicates must be ordinary SWI-Prolog predicates with:

- no cuts;
- no ordinary disjunctions;
- no `findall/3`, `bagof/3`, or `setof/3`;
- no dynamic database operations;
- no unintended choicepoints;
- no hidden enumeration used merely to reconstruct a deterministic loop;
- explicit choice, loop, splice, decision, and state structures.

Fallback predicates may retain ordinary Prolog constructs, but they must be clearly reported and must not be described as fully converted Detlog.

### 4.3 Determinism classes

The analyser must classify predicates using at least:

```text
det       succeeds exactly once
semidet   succeeds zero or one time
multi     succeeds one or more times
nondet    succeeds zero or more times
unknown   cannot be classified safely
```

A fully converted ordinary predicate must be `det` or `semidet`, unless it explicitly returns a collection, packet, iterator state, or stream result.

---

## 5. Choice Packets

The canonical choice representation is:

```prolog
cp(Choices)
```

Example:

```prolog
cp([1,2,3])
```

Requirements:

1. `Choices` must be a proper finite list.
2. Values must be ground before the packet is consumed by a splice.
3. Duplicate choices must be preserved unless the source operation is `setof/3`.
4. Choice order must preserve original Prolog answer order.
5. Cyclic or improper choice lists must be rejected.
6. A literal source packet `cp([])` must be diagnosed as an invalid explicit choice.
7. An empty packet produced by a legitimate failed generator means that there are no rows to process; it must not crash the converter.
8. Nested packets must be normalised recursively while preserving order:

```prolog
cp([1, cp([2,3])])
```

becomes logically equivalent to:

```prolog
cp([1,2,3])
```

A nested packet intended as ordinary data must be wrapped explicitly, for example:

```prolog
data(cp([2,3]))
```

---

## 6. Multiple Clauses

Source facts and clauses must remain ordinary source clauses.

For example:

```prolog
a(1).
a(2).
```

must not be rewritten publicly as:

```prolog
a(cp([1,2])).
```

When a multi-solution predicate contributes alternatives to a later splice or deterministic loop, the converter must generate a contextual adapter.

Conceptually:

```prolog
a_cp(CP) :-
    % generated deterministic collection of a/1 answers
    ...
```

The generated adapter must:

- preserve clause order;
- preserve duplicate answers;
- preserve complete variable-binding relationships;
- avoid `findall/3` in final generated code;
- be generated only when needed;
- remain private to the generated module unless explicitly requested.

When several variables are produced together, each alternative must preserve the complete substitution, for example:

```prolog
cp([
    bindings([x=1,y=a]),
    bindings([x=2,y=b])
])
```

or an equivalent generated tuple representation.

---

## 7. `member/2` and `member_cp/2`

`member/2` must not be converted indiscriminately.

It must be converted only when its nondeterminism contributes to:

- a later splice;
- a deterministic loop;
- a collected result;
- a decision structure;
- another converted generator.

A canonical helper may be provided:

```prolog
member_cp(+List, -ChoicePacket)
```

Example:

```prolog
member_cp([1,2,3], cp([1,2,3])).
```

The converter should fuse unnecessary `findall/3`–`member/2` and `splice/2`–`member/2` pairs.

Example source pattern:

```prolog
findall(X, generator(X), Xs),
member(X, Xs),
process(X).
```

should become a direct deterministic loop over `generator/1` answers where semantics permit.

Likewise:

```prolog
splice(Choices, Rows),
member(Row, Rows),
process(Row).
```

should become a streaming splice consumer rather than materialising and re-enumerating `Rows`.

---

## 8. Splice Semantics

### 8.1 Canonical collected form

The canonical logical interface is:

```prolog
splice(+ChoiceTerms, -Rows)
```

Required semantics:

```prolog
splice(
    [cp([1,2]), cp([3,4])],
    [[1,3],[1,4],[2,3],[2,4]]
).
```

Mixed fixed values and packets must be supported:

```prolog
splice(
    [fixed, cp([1,2]), x],
    [[fixed,1,x], [fixed,2,x]]
).
```

Left-to-right Prolog enumeration order must be preserved.

### 8.2 Streaming implementation

The primary implementation must be streaming. It must not construct the complete Cartesian product unless the caller explicitly requests a collection.

Required public forms:

```prolog
splice_collect(+ChoiceTerms, -Rows).
splice_each(+ChoiceTerms, :Consumer).
splice_first(+ChoiceTerms, -Row).
splice_select(+ChoiceTerms, :Condition, :Consumer).
```

Semantics:

- `splice_collect/2` materialises all rows.
- `splice_each/2` generates rows one at a time and calls `Consumer` once for each row.
- `splice_first/2` returns the first row in normal left-to-right Prolog order.
- `splice_select/3` streams rows that satisfy `Condition` to `Consumer`.

The converter may use a lower-level state-passing iterator internally, but that representation need not be public.

### 8.3 Structure preservation

Version 1 must support list-based `ChoiceTerms`.

Support for arbitrary compound templates may be added if straightforward, but must not delay the required list-based implementation.

### 8.4 Strict scheduling rule

“Splice early, enumerate late” is a strict compiler rule.

The converter must:

1. identify independent alternatives as early as their required inputs are available;
2. construct or stream their combined value pathway;
3. delay consumer execution until the necessary row values are available;
4. avoid premature side effects;
5. avoid unnecessary intermediate collections.

---

## 9. Disjunction

Ordinary disjunction:

```prolog
(A ; B)
```

must be converted into an explicit choice representation when safe.

For example:

```prolog
p(X) :-
    (X = 1 ; X = 2),
    s(X).
```

must be converted conceptually into an ordered choice packet whose alternatives are streamed into `s/1`.

The converter must preserve:

- branch order;
- variable bindings;
- duplicate solutions;
- failure behaviour;
- exception behaviour;
- side-effect order.

A disjunction containing effects before branch commitment must not be converted speculatively.

If safe conversion cannot be established, the containing predicate must use predicate-level fallback.

If-then-else:

```prolog
(If -> Then ; Else)
```

should be converted as deterministic control rather than treated as an ordinary choice packet.

---

## 10. Cut Conversion

Cuts may occur in converter input.

The converter must classify each cut as one of:

- removable green cut;
- deterministic clause-selection cut;
- first-solution cut;
- state-transition cut;
- unsupported cut.

It must attempt to replace cuts with explicit deterministic constructs:

```prolog
if_commit/3
first/2
once_det/1
guard/1
decision/2
loop_exit/1
```

Example:

```prolog
a :- b, !, c.
a :- d.
```

must be converted, where semantics are preserved, into the equivalent of:

```prolog
a :-
    if_commit(b, c, d).
```

The required meaning is:

- attempt `b`;
- if `b` fails, execute `d`;
- if `b` succeeds, commit to that path and execute `c`;
- if `c` then fails, do not execute `d`.

A cut after a known finite generator may be converted into a first-solution operation.

Cuts involving unsafe combinations of:

- meta-calls;
- dynamic predicates;
- pre-commit side effects;
- ambiguous disjunction;
- unclear clause scope;
- unanalysed module behaviour

must not be approximated.

If a cut cannot be safely converted, it may remain only inside a clearly identified predicate-level fallback. Such a predicate is not fully converted Detlog.

### 10.1 Required deterministic control predicates

The runtime library must provide documented forms with intuitive semantics:

```prolog
if_commit(:If, :Then, :Else).
```

Execute `Then` after the first committed success of `If`; execute `Else` only if `If` has no solution.

```prolog
first(:Generator, -Value).
```

Return the first value produced by a finite or safely bounded generator.

```prolog
once_det(:Goal).
```

Run `Goal` at most once, retaining its first solution.

```prolog
guard(:Condition).
```

Require a deterministic or semideterministic condition before continuing.

```prolog
decision(+Cases, :Else).
```

Evaluate ordered guarded cases and execute the first matching case, otherwise `Else`.

```prolog
loop_exit(+Reason).
```

Exit a generated deterministic loop with an explicit reason or result.

These predicates must be documented in everyday language as well as technical language.

---

## 11. Loop Conversion

The converter must attempt to replace the following with deterministic loops or explicit collections:

- `member/2`;
- `between/3`;
- `findall/3`;
- `bagof/3`;
- `setof/3`;
- multiple clauses;
- DCG alternatives;
- structural recursion over lists;
- suitable tail recursion.

Independent generators should be compiled directly into nested loops rather than first constructing packets when this is simpler and more efficient.

The converter must automatically choose among:

- direct deterministic recursion;
- nested loops;
- streaming splices;
- materialised splice tables;
- decision trees;
- explicit choice packets.

The selection must preserve semantics before pursuing performance.

### 11.1 Collection semantics

Conversions must preserve normal SWI-Prolog behaviour:

- `findall/3`: preserve answer order and duplicates;
- `bagof/3`: preserve free-variable grouping and duplicates;
- `setof/3`: preserve grouping, sorting, and duplicate removal.

Generated final code must not retain these predicates merely as hidden implementation shortcuts.

---

## 12. Recursion and Termination

General recursion is accepted as input.

The converter must not claim to decide termination in all cases.

Version 1 must soundly recognise and optimise common cases, including:

- structural recursion over finite lists;
- tail recursion;
- bounded numeric recursion;
- straightforward accumulator recursion;
- recursive DCGs after DCG expansion;
- finite mutually recursive patterns where a decreasing measure is clear.

The analyser must look for:

- obvious nontermination;
- unbounded recursion;
- increasing term size;
- missing decreasing arguments;
- uncontrolled choice growth;
- left-recursive DCGs;
- recursion that invalidates deterministic conversion.

Outcomes:

- proven safe patterns may be converted;
- uncertain patterns compile with a diagnostic and may use predicate-level fallback;
- obvious nontermination or uncontrolled growth must be reported prominently;
- the system must not silently claim a proof it has not established.

Tail recursion should be converted automatically when argument flow and semantics are known.

Recursive DCGs are required in version 1. DCGs should first be translated into ordinary predicates using SWI-Prolog-compatible expansion, then analysed.

---

## 13. Unification and Data

Version 1 must preserve ordinary SWI-Prolog unification semantics outside choice packets.

Requirements:

- variables, lists, and structures are supported;
- full ordinary SWI-Prolog unification is supported;
- rational-tree behaviour should match normal SWI-Prolog unless explicitly rejected by a packet or indexing rule;
- attributed variables and CLP(FD) are unsupported in the fully converted subset;
- strings use SWI-Prolog string semantics;
- choice-packet contents must be ground when consumed;
- variable aliasing across an alternative must be preserved;
- generated collection adapters must preserve complete bindings, not independently combine correlated variables.

---

## 14. Subterm Indexing

Subterm indexing and subterm-index looping must be visible Detlog constructs rather than purely invisible compiler implementation details.

The implementation must define readable ordinary Prolog predicates for:

- retrieving a subterm by an address or index;
- iterating deterministically over indexed subterms;
- preserving term structure and variable identity;
- using indexed values in loop and splice generation.

The exact predicate names may be selected by the implementation, but they must be:

- documented;
- tested;
- stable after version 1;
- readable in displayed generated source;
- free from undocumented reliance on PLOP internals.

---

## 15. Effects and State

Version 1 provides deterministic language foundations, not robot-specific facilities.

The analyser must recognise effects involving:

- terminal I/O;
- files;
- timers;
- sensors;
- actuators;
- networking;
- dynamic database operations;
- exceptions.

State-changing generated predicates should use explicit state threading where conversion is supported:

```prolog
operation(Input, State0, State1).
```

Rules:

1. Effectful operations must not execute before a choice is committed.
2. Optimisation must not reorder side effects.
3. Side-effecting predicates must not be parallelised.
4. The number and order of effects must match the source program.
5. Generated loops may contain effects only when each iteration's execution order is explicit.
6. `assert/1` and `retract/1` should normally trigger fallback unless they are converted to an explicit state representation.
7. Exceptions may remain SWI-Prolog exceptions where preservation is clearer than conversion.
8. No automatic runtime deadline enforcement is required.

---

## 16. Declarations

Detlog should recognise optional declarations such as:

```prolog
:- determinism(move_robot/3, det).
:- deadline(move_robot/3, 20_ms).
:- priority(move_robot/3, high).
:- effect(move_robot/3, io).
:- splice_limit(process/2, 100000).
```

Declarations are documentation and analysis contracts.

Requirements:

- determinism declarations must be checked against inference;
- contradictions must produce diagnostics;
- deadline and priority declarations are retained and documented but need not be enforced;
- invalid declaration syntax must produce a diagnostic;
- declaration meanings must be explained in everyday language in the README and generated documentation.

---

## 17. Large Choice Spaces

The converter must estimate Cartesian-product size where the dimensions are statically or cheaply knowable.

It must distinguish:

- estimated number of rows;
- estimated materialised memory;
- streaming execution;
- early-stopping consumers.

Rules:

1. A large product must generate a warning.
2. A materialised product above the configured limit must not proceed silently.
3. A large streaming product may proceed when no full collection is constructed.
4. A consumer that stops after the first or a bounded number of rows may proceed without materialising the full space.
5. The user may configure limits through options or declarations.
6. When conversion requires partitioning beyond Detlog's scope, diagnostics should recommend Piglog.
7. Core Detlog must not depend on Piglog being installed.
8. Version 1 may emit partition metadata for future Piglog use, but must not invent or assume a Piglog API.

---

## 18. PLOP and Loop2

### 18.1 Loop2

Loop2 is an optional external dependency or optimisation pass.

Detlog must define an adapter boundary rather than embed undocumented assumptions.

If Loop2 is unavailable:

- core Detlog conversion must continue;
- Loop2-specific optimisation must be skipped;
- a diagnostic may be shown when tracing is enabled.

### 18.2 PLOP

PLOP is an optional external optimiser.

It may perform:

- common-prefix factoring;
- common-suffix factoring;
- decision-tree compression;
- optimisation across clauses;
- optimisation across predicates;
- optimisation of generated strings and DCGs;
- broader module-level optimisation where semantics are proven.

PLOP optimisations must be conservative.

They may be applied only when semantic equivalence is established through static analysis, tests, or both.

PLOP must not change:

- answer order;
- duplicate answers;
- variable bindings;
- exception behaviour;
- side-effect order;
- termination behaviour.

The converter must not invent a PLOP API. Integration must use an explicit adapter module and documented dependency version.

---

## 19. Predicate Merging and Public Interfaces

Common-prefix and common-suffix factoring are required optimisation goals.

The optimiser may merge internal implementations across predicates, but it must preserve externally observable callability.

The following must retain callable wrappers unless all call sites are safely rewritten:

- exported predicates;
- predicates called from outside the generated module;
- module-qualified predicates;
- predicates referenced through supported meta-data;
- predicates used by tests or declarations;
- DCG entry points.

Internal private predicates may be renamed, merged, or removed.

Diagnostics and source maps must continue to identify original source predicate names.

---

## 20. Fallback Behaviour

Fallback is predicate-level.

The converter must not mix transformed and untransformed goals inside a predicate in a way that obscures semantics.

When a predicate cannot be safely converted:

1. retain or copy the original predicate into the generated module;
2. mark it as fallback metadata;
3. preserve source location;
4. issue a diagnostic under the default `fallback(warn)` policy;
5. allow supported predicates elsewhere to remain converted;
6. preserve ordinary SWI-Prolog behaviour.

Fallback predicates may contain:

- cuts that could not be converted;
- unsupported meta-calls;
- dynamic operations;
- attributed variables;
- unsafe effects;
- uncertain recursion;
- other unsupported constructs.

They must not be counted as fully deterministic Detlog predicates.

Required fallback options:

```prolog
fallback(warn).   % Preserve predicate and warn; default
fallback(error).  % Stop when fallback would be required
fallback(silent). % Preserve predicate without ordinary warnings
```

Even under `fallback(silent)`, fallback information must remain available to programmatic diagnostics.

---

## 21. Compiler Pipeline

The required pipeline is:

```text
Read ordinary Prolog source
→ record modules, declarations, clauses, and source locations
→ expand DCGs
→ build predicate dependency graph
→ infer modes, determinism, effects, and recursion properties
→ classify cuts
→ identify choicepoints and correlated variable pathways
→ choose loops, choice packets, splices, or decision structures
→ convert safe cuts
→ generate contextual multi-clause adapters
→ enforce splice-early/enumerate-late scheduling
→ fuse unnecessary collection/enumeration pairs
→ apply safe common-prefix and common-suffix factoring
→ optionally call Loop2 and PLOP through adapters
→ remove converted findall/bagof/setof, disjunctions, cuts, and hidden choicepoints
→ verify generated predicates
→ retain explicit predicate-level fallbacks where needed
→ load generated module into SWI-Prolog
→ optionally display or write generated source
→ execute the requested query
```

Intermediate representations do not need to be exposed as public user interfaces.

---

## 22. Source Mapping

Every generated predicate and diagnostic must retain:

- original file;
- original module;
- source predicate;
- clause identifier;
- source line where available;
- transformed predicate name;
- conversion or fallback status.

Runtime exceptions in generated predicates should be translated back to original source locations where practical.

---

## 23. Incremental Compilation

The converter must support incremental recompilation.

Requirements:

- detect changes using content hashes or parsed-term hashes;
- maintain a predicate dependency graph;
- regenerate changed predicates and affected callers;
- regenerate affected merged or factored predicates;
- include Detlog, Loop2, and PLOP adapter versions in cache validity;
- abolish stale generated predicates;
- use an in-memory cache initially;
- allow a persistent cache later without changing public semantics.

---

## 24. Diagnostics

Diagnostics must include where applicable:

- severity;
- original predicate;
- generated predicate;
- clause;
- source line;
- unsupported construct;
- inferred determinism;
- reason conversion was or was not safe;
- suggested Detlog replacement;
- fallback status;
- estimated choice-space size;
- failed proof obligation.

Suggested severities:

```text
info
warning
fallback
error
```

Mode and determinism reports are displayed only when requested.

Example:

```text
a/1: multi → contextual choice adapter
c/2: nondet → streaming splice + deterministic consumer loop
q/1: fallback → unsupported attributed variable at source.pl:42
```

Failed proof obligations do not automatically stop code generation. They must disable the unsafe optimisation or trigger fallback.

---

## 25. Semantic Equivalence

The converter must compare source and generated behaviour in tests.

Equivalence includes, where relevant:

- success and failure;
- answer count;
- answer order;
- duplicate answers;
- complete substitutions;
- exception behaviour;
- effect order and count;
- finite termination behaviour.

Answer comparison must canonicalise variable names while preserving variable aliasing.

For predicates with potentially infinite answer sets, tests must use bounded inputs or bounded observation.

Optimisation must never be accepted merely because answer sets match when order, effects, or termination differ.

---

## 26. Verification of Determinism

Generated predicates classified as `det` or `semidet` must be tested for unintended residual choicepoints using SWI-Prolog facilities such as `deterministic/1`, suitable wrappers, or equivalent instrumentation.

Verification must cover:

- direct calls;
- generated loops;
- splice consumers;
- decision predicates;
- converted cuts;
- recursive predicates;
- DCGs;
- generated adapters.

Fallback predicates are excluded from fully deterministic verification but must be listed separately.

---

## 27. Required Tests

Use `plunit`.

The test suite must include:

- simple deterministic predicates;
- semideterministic predicates;
- multiple facts;
- multiple clauses;
- `member/2`;
- `between/3`;
- `findall/3`;
- `bagof/3`;
- `setof/3`;
- nested generators;
- independent generators;
- correlated variables;
- duplicate answers;
- ordinary disjunction;
- if-then-else;
- convertible cuts;
- unconvertible cuts and fallback;
- nested choice packets;
- explicit empty packets;
- generator-produced empty choices;
- mixed fixed and choice values;
- streaming splice order;
- `splice_first/2`;
- `splice_select/3`;
- recursion over lists;
- tail recursion;
- uncertain recursion;
- recursive DCGs;
- left-recursive DCG diagnostics;
- strings;
- full ordinary unification;
- unsupported attributed variables;
- I/O and other side effects;
- explicit state threading;
- large materialised products;
- large streaming products;
- common-prefix factoring;
- common-suffix factoring;
- source mappings;
- incremental recompilation;
- optional dependency absence;
- exact source-versus-generated answer order.

Every bug fix must add a regression test.

---

## 28. Benchmarks

Benchmarks must measure at least:

- execution time;
- SWI-Prolog inferences;
- peak stack or memory use where available;
- number of generated rows;
- number of materialised rows;
- compilation time;
- residual choicepoints;
- source-versus-generated comparison.

Initial benchmark classes must include:

- decision trees;
- DCGs;
- symbolic transformations;
- S2A-style algorithms;
- splice-heavy algorithms;
- nested generator programs;
- list recursion.

Detlog is not required to outperform ordinary SWI-Prolog on every program.

Benchmark reports must identify:

- improvements;
- regressions;
- conversion overhead;
- cases where fallback was used;
- cases where examination or determinism improved despite neutral performance.

---

## 29. Repository Structure

Recommended structure:

```text
detlog/
├── pack.pl
├── README.md
├── PROGRAM_REQUIREMENTS.md
├── PROGRESS.md
├── LICENSE
├── prolog/
│   ├── detlog.pl
│   ├── detlog_reader.pl
│   ├── detlog_analysis.pl
│   ├── detlog_modes.pl
│   ├── detlog_effects.pl
│   ├── detlog_recursion.pl
│   ├── detlog_cuts.pl
│   ├── detlog_choices.pl
│   ├── detlog_splice.pl
│   ├── detlog_loops.pl
│   ├── detlog_codegen.pl
│   ├── detlog_runtime.pl
│   ├── detlog_source_map.pl
│   ├── detlog_cache.pl
│   ├── detlog_diagnostics.pl
│   └── adapters/
│       ├── detlog_loop2.pl
│       ├── detlog_plop.pl
│       └── detlog_piglog_metadata.pl
├── test/
│   ├── unit/
│   ├── integration/
│   ├── equivalence/
│   ├── regression/
│   └── fixtures/
├── benchmark/
└── docs/
```

The implementation may adjust filenames while preserving clear separation of concerns.

---

## 30. Documentation

The repository must document:

- the purpose of Detlog;
- the REPL-first workflow;
- the difference between source Prolog, fully converted Detlog, and fallback predicates;
- choice packets;
- streaming splices;
- deterministic loops;
- cut conversion;
- effect commitment;
- recursion analysis limitations;
- declarations in everyday language;
- optional Loop2, PLOP, and Piglog relationships;
- examples before and after conversion;
- how to request generated code;
- how to request traces, modes, and benchmarks;
- known limitations.

Generated code should be readable enough for examination by a Prolog programmer.

---

## 31. GitHub Copilot Agent Instructions

The GitHub Copilot Agent must implement the project in explicit stages.

For every stage it must:

1. review these requirements;
2. implement only the stage's defined scope;
3. add or update unit tests;
4. add or update integration tests;
5. add semantic-equivalence tests;
6. update documentation;
7. perform a self-review;
8. run the stage tests;
9. run the complete test suite;
10. fix failures;
11. repeat until all tests pass;
12. update `PROGRESS.md`.

The Agent must not:

- change Detlog semantics merely to make tests pass;
- silently weaken answer-order equivalence;
- remove difficult tests;
- claim deterministic conversion when fallback remains;
- invent Loop2, PLOP, or Piglog APIs;
- hide unsupported constructs;
- introduce speculative behaviour without documenting it;
- overwrite source programs.

The Agent may add dependencies, but must document:

- dependency name;
- version or source revision;
- purpose;
- licence;
- whether it is required or optional.

When a required semantic issue cannot be resolved from this document, the Agent must:

1. choose the most conservative behaviour that preserves SWI-Prolog semantics if possible;
2. document the decision in `PROGRESS.md`;
3. open a GitHub issue when the choice materially affects the language;
4. avoid speculative implementation.

Separate commits per stage are not required.

---

## 32. Implementation Stages

### Stage 1 — REPL shell and source reader

Deliver:

- `detlog/2`;
- `detlog/3`;
- `detlog_compile/2`;
- option parsing;
- source reading;
- temporary generated modules;
- optional code display and file output;
- source mappings;
- basic diagnostics.

Acceptance:

- a deterministic source program can be read, copied, loaded, and run;
- generated code is hidden by default;
- `code(true)` displays code;
- `code(File)` writes code without modifying the source.

### Stage 2 — Dependency, mode, determinism, and effect analysis

Deliver:

- predicate dependency graph;
- mode inference;
- determinism inference;
- effect classification;
- optional reports.

Acceptance:

- representative fixtures receive correct classifications;
- requested reports identify source locations.

### Stage 3 — Choice packets and multiple-clause adapters

Deliver:

- `cp/1` validation;
- nested-packet normalisation;
- contextual adapters for multiple clauses;
- correlated-binding preservation;
- `member_cp/2`.

Acceptance:

- order and duplicate answers match source Prolog;
- public source facts remain ordinary facts.

### Stage 4 — Streaming splice runtime

Deliver:

- `splice/2`;
- `splice_collect/2`;
- `splice_each/2`;
- `splice_first/2`;
- `splice_select/3`;
- fixed-value support;
- streaming Cartesian traversal;
- product-size estimation.

Acceptance:

- exact required examples pass;
- streaming forms do not materialise the full result;
- order matches source Prolog.

### Stage 5 — Loop conversion

Deliver conversions for:

- `member/2`;
- `between/3`;
- `findall/3`;
- basic `bagof/3`;
- basic `setof/3`;
- nested independent generators;
- fusion of collection/enumeration pairs.

Acceptance:

- generated converted predicates do not retain prohibited collection predicates;
- source and generated answers match exactly.

### Stage 6 — Disjunction and deterministic decisions

Deliver:

- ordered disjunction conversion;
- correlated branch bindings;
- if-then-else conversion;
- `guard/1`;
- `decision/2`.

Acceptance:

- answer order, failure, and effects are preserved;
- unsafe disjunctions use fallback.

### Stage 7 — Cut classification and conversion

Deliver:

- cut classification;
- `if_commit/3`;
- `first/2`;
- `once_det/1`;
- `loop_exit/1`;
- safe cut transformations;
- fallback for unsafe cuts.

Acceptance:

- source cut semantics are preserved;
- fully converted predicates contain no cuts;
- unconvertible cuts are visibly classified as fallback.

### Stage 8 — Recursion and DCGs

Deliver:

- structural recursion recognition;
- tail-recursion conversion;
- bounded numeric recursion;
- DCG expansion and analysis;
- recursive DCG support;
- termination and growth diagnostics.

Acceptance:

- supported patterns convert correctly;
- uncertain cases do not receive false proofs;
- left recursion is diagnosed.

### Stage 9 — Factoring and external adapters

Deliver:

- common-prefix factoring;
- common-suffix factoring;
- Loop2 adapter;
- PLOP adapter;
- optional Piglog partition metadata.

Acceptance:

- optimisations run only when equivalence is preserved;
- core operation works with dependencies absent;
- no external API is invented.

### Stage 10 — Incremental compilation, verification, and benchmarks

Deliver:

- dependency-aware cache;
- stale predicate removal;
- deterministic verification;
- complete benchmark suite;
- final documentation.

Acceptance:

- changed predicates and affected callers are regenerated;
- generated `det` and `semidet` predicates have no unintended choicepoints;
- all unit, integration, equivalence, and regression tests pass.

---

## 33. Definition of Done

Version 1 is complete when:

1. Detlog runs entirely inside the SWI-Prolog REPL.
2. Users can execute conversion and query evaluation with one command.
3. Generated source is hidden by default.
4. Users can request generated source on screen or in a separate file.
5. Required generators, disjunctions, cuts, recursion, DCGs, loops, packets, and splices are implemented or visibly handled through fallback.
6. Fully converted predicates contain no prohibited hidden nondeterministic constructs.
7. Source and generated answers match in value, order, duplicates, and relevant effects.
8. Source locations are retained.
9. Incremental recompilation works.
10. Optional dependencies do not prevent core operation.
11. The full test suite passes.
12. `PROGRESS.md` records completed work, limitations, and unresolved issues.
13. The README clearly distinguishes fully converted Detlog from ordinary Prolog fallback.
14. The implementation improves the examination of nondeterministic algorithms and provides a foundation for later MNN-oriented optimisation.

## 34. Cut-free implementation invariant

Detlog must accept source programs containing cut while keeping Detlog implementation and converted output operationally cut-free.

Required checks:

- `detlog_verify_cut_free/0` must parse implementation terms and fail on operational cut use.
- quoted cut inspection (for analysis) is allowed.
- fallback wrappers may call source predicates containing cut, but fallback must be diagnosed and must not be marked converted.
