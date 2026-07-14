:- module(detlog_loops,
          [loop_member/2,
           loop_between/3,
           loop_findall/3,
           loop_bagof/3,
           loop_setof/3]).

loop_member(Value, List) :-
    member(Value, List).

loop_between(Low, High, Value) :-
    between(Low, High, Value).

loop_findall(Template, Goal, Results) :-
    findall(Template, Goal, Results).

loop_bagof(Template, Goal, Results) :-
    bagof(Template, Goal, Results).

loop_setof(Template, Goal, Results) :-
    setof(Template, Goal, Results).

