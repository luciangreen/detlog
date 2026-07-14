:- begin_tests(detlog_equivalence).
:- use_module('../../prolog/detlog').

fixture_path(File) :-
    absolute_file_name('test/fixtures/sample_program.pl', File).

source_answers(File, Goal, Answers) :-
    user:load_files(File, [silent(true)]),
    findall(Goal, user:Goal, Answers).

generated_answers(File, Goal, Answers) :-
    findall(Goal, detlog(File, Goal, [fallback(silent)]), Answers).

test(member_equivalence_order_and_duplicates) :-
    fixture_path(File),
    source_answers(File, multi_fact(X), Source),
    generated_answers(File, multi_fact(X), Generated),
    assertion(Generated == Source).

test(nondet_member_equivalence) :-
    fixture_path(File),
    source_answers(File, nondet_member(X, [a,b]), Source),
    generated_answers(File, nondet_member(X, [a,b]), Generated),
    assertion(Generated == Source).

:- end_tests(detlog_equivalence).
