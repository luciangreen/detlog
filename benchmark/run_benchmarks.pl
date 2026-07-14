:- use_module('../prolog/detlog').

run :-
    Fixture = 'test/fixtures/sample_program.pl',
    benchmark_case('det_sum', det_sum([1,2,3,4,5], _)),
    benchmark_case('nondet_member', nondet_member(_, [a,b,c,d])),
    benchmark_case('if_then_else', if_then_else(1, _)),
    benchmark_case('safe_cut', safe_cut(1)),
    benchmark_case('side_effect', side_effect(ok)),
    format('benchmarks_complete fixture=~w~n', [Fixture]).

benchmark_case(Name, Goal) :-
    statistics(runtime, [Start|_]),
    findall(Goal, detlog('test/fixtures/sample_program.pl', Goal), Results),
    statistics(runtime, [End|_]),
    Duration is End - Start,
    length(Results, AnswerCount),
    format('benchmark ~w runtime_ms=~w answers=~w~n', [Name, Duration, AnswerCount]).

:- initialization(run, main).

