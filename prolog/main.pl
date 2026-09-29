% =============================================================================
% main.pl
% -----------------------------------------------------------------------------
% Single entry point for the whole Expert System.
%
% Usage:
%   swipl main.pl
%   (or: swipl -g start -t halt main.pl)
%
% This loads the knowledge base, both inference engines, the explanation
% facility and the HTTP server, then starts listening so the UI at
% frontend/index.html can be opened in a browser.
% =============================================================================

:- initialization(main).

:- [facts].
:- [rules].
:- [knowledge_base].
:- [inference_forward].
:- [inference_backward].
:- [explanation].
:- [server].

main :-
    catch(
        server:start_server,
        Error,
        ( print_message(error, Error),
          format("~nFATAL: could not start the server. See the error above.~n"),
          format("Common causes: the port is already in use (set PORT=8001 and retry),~n"),
          format("or SWI-Prolog's http libraries are not installed.~n"),
          halt(1)
        )
    ),
    % Block the main thread forever so the process stays alive whether run
    % interactively, in the background, under nohup, or with no stdin at
    % all - the HTTP server itself runs in its own thread(s).
    format("Press Ctrl+C to stop the server.~n~n"),
    thread_get_message(_keep_alive_forever).
