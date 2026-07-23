:- module(detlog_modes, [infer_modes/2]).

:- use_module(library(lists)).

infer_modes(Clauses, Modes) :-
    findall(
        mode_info{
            predicate:PI,
            mode:Mode,
            determinism:Det
        },
        (
            predicate_signature(Clauses, PI),
            mode_of_predicate(Clauses, PI, Mode),
            determinism_of_predicate(Clauses, PI, Det)
        ),
        Raw
    ),
    sort(Raw, Modes).

predicate_signature(Clauses, Name/Arity) :-
    member(clause_info{head:Head, body:_, line:_}, Clauses),
    functor(Head, Name, Arity).

mode_of_predicate(Clauses, Name/Arity, mode(ArgModes)) :-
    findall(Head,
            (member(clause_info{head:Head, body:_, line:_}, Clauses), functor(Head, Name, Arity)),
            Heads),
    Heads = [First|_],
    First =.. [_|Args],
    maplist(arg_mode(Heads), Args, ArgModes).

arg_mode(Heads, Arg, in) :-
    (   ground(Arg),
        Heads \= []
    ->  true
    ;   fail
    ).
arg_mode(_, _, inout).

determinism_of_predicate(Clauses, Name/Arity, Det) :-
    findall(Body,
            (
                member(clause_info{head:Head, body:Body, line:_}, Clauses),
                functor(Head, Name, Arity)
            ),
            Bodies),
    length(Bodies, Count),
    (   Count =:= 0
    ->  Det = det
    ;   Count =:= 1,
        \+ contains_choicepoint(Bodies)
    ->  Det = det
    ;   Count =:= 1
    ->  Det = semidet
    ;   Det = nondet
    ).

contains_choicepoint(Bodies) :-
    member(Body, Bodies),
    (   sub_term(Term, Body),
        nonvar(Term),
        (   Term = (_;_)
        ;   Term == !
        ;   Term = findall(_, _, _)
        ;   Term = bagof(_, _, _)
        ;   Term = setof(_, _, _)
        ;   Term = member(_, _)
        ;   Term = between(_, _, _)
        )
    ).
