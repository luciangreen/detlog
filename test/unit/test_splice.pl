:- begin_tests(detlog_splice).
:- use_module('../../prolog/detlog_splice').

select_second(Row, Value) :-
    nth1(2, Row, Value).

test(splice_collect_order) :-
    splice_collect([[a, b], [1, 2]], Rows),
    assertion(Rows == [[a, 1], [a, 2], [b, 1], [b, 2]]).

test(splice_first) :-
    splice_first([[x, y], [1, 2]], Row),
    assertion(Row == [x, 1]).

test(splice_select) :-
    once(splice_select([[x], [1, 2]], select_second, Value)),
    assertion(Value == 1).

test(estimate_size) :-
    splice_estimated_size([[x, y], fixed(1), [a, b, c]], Size),
    assertion(Size =:= 6).

:- end_tests(detlog_splice).
