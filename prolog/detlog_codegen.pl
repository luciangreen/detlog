:- module(detlog_codegen,
          [generate_module/5,
           source_term_kind/2,
           predicate_conversion_status/4]).

:- use_module(library(gensym)).
:- use_module(library(lists)).
:- use_module(detlog_source_map).
:- use_module(detlog_diagnostics).
:- use_module(detlog_runtime).

generate_module(_File, SourceInfo, Analysis, FallbackPolicy, Generated) :-
    gensym(detlog_generated_, Module),
    load_source(SourceInfo, LoadedSourceModule),
    export_predicates(SourceInfo.predicates, Exports),
    maplist(generated_predicate_clauses(SourceInfo, Analysis, FallbackPolicy, LoadedSourceModule),
            SourceInfo.predicates, PredicateClauseLists),
    append(PredicateClauseLists, WrapperClauses),
    module_text(Module, Exports, WrapperClauses, Code),
    load_generated_code(Module, Code),
    build_trace(SourceInfo.predicates, Analysis, Trace),
    Generated = generated{
        module:Module,
        code:Code,
        trace:Trace
    }.

load_source(SourceInfo, LoadedSourceModule) :-
    (   SourceInfo.source_module == user
    ->  gensym(detlog_source_, LoadedSourceModule),
        load_terms_into_module(SourceInfo.terms, LoadedSourceModule)
    ;   LoadedSourceModule = SourceInfo.source_module,
        load_files(SourceInfo.file, [silent(true)])
    ).

load_terms_into_module(Terms, Module) :-
    forall(member(term_info{term:Term, line:_}, Terms),
           assert_source_term(Module, Term)).

assert_source_term(Module, Term) :-
    source_term_kind(Term, Kind),
    process_source_term(Kind, Module, Term).

source_term_kind(end_of_file, end_of_file).
source_term_kind((:- _), directive).
source_term_kind((?- _), query).
source_term_kind((Head :- _Body), rule) :-
    callable(Head).
source_term_kind(Term, fact) :-
    callable(Term),
    Term \= (_ :- _),
    Term \= (:- _),
    Term \= (?- _).
source_term_kind(_, unsupported).

process_source_term(directive, _, _).
process_source_term(query, _, _).
process_source_term(end_of_file, _, _).
process_source_term(fact, Module, Fact) :-
    assertz(Module:Fact).
process_source_term(rule, Module, Rule) :-
    assertz(Module:Rule).
process_source_term(unsupported, _, Term) :-
    throw(error(unsupported_source_term(Term), _)).

export_predicates(Predicates, Exports) :-
    findall(PI, member(source_predicate{predicate:PI, line:_}, Predicates), Raw),
    sort(Raw, Exports).

generated_predicate_clauses(SourceInfo, Analysis, FallbackPolicy, SourceModule, SourcePred, ClauseTexts) :-
    SourcePred = source_predicate{predicate:PI, line:Line},
    predicate_conversion_status(Analysis, PI, Status, Reason),
    clauses_for_status(Status, SourceInfo, SourceModule, PI, Clauses),
    maplist(clause_text, Clauses, ClauseTexts),
    maplist(record_map(SourceInfo, PI, Line, Status), Clauses),
    maybe_fallback_diagnostic(Status, FallbackPolicy, PI, SourceInfo.file, Line, Reason).

clauses_for_status(converted, SourceInfo, _SourceModule, PI, Clauses) :-
    predicate_source_clauses(SourceInfo.clauses, PI, Clauses).
clauses_for_status(fallback, _SourceInfo, SourceModule, Name/Arity, [Wrapper]) :-
    functor(Head, Name, Arity),
    Head =.. [Name|Args],
    Qualified =.. [Name|Args],
    Wrapper = (Head :- SourceModule:Qualified).
clauses_for_status(rejected, _SourceInfo, SourceModule, Name/Arity, [Wrapper]) :-
    functor(Head, Name, Arity),
    Head =.. [Name|Args],
    Qualified =.. [Name|Args],
    Wrapper = (Head :- SourceModule:Qualified).

predicate_source_clauses(ClauseInfos, Name/Arity, Clauses) :-
    findall(Clause,
            (member(clause_info{head:Head, body:Body, line:_}, ClauseInfos),
             functor(Head, Name, Arity),
             clause_from_parts(Head, Body, Clause)),
            Clauses).

clause_from_parts(Head, true, Head).
clause_from_parts(Head, Body, (Head :- Body)) :-
    Body \== true.

clause_text(Clause, ClauseText) :-
    term_text(Clause, ClauseTermText),
    format(string(ClauseText), '~s.~n', [ClauseTermText]).

record_map(SourceInfo, PI, Line, Status, _Clause) :-
    record_source_map(source_map{
        file:SourceInfo.file,
        source_module:SourceInfo.source_module,
        predicate:PI,
        clause:PI,
        line:Line,
        generated_predicate:PI,
        status:Status
    }).

predicate_conversion_status(Analysis, PI, Status, Reason) :-
    conversion_conditions(Analysis, PI, Conditions),
    conversion_status_from_conditions(Conditions, Status, Reason).

conversion_conditions(Analysis, PI, conditions{
    determinism:Determinism,
    cut_status:CutStatus,
    effect:Effect,
    recursion:RecursionSafety,
    supported_constructs:SupportedConstructs
}) :-
    mode_det(Analysis.modes, PI, Determinism),
    cut_status(Analysis.cuts, PI, CutStatus),
    effect_status(Analysis.effects, PI, Effect),
    recursion_safety(Analysis.recursion, PI, RecursionSafety),
    supported_constructs(Analysis, PI, SupportedConstructs).

mode_det(Modes, PI, Determinism) :-
    (   member(ModeInfo, Modes),
        ModeInfo.predicate == PI,
        Determinism0 = ModeInfo.determinism
    ->  Determinism = Determinism0
    ;   Determinism = unknown
    ).

cut_status(Cuts, PI, CutStatus) :-
    (   member(CutInfo, Cuts),
        CutInfo.predicate == PI,
        CutStatus0 = CutInfo.cut
    ->  CutStatus = CutStatus0
    ;   CutStatus = fallback_unsafe_cut
    ).

effect_status(Effects, PI, Effect) :-
    (   member(EffectInfo, Effects),
        EffectInfo.predicate == PI,
        Effect0 = EffectInfo.effect
    ->  Effect = Effect0
    ;   Effect = io
    ).

recursion_safety(Recursions, PI, safe) :-
    member(RecursionInfo, Recursions),
    RecursionInfo.predicate == PI,
    RecursionInfo.uncertain == false.
recursion_safety(Recursions, PI, unsafe) :-
    \+ (member(RecursionInfo, Recursions),
        RecursionInfo.predicate == PI,
        RecursionInfo.uncertain == false).

supported_constructs(_Analysis, _PI, true).

conversion_status_from_conditions(Conditions, Status, Reason) :-
    decision(
        [
            case(Conditions.supported_constructs == false,
                 (Status = rejected, Reason = unsupported_constructs)),
            case(Conditions.cut_status \== no_cut,
                 (Status = fallback, Reason = unsafe_cut)),
            case(Conditions.effect \== pure,
                 (Status = fallback, Reason = impure_effects)),
            case(Conditions.recursion \== safe,
                 (Status = fallback, Reason = recursion_uncertain)),
            case(Conditions.determinism \== det,
                 (Status = fallback, Reason = nondeterministic)),
            case(true,
                 (Status = converted, Reason = all_required_properties_proved))
        ],
        (Status = fallback, Reason = wrapper_only_not_converted)
    ).

maybe_fallback_diagnostic(converted, _, _, _, _, _).
maybe_fallback_diagnostic(fallback, FallbackPolicy, PI, File, Line, Note) :-
    add_diagnostic(diagnostic{
        severity:fallback,
        original_predicate:PI,
        generated_predicate:PI,
        source_line:Line,
        source_file:File,
        reason:Note
    }),
    (   FallbackPolicy == warn
    ->  format(user_error, 'detlog fallback ~w at ~w:~w~n', [PI, File, Line])
    ;   FallbackPolicy == error
    ->  throw(error(detlog_fallback(PI, File, Line), _))
    ;   true
    ).
maybe_fallback_diagnostic(rejected, FallbackPolicy, PI, File, Line, Note) :-
    maybe_fallback_diagnostic(fallback, FallbackPolicy, PI, File, Line, Note).

module_text(Module, Exports, WrapperClauses, Code) :-
    term_text((:- module(Module, Exports)), ModuleDeclBody),
    format(string(ModuleDecl), '~s.~n', [ModuleDeclBody]),
    atomic_list_concat([ModuleDecl|WrapperClauses], Code).

term_text(Term, Text) :-
    copy_term(Term, Copy),
    numbervars(Copy, 0, _),
    format(string(Text), '~q', [Copy]).

load_generated_code(Module, Code) :-
    tmp_file_stream(text, TempFile, Stream),
    format(Stream, '~s', [Code]),
    close(Stream),
    load_files(TempFile, [silent(true), imports([])]),
    delete_file(TempFile),
    current_module(Module).

build_trace(Predicates, Analysis, Trace) :-
    findall(Line,
            (
                member(source_predicate{predicate:PI, line:_}, Predicates),
                trace_line(Analysis, PI, Line)
            ),
            Trace).

trace_line(Analysis, PI, Line) :-
    mode_det(Analysis.modes, PI, Det),
    cut_status(Analysis.cuts, PI, CutClass),
    predicate_conversion_status(Analysis, PI, Status, Reason),
    format(string(Line), '~w: ~w / ~w -> ~w (~w)', [PI, Det, CutClass, Status, Reason]).
