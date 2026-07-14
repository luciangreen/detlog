:- module(detlog_runtime,
          [guard/1,
           decision/2,
           if_commit/3,
           first/2,
           once_det/1,
           loop_exit/1]).

guard(Goal) :-
    call(Goal).

decision(Index, Goals) :-
    nth1(Index, Goals, Goal),
    call(Goal).

if_commit(Cond, Then, Else) :-
    (   call(Cond)
    ->  call(Then)
    ;   call(Else)
    ).

first(Goal, Result) :-
    once(call(Goal)),
    Result = true.

once_det(Goal) :-
    once(call(Goal)).

loop_exit(Goal) :-
    once(call(Goal)).

