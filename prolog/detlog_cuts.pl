:- module(detlog_cuts,
          [classify_cuts/2,
           cut_class_of_predicate/3,
           select_highest_priority/3]).

:- use_module(library(lists)).
:- use_module(detlog_runtime).

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

cut_class_of_predicate(Clauses, PI, Class) :-
    classify_cut_conditions(Clauses, PI, Conditions),
    select_cut_class(Conditions, Class).

classify_cut_conditions(Clauses, Name/Arity, cut_conditions{
    contains_cut:ContainsCut,
    matches_if_commit:MatchesIfCommit,
    contains_disjunction:ContainsDisjunction,
    contains_meta_call:ContainsMetaCall,
    contains_precommit_effect:ContainsPrecommitEffect
}) :-
    findall(Body,
            (member(clause_info{head:Head, body:Body, line:_}, Clauses),
             functor(Head, Name, Arity)),
            Bodies),
    contains_cut(Bodies, ContainsCut),
    matches_if_commit(Bodies, MatchesIfCommit),
    contains_disjunction(Bodies, ContainsDisjunction),
    contains_meta_call(Bodies, ContainsMetaCall),
    contains_precommit_effect(Bodies, ContainsPrecommitEffect).

contains_cut(Bodies, true) :-
    member(Body, Bodies),
    sub_term(Term, Body),
    Term == !.
contains_cut(Bodies, false) :-
    \+ (member(Body, Bodies),
        sub_term(Term, Body),
        Term == !).

matches_if_commit(Bodies, true) :-
    (   member((Cond, !, Then), Bodies),
        \+ contains_disjunction_term(Cond),
        \+ contains_disjunction_term(Then)
    ;   member((Cond, !), Bodies),
        \+ contains_disjunction_term(Cond)
    ).
matches_if_commit(Bodies, false) :-
    \+ ( (member((Cond, !, Then), Bodies),
          \+ contains_disjunction_term(Cond),
          \+ contains_disjunction_term(Then))
       ; (member((Cond, !), Bodies),
          \+ contains_disjunction_term(Cond))
       ).

contains_disjunction(Bodies, true) :-
    member(Body, Bodies),
    sub_term(Term, Body),
    nonvar(Term),
    Term = (_;_).
contains_disjunction(Bodies, false) :-
    \+ (member(Body, Bodies),
        sub_term(Term, Body),
        nonvar(Term),
        Term = (_;_)).

contains_meta_call(Bodies, true) :-
    member(Body, Bodies),
    (sub_term(Term, Body), nonvar(Term), Term = call(_)
    ;sub_term(Term, Body), nonvar(Term), Term = apply(_,_)).
contains_meta_call(Bodies, false) :-
    \+ (member(Body, Bodies),
        (sub_term(Term, Body), nonvar(Term), Term = call(_)
        ;sub_term(Term, Body), nonvar(Term), Term = apply(_,_))).

contains_disjunction_term(Term) :-
    sub_term(SubTerm, Term),
    nonvar(SubTerm),
    SubTerm = (_;_).

contains_precommit_effect(Bodies, true) :-
    (member((Cond, !, _Then), Bodies) ; member((Cond, !), Bodies)),
    sub_term(Goal, Cond),
    callable(Goal),
    Goal =.. [Functor|_],
    memberchk(Functor, [write, writeln, format, read, open, close, assertz, retract, nb_setval]).
contains_precommit_effect(Bodies, false) :-
    \+ ((member((Cond, !, _Then), Bodies) ; member((Cond, !), Bodies)),
        sub_term(Goal, Cond),
        callable(Goal),
        Goal =.. [Functor|_],
        memberchk(Functor, [write, writeln, format, read, open, close, assertz, retract, nb_setval])).

select_cut_class(Conditions, Class) :-
    applicable_cut_classes(Conditions, Applicable),
    cut_class_priority(Priority),
    select_highest_priority(Priority, Applicable, Class).

applicable_cut_classes(Conditions, Classes) :-
    findall(Class,
            cut_class_rule(Conditions, Class),
            Raw),
    (   Raw == []
    ->  Classes = [fallback_unsafe_cut]
    ;   sort(Raw, Classes)
    ).

cut_class_rule(Conditions, no_cut) :-
    Conditions.contains_cut == false.
cut_class_rule(Conditions, safe_if_commit) :-
    Conditions.contains_cut == true,
    Conditions.matches_if_commit == true,
    Conditions.contains_disjunction == false,
    Conditions.contains_meta_call == false,
    Conditions.contains_precommit_effect == false.
cut_class_rule(_Conditions, fallback_unsafe_cut).

cut_class_priority([no_cut, safe_if_commit, fallback_unsafe_cut]).

select_highest_priority(PriorityOrder, ApplicableClasses, SelectedClass) :-
    validate_classes(PriorityOrder, ApplicableClasses),
    decision(
        [
            case(first_applicable(PriorityOrder, ApplicableClasses, Class),
                 SelectedClass = Class)
        ],
        throw(error(no_applicable_cut_class(ApplicableClasses), _))
    ).

first_applicable([Class|_], ApplicableClasses, Class) :-
    memberchk(Class, ApplicableClasses).
first_applicable([_|Rest], ApplicableClasses, Class) :-
    first_applicable(Rest, ApplicableClasses, Class).

validate_classes(PriorityOrder, ApplicableClasses) :-
    (   member(Class, ApplicableClasses),
        \+ memberchk(Class, PriorityOrder)
    ->  throw(error(unknown_cut_class(Class), _))
    ;   true
    ).
