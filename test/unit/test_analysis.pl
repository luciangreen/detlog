:- begin_tests(detlog_analysis).
:- use_module('../../prolog/detlog_reader').
:- use_module('../../prolog/detlog_analysis').
:- use_module('../../prolog/detlog_modes').
:- use_module('../../prolog/detlog_effects').

test(infers_dependencies_and_modes) :-
    absolute_file_name('test/fixtures/sample_program.pl', File),
    read_source_file(File, SourceInfo),
    analyse_source(SourceInfo, Analysis),
    once(member(_-_, Analysis.dependencies)),
    once(member(mode_info{predicate:det_sum/2, mode:_, determinism:_}, Analysis.modes)).

test(propagates_unproved_local_determinism) :-
    Clauses = [
        clause_info{head:helper(X), body:member(X, [a,b]), line:1},
        clause_info{head:middle(X), body:helper(X), line:2},
        clause_info{head:caller(X), body:middle(X), line:3}
    ],
    infer_modes(Clauses, Modes),
    once((member(Helper, Modes), Helper.predicate == helper/1)),
    assertion(Helper.determinism == semidet),
    once((member(Middle, Modes), Middle.predicate == middle/1)),
    assertion(Middle.determinism == unknown),
    once((member(Caller, Modes), Caller.predicate == caller/1)),
    assertion(Caller.determinism == unknown).

test(propagates_local_effects) :-
    Clauses = [
        clause_info{head:helper(X), body:writeln(X), line:1},
        clause_info{head:middle(X), body:helper(X), line:2},
        clause_info{head:caller(X), body:middle(X), line:3}
    ],
    classify_effects(Clauses, Effects),
    once((member(Middle, Effects), Middle.predicate == middle/1)),
    assertion(Middle.effect == io),
    once((member(Caller, Effects), Caller.predicate == caller/1)),
    assertion(Caller.effect == io).

:- end_tests(detlog_analysis).
