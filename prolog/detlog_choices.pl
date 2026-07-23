:- module(detlog_choices,
          [cp/1, normalize_cp/2, member_cp/2, validate_cp/1]).

:- use_module(library(error)).

cp(Choices) :-
    validate_cp(Choices).

validate_cp(cp(_)).
validate_cp(Choices) :-
    (   is_list(Choices)
    ->  true
    ;   throw(error(type_error(choice_packet, Choices), _))
    ).

normalize_cp(cp(Choices), Normalized) :-
    normalize_cp(Choices, Normalized).
normalize_cp(Choices, Normalized) :-
    must_be(list, Choices),
    maplist(normalize_item, Choices, Items),
    append(Items, Normalized).

normalize_item(cp(Nested), Flat) :-
    normalize_cp(Nested, Flat).
normalize_item(Item, [Item]).

member_cp(Value, Packet) :-
    normalize_cp(Packet, Items),
    member(Value, Items).
