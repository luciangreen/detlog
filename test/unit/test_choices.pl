:- begin_tests(detlog_choices).
:- use_module('../../prolog/detlog_choices').

test(normalize_nested_packets) :-
    normalize_cp([a, cp([b, cp([c])])], Values),
    assertion(Values == [a, b, c]).

test(member_cp_matches_nested) :-
    member_cp(c, [a, cp([b, cp([c])])]).

test(validate_cp_error, [throws(error(type_error(choice_packet, x), _))]) :-
    validate_cp(x).

:- end_tests(detlog_choices).

