:- module(detlog_runtime,
          [guard/1,
           decision/2,
           call_indexed_goal/2,
           if_commit/3,
           first/2,
           once_det/1,
           loop_exit/1,
           cut_free_mode/1,
           detlog_commitment_audit/1]).

:- meta_predicate guard(0).
:- meta_predicate decision(+, 0).
:- meta_predicate if_commit(0, 0, 0).
:- meta_predicate first(0, -).
:- meta_predicate once_det(0).

guard(Goal) :-
    (   call(Goal)
    ->  true
    ;   fail
    ).

decision(Cases, Else) :-
    strip_module(Else, Caller, ElseGoal),
    decision_cases(Cases, Caller, ElseGoal).

decision_cases([], Caller, Else) :-
    call(Caller:Else).
decision_cases([case(Condition, Action)|Rest], Caller, Else) :-
    (   call(Caller:Condition)
    ->  call(Caller:Action)
    ;   decision_cases(Rest, Caller, Else)
    ).

call_indexed_goal(Index, Goals) :-
    nth1(Index, Goals, Goal),
    call(Goal).

if_commit(Cond, Then, Else) :-
    (   call(Cond)
    ->  call(Then)
    ;   call(Else)
    ).

first(Generator, Result) :-
    (   call(Generator)
    ->  Result = Generator
    ;   fail
    ).

once_det(Goal) :-
    (   call(Goal)
    ->  true
    ;   fail
    ).

loop_exit(Reason) :-
    nonvar(Reason).

cut_free_mode(strict).

detlog_commitment_audit([]).
