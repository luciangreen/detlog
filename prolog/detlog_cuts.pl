:- module(detlog_cuts, [classify_cuts/2]).

:- use_module(library(lists)).

classify_cuts(Clauses, Cuts) :-
    findall(
        cut_info{
            predicate:PI,
            cut:Class
        },
        (
            predicate_signature(Clauses, PI),
            cut_class_of_predicate(Clauses, PI, Class)
        ),
        Raw
    ),
    sort(Raw, Cuts).

predicate_signature(Clauses, Name/Arity) :-
    member(clause_info{head:Head, body:_, line:_}, Clauses),
    functor(Head, Name, Arity).

cut_class_of_predicate(Clauses, Name/Arity, no_cut) :-
    \+ (member(clause_info{head:Head, body:Body, line:_}, Clauses),
        functor(Head, Name, Arity),
        sub_term(!, Body)),
    !.
cut_class_of_predicate(Clauses, Name/Arity, safe_if_commit) :-
    member(clause_info{head:Head, body:Body, line:_}, Clauses),
    functor(Head, Name, Arity),
    Body = (Cond, !, Then),
    \+ sub_term((_;_), Cond),
    \+ sub_term((_;_), Then),
    !.
cut_class_of_predicate(_, _, fallback_unsafe_cut).
