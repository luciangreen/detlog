:- module(detlog_analysis, [analyse_source/2]).

:- use_module(library(lists)).
:- use_module(detlog_modes).
:- use_module(detlog_effects).
:- use_module(detlog_recursion).
:- use_module(detlog_cuts).

analyse_source(SourceInfo, analysis{
    dependencies:Dependencies,
    modes:Modes,
    effects:Effects,
    recursion:Recursion,
    cuts:Cuts
}) :-
    dependency_graph(SourceInfo.clauses, Dependencies),
    infer_modes(SourceInfo.clauses, Modes),
    classify_effects(SourceInfo.clauses, Effects),
    recursion_properties(SourceInfo.clauses, Recursion),
    classify_cuts(SourceInfo.clauses, Cuts).

dependency_graph(Clauses, Graph) :-
    findall(From-To,
            (
                member(clause_info{head:Head, body:Body, line:_}, Clauses),
                functor(Head, HName, HArity),
                From = HName/HArity,
                body_goal(Body, Goal),
                callable(Goal),
                \+ built_in_goal(Goal),
                functor(Goal, GName, GArity),
                To = GName/GArity
            ),
            Edges),
    sort(Edges, Graph).

body_goal((A, B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal((A ; B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal((A -> B), Goal) :-
    (body_goal(A, Goal) ; body_goal(B, Goal)).
body_goal(\+ A, Goal) :-
    body_goal(A, Goal).
body_goal(Goal, Goal) :-
    callable(Goal).

built_in_goal(Goal) :-
    (   predicate_property(Goal, built_in)
    ->  true
    ;   Goal = _:_
    ).
