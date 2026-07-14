:- module(detlog_cache,
          [cache_key/4,
           cache_lookup/2,
           cache_store/2,
           cache_clear/0]).

:- dynamic cache_entry/2.

cache_key(File, Hash, FallbackPolicy, key(File, Hash, FallbackPolicy)).

cache_lookup(Key, Value) :-
    cache_entry(Key, Value).

cache_store(Key, Value) :-
    retractall(cache_entry(Key, _)),
    assertz(cache_entry(Key, Value)).

cache_clear :-
    retractall(cache_entry(_, _)).

