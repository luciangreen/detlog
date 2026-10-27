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
    sort(Raw, InitialEffects),
    propagate_effects(Clauses, InitialEffects, Effects).

propagate_effects(Clauses, Effects0, Effects) :-
    maplist(conservative_effect(Clauses, Effects0), Effects0, Effects1),
    (   Effects1 == Effects0
    ->  Effects = Effects1
    ;   propagate_effects(Clauses, Effects1, Effects)
    ).

conservative_effect(Clauses, Effects, Effect0, Effect) :-
    (   Effect0.effect == pure,
        calls_effectful_local_predicate(Clauses, Effect0.predicate, Effects)
    ->  Effect = Effect0.put(effect, io)
    ;   Effect = Effect0
    ).

calls_effectful_local_predicate(Clauses, PI, Effects) :-
    member(clause_info{head:Head, body:Body, line:_}, Clauses),
    functor(Head, Name, Arity),
    PI == Name/Arity,
    body_goal(Body, Goal),
    callable(Goal),
    functor(Goal, GoalName, GoalArity),
    GoalPI = GoalName/GoalArity,
    GoalPI \== PI,
    member(EffectInfo, Effects),
    EffectInfo.predicate == GoalPI,
    EffectInfo.effect == io.

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
