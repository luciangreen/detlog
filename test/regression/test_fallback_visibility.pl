:- begin_tests(detlog_fallback_visibility).
:- use_module('../../prolog/detlog').
:- use_module('../../prolog/detlog_diagnostics').

fixture_path(File) :-
    once(absolute_file_name('test/fixtures/sample_program.pl', File)).

test(fallback_recorded_for_nondet_predicate, [nondet]) :-
    fixture_path(File),
    detlog_compile(File, [fallback(silent)]),
    diagnostics(Diagnostics),
    once(member(diagnostic{
               original_predicate:nondet_member/2,
               severity:fallback,
               generated_predicate:_,
               source_line:_,
               source_file:_,
               reason:_
           },
           Diagnostics)).

:- end_tests(detlog_fallback_visibility).
