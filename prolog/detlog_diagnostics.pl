:- module(detlog_diagnostics,
          [clear_diagnostics/0,
           add_diagnostic/1,
           diagnostics/1]).

:- dynamic diagnostic/1.

clear_diagnostics :-
    retractall(diagnostic(_)).

add_diagnostic(Diagnostic) :-
    assertz(diagnostic(Diagnostic)).

diagnostics(List) :-
    findall(D, diagnostic(D), List).

