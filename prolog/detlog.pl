:- module(detlog, [detlog/2, detlog/3, detlog_compile/2, detlog_verify_cut_free/0]).

:- use_module(library(option)).
:- use_module(library(lists)).
:- use_module(detlog_reader).
:- use_module(detlog_analysis).
:- use_module(detlog_codegen).
:- use_module(detlog_source_map).
:- use_module(detlog_cache).
:- use_module(detlog_diagnostics).
:- use_module(detlog_runtime).
:- use_module(detlog_verify).

detlog(File, Query) :-
    detlog(File, Query, []).

detlog(File, Query, Options0) :-
    detlog_options(Options0, Options),
    once_det(compile_for_use(File, Options, GeneratedModule)),
    call(GeneratedModule:Query),
    maybe_run_benchmarks(File, Query, Options).

detlog_compile(File, Options0) :-
    detlog_options(Options0, Options),
    once_det(compile_for_use(File, Options, _)).

compile_for_use(File, Options, Module) :-
    detlog_diagnostics:clear_diagnostics,
    detlog_source_map:clear_source_map,
    absolute_file_name(File, Absolute, [file_errors(fail)]),
    read_source_file(Absolute, SourceInfo),
    source_hash(SourceInfo, SourceHash),
    option(fallback(FallbackPolicy), Options),
    cache_key(Absolute, SourceHash, FallbackPolicy, CacheKey),
    (   cache_lookup(CacheKey, Cached)
    ->  Module = Cached.module
    ;   compile_source(Absolute, SourceInfo, SourceHash, Options, CacheKey, Module)
    ).

compile_source(Absolute, SourceInfo, _SourceHash, Options0, CacheKey, Module) :-
    analyse_source(SourceInfo, Analysis),
    option(fallback(FallbackPolicy), Options0),
    generate_module(Absolute, SourceInfo, Analysis, FallbackPolicy, Generated),
    Module = Generated.module,
    cache_store(CacheKey, Generated),
    maybe_display_code(Generated.code, Options0),
    maybe_write_code(Generated.code, Options0),
    maybe_report_trace(Generated.trace, Options0),
    maybe_report_modes(Analysis, SourceInfo, Options0).

detlog_options(Options0, Options) :-
    merge_options(Options0,
                  [ code(false),
                    trace(false),
                    modes(false),
                    benchmarks(false),
                    fallback(warn)
                  ],
                  Merged),
    must_be_valid_options(Merged),
    Options = Merged.

must_be_valid_options(Options) :-
    option(code(Code), Options),
    valid_code_option(Code),
    option(trace(Trace), Options),
    must_be(boolean, Trace),
    option(modes(Modes), Options),
    must_be(boolean, Modes),
    option(benchmarks(Benchmarks), Options),
    must_be(boolean, Benchmarks),
    option(fallback(Fallback), Options),
    memberchk(Fallback, [warn, silent, error]).

valid_code_option(false).
valid_code_option(true).
valid_code_option(File) :-
    atom(File),
    File \== true,
    File \== false.

maybe_display_code(Code, Options) :-
    (   option(code(true), Options)
    ->  format('~s~n', [Code])
    ;   true
    ).

maybe_write_code(Code, Options) :-
    option(code(OutputFile), Options),
    atom(OutputFile),
    OutputFile \== true,
    OutputFile \== false,
    setup_call_cleanup(
        open(OutputFile, write, Stream),
        format(Stream, '~s', [Code]),
        close(Stream)
    ).
maybe_write_code(_, _).

maybe_report_trace(Trace, Options) :-
    (   option(trace(true), Options)
    ->  forall(member(Line, Trace), format('~w~n', [Line]))
    ;   true
    ).

maybe_report_modes(Analysis, SourceInfo, Options) :-
    (   option(modes(true), Options)
    ->  format_modes(Analysis.modes, SourceInfo)
    ;   true
    ).

format_modes(Modes, SourceInfo) :-
    forall(
        member(ModeInfo, Modes),
        (
            ModeInfo = mode_info{predicate:PI, mode:Mode, determinism:Det},
            source_predicate_line(SourceInfo, PI, Line),
            format('~w ~w ~w (~w:~w)~n',
                   [PI, Mode, Det, SourceInfo.file, Line])
        )
    ).

source_predicate_line(SourceInfo, Predicate, Line) :-
    (   member(Source, SourceInfo.predicates),
        Source.predicate == Predicate
    ->  Line = Source.line
    ;   Line = unknown
    ).

maybe_run_benchmarks(File, Query, Options) :-
    (   option(benchmarks(true), Options)
    ->  statistics(runtime, [StartMs|_]),
        once_det(detlog(File, Query, [benchmarks(false)|Options])),
        statistics(runtime, [EndMs|_]),
        Duration is EndMs - StartMs,
        format('benchmark runtime_ms=~w~n', [Duration])
    ;   true
    ).
