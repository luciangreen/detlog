det_sum([], 0).
det_sum([H|T], S) :-
    det_sum(T, Rest),
    S is H + Rest.

nondet_member(X, List) :-
    member(X, List).

multi_fact(a).
multi_fact(b).
multi_fact(b).

if_then_else(X, Y) :-
    (X > 0 -> Y = pos ; Y = nonpos).

safe_cut(X) :-
    X > 0, !.
safe_cut(_).

side_effect(X) :-
    writeln(X).

