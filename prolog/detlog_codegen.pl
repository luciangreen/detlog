:- module(detlog_codegen,
          [generate_module/5]).

:- use_module(library(gensym)).
:- use_module(library(lists)).
:- use_module(detlog_source_map).
:- use_module(detlog_diagnostics).

generate_module(_File, SourceInfo, Analysis, FallbackPolicy, Generated) :-
    gensym(detlog_generated_, Module),
    load_source(SourceInfo, LoadedSourceModule),
    export_predicates(SourceInfo.predicates, Exports),
    maplist(wrapper_clause(SourceInfo, Analysis, FallbackPolicy, LoadedSourceModule),
            SourceInfo.predicates, WrapperClauses),
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

assert_source_term(_, (:- _)) :- !.
assert_source_term(_, (?- _)) :- !.
assert_source_term(Module, Term) :-
    assertz(Module:Term).

export_predicates(Predicates, Exports) :-
    findall(PI, member(source_predicate{predicate:PI, line:_}, Predicates), Raw),
    sort(Raw, Exports).

wrapper_clause(SourceInfo, Analysis, FallbackPolicy, SourceModule, SourcePred, ClauseText) :-
    SourcePred = source_predicate{predicate:Name/Arity, line:Line},
    functor(Head, Name, Arity),
    classify_predicate(Analysis, Name/Arity, Status),
    build_body(SourceModule, Head, Status, BodyText, ConversionNote),
    format(string(ClauseText), '~q :- ~s.~n', [Head, BodyText]),
    record_source_map(source_map{
        file:SourceInfo.file,
        source_module:SourceInfo.source_module,
        predicate:Name/Arity,
        clause:Name/Arity,
        line:Line,
        generated_predicate:Name/Arity,
        status:Status
    }),
    maybe_fallback_diagnostic(Status, FallbackPolicy, Name/Arity, SourceInfo.file, Line, ConversionNote).

classify_predicate(Analysis, PI, converted) :-
    member(mode_info{predicate:PI, determinism:det}, Analysis.modes),
    member(cut_info{predicate:PI, cut:no_cut}, Analysis.cuts),
    member(effect_info{predicate:PI, effect:pure}, Analysis.effects),
    !.
classify_predicate(_, _, fallback).

build_body(SourceModule, Head, converted, BodyText, converted) :-
    Head =.. [Name|Args],
    Qualified =.. [Name|Args],
    format(string(BodyText), '~q:~q', [SourceModule, Qualified]).
build_body(SourceModule, Head, fallback, BodyText, fallback) :-
    Head =.. [Name|Args],
    Qualified =.. [Name|Args],
    format(string(BodyText), '~q:~q', [SourceModule, Qualified]).

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

module_text(Module, Exports, WrapperClauses, Code) :-
    format(string(ModuleDecl), ':- module(~q, ~q).~n', [Module, Exports]),
    atomic_list_concat([ModuleDecl|WrapperClauses], Code).

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
    member(mode_info{predicate:PI, determinism:Det}, Analysis.modes),
    member(cut_info{predicate:PI, cut:CutClass}, Analysis.cuts),
    classify_predicate(Analysis, PI, Status),
    format(string(Line), '~w: ~w / ~w -> ~w', [PI, Det, CutClass, Status]).
