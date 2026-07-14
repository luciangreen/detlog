:- module(detlog_reader, [read_source_file/2, source_hash/2]).

:- use_module(library(sha)).
:- use_module(library(readutil)).
:- use_module(library(lists)).

read_source_file(File, source_info{
    file: File,
    source_module: SourceModule,
    clauses: Clauses,
    predicates: Predicates,
    terms: Terms
}) :-
    read_source_terms(File, Terms),
    source_module(Terms, SourceModule),
    findall(clause_info{head:Head, body:Body, line:Line},
            member(term_info{term:(Head :- Body), line:Line}, Terms),
            RuleClauses),
    findall(clause_info{head:Head, body:true, line:Line},
            (
                member(term_info{term:Head, line:Line}, Terms),
                callable(Head),
                Head \= (_ :- _),
                Head \= (:- _),
                Head \= (?- _)
            ),
            FactClauses),
    append(RuleClauses, FactClauses, Clauses),
    collect_predicates(Clauses, Predicates).

source_hash(SourceInfo, Hash) :-
    term_string(SourceInfo.terms, Text),
    sha_hash(Text, Bytes, []),
    hash_atom(Bytes, Hash).

read_source_terms(File, Terms) :-
    setup_call_cleanup(
        open(File, read, Stream),
        read_terms(Stream, Terms),
        close(Stream)
    ).

read_terms(Stream, Terms) :-
    stream_property(Stream, position(Pos0)),
    stream_position_data(line_count, Pos0, Line),
    read_term(Stream, Term, []),
    (   Term == end_of_file
    ->  Terms = []
    ;   Terms = [term_info{term:Term, line:Line}|Rest],
        read_terms(Stream, Rest)
    ).

source_module(Terms, Module) :-
    (   member(term_info{term:(:- module(Module, _))}, Terms)
    ->  true
    ;   Module = user
    ).

collect_predicates(Clauses, Predicates) :-
    findall(Name/Arity-Line,
            (
                member(clause_info{head:Head, body:_, line:Line}, Clauses),
                callable(Head),
                functor(Head, Name, Arity)
            ),
            Raw),
    keysort(Raw, Sorted),
    collapse_predicates(Sorted, Predicates).

collapse_predicates([], []).
collapse_predicates([PI-Line|Rest], [source_predicate{predicate:PI, line:Line}|Tail]) :-
    skip_same_predicate(Rest, PI, Remaining),
    collapse_predicates(Remaining, Tail).

skip_same_predicate([PI-_|Rest], PI, Remaining) :-
    !,
    skip_same_predicate(Rest, PI, Remaining).
skip_same_predicate(Rest, _, Rest).
