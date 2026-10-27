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
    sort(Raw, InitialModes),
    propagate_determinism(Clauses, InitialModes, Modes).

propagate_determinism(Clauses, Modes0, Modes) :-
    maplist(conservative_mode(Clauses, Modes0), Modes0, Modes1),
    (   Modes1 == Modes0
    ->  Modes = Modes1
    ;   propagate_determinism(Clauses, Modes1, Modes)
    ).

conservative_mode(Clauses, Modes, Mode0, Mode) :-
    (   Mode0.determinism == det,
        calls_unproved_local_predicate(Clauses, Mode0.predicate, Modes)
    ->  Mode = Mode0.put(determinism, unknown)
    ;   Mode = Mode0
    ).

calls_unproved_local_predicate(Clauses, PI, Modes) :-
    member(clause_info{head:Head, body:Body, line:_}, Clauses),
    functor(Head, Name, Arity),
    PI == Name/Arity,
    body_goal(Body, Goal),
    callable(Goal),
    functor(Goal, GoalName, GoalArity),
    GoalPI = GoalName/GoalArity,
    GoalPI \== PI,
    member(ModeInfo, Modes),
    ModeInfo.predicate == GoalPI,
    ModeInfo.determinism \== det.

body_goal((A, B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal((A ; B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal((A -> B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal((A *-> B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal(\+ A, Goal) :-
    body_goal(A, Goal).
body_goal(Goal, Goal) :-
    callable(Goal).

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
        ;   Term = call(_)
        )
    ).
