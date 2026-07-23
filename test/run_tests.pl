:- use_module(library(plunit)).
:- asserta(user:file_search_path(detlog, 'prolog')).
:- use_module(detlog(detlog)).
:- ensure_loaded('unit/test_choices.pl').
:- ensure_loaded('unit/test_splice.pl').
:- ensure_loaded('unit/test_analysis.pl').
:- ensure_loaded('unit/test_cut_free_converter.pl').
:- ensure_loaded('integration/test_repl.pl').
:- ensure_loaded('equivalence/test_equivalence.pl').
:- ensure_loaded('regression/test_fallback_visibility.pl').
:- ensure_loaded('test_cut_free_implementation.pl').
