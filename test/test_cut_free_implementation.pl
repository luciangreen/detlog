:- begin_tests(detlog_cut_free_implementation).
:- use_module('../prolog/detlog').
:- use_module('../prolog/detlog_reader').
:- use_module('../prolog/detlog_analysis').
:- use_module('../prolog/detlog_diagnostics').

test(repository_is_operationally_cut_free) :-
    detlog_verify_cut_free.

test(source_cut_is_accepted_and_classified) :-
    absolute_file_name('test/fixtures/sample_program.pl', File),
    read_source_file(File, SourceInfo),
    analyse_source(SourceInfo, Analysis),
    once(member(cut_info{predicate:safe_cut/1, cut:Class}, Analysis.cuts)),
    Class \== no_cut.

test(quoted_cut_inspection_allowed) :-
    Body = (a, !, b),
    once(sub_term(!, Body)).

test(generated_code_contains_no_cut) :-
    absolute_file_name('test/fixtures/sample_program.pl', File),
    tmp_file_stream(text, OutFile, Stream),
    close(Stream),
    detlog_compile(File, [code(OutFile), fallback(silent)]),
    setup_call_cleanup(
        open(OutFile, read, ReadStream),
        read_string(ReadStream, _, Code),
        close(ReadStream)
    ),
    delete_file(OutFile),
    \+ sub_string(Code, _, _, _, "!").

test(fallback_is_reported_not_converted, [nondet]) :-
    absolute_file_name('test/fixtures/sample_program.pl', File),
    detlog_compile(File, [fallback(silent)]),
    diagnostics(Diagnostics),
    member(diagnostic{
               original_predicate:safe_cut/1,
               severity:fallback,
               generated_predicate:_,
               source_line:_,
               source_file:_,
               reason:unsafe_cut
           },
           Diagnostics).

:- end_tests(detlog_cut_free_implementation).
