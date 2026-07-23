:- module(detlog_verify, [detlog_verify_cut_free/0]).

:- use_module(library(apply)).
:- use_module(library(filesex)).
:- use_module(library(lists)).

detlog_verify_cut_free :-
    implementation_prolog_files(Files),
    findall(Finding,
            (member(File, Files), file_operational_cuts(File, Finding)),
            Findings),
    (   Findings == []
    ->  format('Detlog implementation is operationally cut-free.~n')
    ;   print_findings(Findings),
        fail
    ).

implementation_prolog_files(Files) :-
    expand_file_name('prolog/**/*.pl', All),
    include(exists_file, All, Files).

file_operational_cuts(File, operational_cut_found(File, Module, PI, ClauseNumber, Line, Context)) :-
    read_term_records(File, Module, Terms),
    nth1(ClauseNumber, Terms, term_record(PI, Line, Body)),
    operational_cut_context(Body, Context).

read_term_records(File, Module, Terms) :-
    setup_call_cleanup(
        open(File, read, Stream),
        read_terms(Stream, user, Module, [], Terms),
        close(Stream)
    ).

read_terms(Stream, Module0, Module, Acc, Terms) :-
    stream_property(Stream, position(Pos0)),
    stream_position_data(line_count, Pos0, Line),
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  reverse(Acc, Terms),
        Module = Module0
    ;   term_record(Term, Line, Module0, Module1, MaybeRecord),
        maybe_cons(MaybeRecord, Acc, Acc1),
        read_terms(Stream, Module1, Module, Acc1, Terms)
    ).

term_record((:- module(M, _)), _Line, _Module0, M, none).
term_record((Head :- Body), Line, Module, Module, some(term_record(PI, Line, Body))) :-
    callable(Head),
    functor(Head, Name, Arity),
    PI = Name/Arity.
term_record(Fact, Line, Module, Module, some(term_record(PI, Line, true))) :-
    callable(Fact),
    Fact \= (:- _),
    Fact \= (?- _),
    functor(Fact, Name, Arity),
    PI = Name/Arity.
term_record(_, _Line, Module, Module, none).

maybe_cons(none, Acc, Acc).
maybe_cons(some(Item), Acc, [Item|Acc]).

operational_cut_context((A, B), Context) :-
    (operational_cut_context(A, Context) ; operational_cut_context(B, Context)).
operational_cut_context((A ; B), Context) :-
    (operational_cut_context(A, Context) ; operational_cut_context(B, Context)).
operational_cut_context((A -> B), Context) :-
    (operational_cut_context(A, Context) ; operational_cut_context(B, Context)).
operational_cut_context((A *-> B), Context) :-
    (operational_cut_context(A, Context) ; operational_cut_context(B, Context)).
operational_cut_context(\+ A, Context) :-
    operational_cut_context(A, Context).
operational_cut_context(!, goal_cut).
operational_cut_context(call(!), meta_call_cut).
operational_cut_context(once(!), once_cut).

print_findings([]).
print_findings([Finding|Rest]) :-
    write_term(Finding, [quoted(true)]),
    format('.~n'),
    print_findings(Rest).
