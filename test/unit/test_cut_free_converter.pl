:- begin_tests(detlog_cut_free_converter).
:- use_module('../../prolog/detlog_runtime').
:- use_module('../../prolog/detlog_codegen').
:- use_module('../../prolog/detlog_cuts').
:- use_module('../../prolog/detlog_reader').
:- use_module('../../prolog/detlog_analysis').

assert_det(Goal) :-
    findall(ok, Goal, Results),
    assertion(Results == [ok]).

assert_semidet(Goal) :-
    findall(ok, Goal, Results),
    length(Results, Len),
    assertion(Len =< 1).

test(decision_ordered_selection) :-
    assert_det(
        decision(
            [case(1 =:= 2, fail), case(1 =:= 1, true)],
            fail
        )
    ).

test(if_commit_uses_first_outcome) :-
    assert_det(if_commit(member(X, [a,b]), X = a, fail)).

test(first_returns_correlated_result) :-
    assert_det((first(member(X-Y, [1-a, 2-b]), _Result), X == 1, Y == a)).

test(source_term_kind_classification) :-
    assert_det(source_term_kind((:- dynamic(foo/1)), directive)),
    assert_det(source_term_kind((?- foo(X)), query)),
    assert_det(source_term_kind(foo(a), fact)),
    assert_det(source_term_kind((foo(X) :- bar(X)), rule)).

test(cut_classifier_no_cut) :-
    Clauses = [clause_info{head:p(1), body:true, line:1}],
    assert_det(cut_class_of_predicate(Clauses, p/1, no_cut)).

test(cut_classifier_safe_if_commit) :-
    Clauses = [clause_info{head:p(X), body:(X > 0, !, X = 1), line:1}],
    assert_det(cut_class_of_predicate(Clauses, p/1, safe_if_commit)).

test(cut_classifier_fallback_with_disjunction) :-
    Clauses = [clause_info{head:p(X), body:((X = 1 ; X = 2), !, X = 1), line:1}],
    assert_det(cut_class_of_predicate(Clauses, p/1, fallback_unsafe_cut)).

test(predicate_conversion_status_converted) :-
    Analysis = analysis{
        modes:[mode_info{predicate:p/1, mode:mode([inout]), determinism:det}],
        cuts:[cut_info{predicate:p/1, cut:no_cut}],
        effects:[effect_info{predicate:p/1, effect:pure}],
        recursion:[recursion_info{predicate:p/1, recursive:false, tail_recursive:false, uncertain:false}]
    },
    predicate_conversion_status(Analysis, p/1, converted, all_required_properties_proved).

test(predicate_conversion_status_fallback) :-
    absolute_file_name('test/fixtures/sample_program.pl', File),
    read_source_file(File, SourceInfo),
    analyse_source(SourceInfo, Analysis),
    predicate_conversion_status(Analysis, safe_cut/1, fallback, unsafe_cut).

test(semidet_helper_allows_failure) :-
    assert_semidet(member(_X, [])).

:- end_tests(detlog_cut_free_converter).
