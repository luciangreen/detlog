:- module(detlog_splice,
          [splice/2,
           splice_collect/2,
           splice_each/2,
           splice_first/2,
           splice_select/3,
           splice_estimated_size/2]).

:- meta_predicate splice_select(+, 2, -).

:- use_module(library(lists)).
:- use_module(detlog_choices).
:- use_module(detlog_runtime).

splice([], [[]]).
splice([Packet|Rest], Rows) :-
    packet_items(Packet, Items),
    splice(Rest, RestRows),
    findall([Item|Row],
            (member(Item, Items), member(Row, RestRows)),
            Rows).

splice_collect(PacketSpecs, Rows) :-
    splice(PacketSpecs, Rows).

splice_each(PacketSpecs, Row) :-
    splice(PacketSpecs, Rows),
    member(Row, Rows).

splice_first(PacketSpecs, Row) :-
    once_det(splice_each(PacketSpecs, Row)).

splice_select(PacketSpecs, Selector, Value) :-
    splice_each(PacketSpecs, Row),
    call(Selector, Row, Value).

splice_estimated_size(PacketSpecs, Size) :-
    maplist(packet_count, PacketSpecs, Counts),
    foldl(multiply, Counts, 1, Size).

packet_count(Packet, Count) :-
    packet_items(Packet, Items),
    length(Items, Count).

packet_items(Packet, Items) :-
    (   Packet = fixed(Value)
    ->  Items = [Value]
    ;   normalize_cp(Packet, Items)
    ).

multiply(X, Acc, Y) :- Y is Acc * X.
