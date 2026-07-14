:- begin_tests(detlog_repl).
:- use_module('../../prolog/detlog').

fixture_path(File) :-
    absolute_file_name('test/fixtures/sample_program.pl', File).

test(detlog_two_arity_executes) :-
    fixture_path(File),
    once(detlog(File, det_sum([1,2,3], S))),
    assertion(S =:= 6).

test(code_output_file) :-
    fixture_path(File),
    tmp_file_stream(text, OutFile, Stream),
    close(Stream),
    detlog_compile(File, [code(OutFile)]),
    exists_file(OutFile),
    setup_call_cleanup(
        open(OutFile, read, ReadStream),
        read_string(ReadStream, _, Code),
        close(ReadStream)
    ),
    sub_string(Code, _, _, _, "det_sum(A,B) :-"),
    delete_file(OutFile).

:- end_tests(detlog_repl).
