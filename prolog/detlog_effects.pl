:- module(detlog_effects, [classify_effects/2]).

:- use_module(library(lists)).

classify_effects(Clauses, Effects) :-
    findall(
        effect_info{
            predicate:PI,
            effect:Effect
        },
        (
            predicate_signature(Clauses, PI),
            effect_of_predicate(Clauses, PI, Effect)
        ),
        Raw
    ),
    sort(Raw, Effects).

predicate_signature(Clauses, Name/Arity) :-
    member(clause_info{head:Head, body:_, line:_}, Clauses),
    functor(Head, Name, Arity).

effect_of_predicate(Clauses, Name/Arity, io) :-
    member(clause_info{head:Head, body:Body, line:_}, Clauses),
    functor(Head, Name, Arity),
    contains_effect(Body).
effect_of_predicate(Clauses, Name/Arity, pure) :-
    \+ (member(clause_info{head:Head, body:Body, line:_}, Clauses),
        functor(Head, Name, Arity),
        contains_effect(Body)).

contains_effect(Body) :-
    sub_term(Goal, Body),
    callable(Goal),
    Goal =.. [Functor|_],
    memberchk(Functor,
              [write, writeln, format, read, open, close, assertz, retract, nb_setval]).
