:- module(detlog_recursion, [recursion_properties/2]).

:- use_module(library(lists)).

recursion_properties(Clauses, Props) :-
    findall(
        recursion_info{
            predicate:PI,
            recursive:Recursive,
            tail_recursive:Tail,
            uncertain:Uncertain
        },
        (
            predicate_signature(Clauses, PI),
            recursion_of_predicate(Clauses, PI, Recursive, Tail, Uncertain)
        ),
        Raw
    ),
    sort(Raw, Props).

predicate_signature(Clauses, Name/Arity) :-
    member(clause_info{head:Head, body:_, line:_}, Clauses),
    functor(Head, Name, Arity).

recursion_of_predicate(Clauses, PI, Recursive, Tail, Uncertain) :-
    PI = Name/Arity,
    (   member(clause_info{head:Head, body:Body, line:_}, Clauses),
        functor(Head, Name, Arity),
        sub_term(Goal, Body),
        callable(Goal),
        functor(Goal, Name, Arity)
    ->  Recursive = true
    ;   Recursive = false
    ),
    (   Recursive == true,
        member(clause_info{head:Head2, body:Body2, line:_}, Clauses),
        functor(Head2, Name, Arity),
        tail_call(Body2, Name, Arity)
    ->  Tail = true
    ;   Tail = false
    ),
    (Recursive == true, Tail == false -> Uncertain = true ; Uncertain = false).

tail_call((_, Last), Name, Arity) :-
    !,
    tail_call(Last, Name, Arity).
tail_call(Goal, Name, Arity) :-
    callable(Goal),
    functor(Goal, Name, Arity).
