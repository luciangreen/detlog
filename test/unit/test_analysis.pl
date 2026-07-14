:- begin_tests(detlog_analysis).
:- use_module('../../prolog/detlog_reader').
:- use_module('../../prolog/detlog_analysis').

test(infers_dependencies_and_modes) :-
    absolute_file_name('test/fixtures/sample_program.pl', File),
    read_source_file(File, SourceInfo),
    analyse_source(SourceInfo, Analysis),
    once(member(_-_, Analysis.dependencies)),
    once(member(mode_info{predicate:det_sum/2, mode:_, determinism:_}, Analysis.modes)).

:- end_tests(detlog_analysis).
