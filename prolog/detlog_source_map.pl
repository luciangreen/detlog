:- module(detlog_source_map,
          [clear_source_map/0,
           record_source_map/1,
           source_map/1,
           source_map/2]).

:- dynamic source_map_entry/1.

clear_source_map :-
    retractall(source_map_entry(_)).

record_source_map(Map) :-
    assertz(source_map_entry(Map)).

source_map(Map) :-
    source_map_entry(Map).

source_map(Predicate, Map) :-
    source_map_entry(Map),
    Map.predicate == Predicate.

