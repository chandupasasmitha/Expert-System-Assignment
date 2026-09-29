% =============================================================================
% server.pl
% -----------------------------------------------------------------------------
% Backend / API layer. A small SWI-Prolog HTTP server that:
%   (a) serves the static frontend (HTML/CSS/JS) directly, and
%   (b) exposes a JSON API that lets the frontend collect user input, convert
%       it to facts, run forward or backward chaining, and get back the
%       conclusion PLUS the full reasoning trace / explanation.
%
% This keeps "Frontend UI -> Backend/API -> SWI-Prolog Expert System ->
% Knowledge Base + Inference Engine" all inside a single, simple, reliable
% process: one command (`swipl main.pl`) starts everything, nothing else to
% install or configure.
% =============================================================================

:- module(server, [start_server/0, start_server/1]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_error)).
:- use_module(library(http/http_parameters)).
:- use_module(library(option)).
:- use_module(library(yall)).

:- use_module(knowledge_base).
:- use_module(facts).
:- use_module(rules).
:- use_module(inference_forward).
:- use_module(inference_backward).
:- use_module(explanation).

% -----------------------------------------------------------------------------
% Static frontend
% -----------------------------------------------------------------------------
:- dynamic frontend_dir/1.
:- dynamic server_source_dir/1.

:- prolog_load_context(directory, Dir), assertz(server_source_dir(Dir)).

set_frontend_dir(Dir) :- retractall(frontend_dir(_)), assertz(frontend_dir(Dir)).

:- http_handler(root(.), serve_index, []).
:- http_handler(root('index.html'), serve_index, []).
:- http_handler(root('css/'), serve_static('css'), [prefix]).
:- http_handler(root('js/'), serve_static('js'), [prefix]).

serve_index(_Request) :-
    frontend_dir(Dir),
    atomic_list_concat([Dir, '/index.html'], Path),
    reply_file_raw(Path, 'text/html; charset=UTF-8').

serve_static(SubDir, Request) :-
    frontend_dir(Dir),
    memberchk(path(ReqPath), Request),
    file_base_name(ReqPath, FileName),
    atomic_list_concat([Dir, '/', SubDir, '/', FileName], Path),
    ( sub_atom(FileName, _, _, 0, '.css') -> Mime = 'text/css; charset=UTF-8'
    ; sub_atom(FileName, _, _, 0, '.js')  -> Mime = 'application/javascript; charset=UTF-8'
    ; Mime = 'application/octet-stream'
    ),
    reply_file_raw(Path, Mime).

% Manually stream a file's bytes as the HTTP response, bypassing
% library(http/http_files)'s access_file/2 check (which this sandboxed
% environment's syscall filter rejects even for files that DO open() fine).
reply_file_raw(Path, Mime) :-
    ( exists_file(Path)
    -> setup_call_cleanup(
         open(Path, read, Stream, [encoding(utf8)]),
         read_string(Stream, _, Content),
         close(Stream)
       ),
       format("Content-type: ~w~n~n", [Mime]),
       format("~w", [Content])
    ;  format("Content-type: text/plain~n~n"),
       format("404 Not Found: ~w~n", [Path])
    ).

% -----------------------------------------------------------------------------
% API: knowledge base introspection (for the "Knowledge Base" demo page)
% -----------------------------------------------------------------------------
:- http_handler(root('api/facts'), api_facts, []).
:- http_handler(root('api/rules'), api_rules, []).
:- http_handler(root('api/goals'), api_goals, []).
:- http_handler(root('api/examples'), api_examples, []).
:- http_handler(root('api/forward'), api_forward, [methods([post,options])]).
:- http_handler(root('api/backward'), api_backward, [methods([post,options])]).

api_facts(_Request) :-
    safe_json(( findall(
        _{id:Id, term:TermStr, meaning:Meaning, source:SourceStr},
        ( facts:fact_doc(Id, Term, Meaning, SourceKey),
          term_to_atom(Term, TermStr),
          source_str(SourceKey, SourceStr)
        ),
        FactList
    ), length(FactList, N), reply_json_dict(_{ok: true, count: N, facts: FactList}) )).

api_rules(_Request) :-
    safe_json(( findall(
        _{id:Id, level:Level, conditions:CondStrs, conclusion:ConclStr,
          explanation:Expl, source:SourceStr},
        ( rules:rule(Id, Conds, Concl, Expl),
          rules:rule_level(Id, Level),
          maplist(term_to_atom, Conds, CondStrs),
          term_to_atom(Concl, ConclStr),
          findall(S, (rules:rule_source(Id, SK), source_str(SK, S)), Srcs),
          atomic_list_concat(Srcs, ' | ', SourceStr)
        ),
        RuleList
    ), reply_json_dict(_{ok: true, rules: RuleList}) )).

api_goals(_Request) :-
    safe_json(( findall(_{id:D, label:Label}, (facts:disease_info(D,Label,_)), Diseases),
      findall(_{id:A, label:Label2}, (facts:action_info(A,Label2)), Actions),
      reply_json_dict(_{ok:true, diseases:Diseases, actions:Actions})
    )).

source_str(SourceKey, Str) :-
    ( facts:source(SourceKey, Title, Org, Year, Url)
    -> format(atom(Str), "~w - ~w (~w). ~w", [Title, Org, Year, Url])
    ;  Str = "Unknown source"
    ).

% -----------------------------------------------------------------------------
% API: predefined demo scenarios (Testing/Demo page)
% -----------------------------------------------------------------------------
api_examples(_Request) :-
    safe_json(( examples(List), reply_json_dict(_{ok:true, examples:List}) )).

examples([
  _{name:"Classic Dengue (non-severe)",
    description:"Fever, severe headache, retro-orbital pain, joint pain, mosquito exposure - no bleeding.",
    fact_ids:[f01,f07,f08,f09,f31]},
  _{name:"Severe Dengue (warning signs)",
    description:"Same as above, plus persistent vomiting and bleeding gums.",
    fact_ids:[f01,f07,f08,f09,f31,f17,f14]},
  _{name:"Malaria after endemic travel",
    description:"Fever, chills and sweats, recent travel to a malaria area.",
    fact_ids:[f01,f27,f35]},
  _{name:"Typhoid fever",
    description:"Prolonged fever, abdominal pain, rose spots, unsafe food/water exposure.",
    fact_ids:[f05,f18,f21,f33]},
  _{name:"COVID-19 with known contact",
    description:"Cough, sore throat, runny nose, sneezing, loss of smell/taste, contact with a case.",
    fact_ids:[f23,f22,f25,f26,f28,f34]},
  _{name:"Influenza (flu)",
    description:"Fever, muscle pain, cough, sore throat, runny nose, sneezing - no loss of smell/taste.",
    fact_ids:[f01,f11,f23,f22,f25,f26]},
  _{name:"Common cold",
    description:"Runny nose, sneezing, sore throat, cough - no fever.",
    fact_ids:[f25,f26,f22,f23]},
  _{name:"Chikungunya",
    description:"Fever, severe joint pain, skin rash, mosquito exposure.",
    fact_ids:[f01,f10,f13,f31]},
  _{name:"Leptospirosis",
    description:"Fever, calf muscle pain, jaundice, conjunctivitis, contaminated water exposure.",
    fact_ids:[f01,f12,f30,f29,f32]},
  _{name:"Ambiguous prolonged fever (fallback)",
    description:"Long-lasting fever only, no other distinguishing symptoms - tests the fallback rule.",
    fact_ids:[f01,f05]},
  _{name:"Fever after malaria-area travel (safety net)",
    description:"Fever and recent travel to a malaria area, but no chills/sweats - tests safety-net rule r34.",
    fact_ids:[f01,f35]},
  _{name:"No symptoms (edge case)",
    description:"Empty / no symptoms selected - no rule fires and the system says so.",
    fact_ids:[]}
]).

% -----------------------------------------------------------------------------
% API: forward chaining
% POST body: {"fact_ids": ["f01","f07", ...]}
% -----------------------------------------------------------------------------
api_forward(Request) :-
    ( option(method(options), Request)
    -> format('Content-type: text/plain~n~n')
    ;  safe_json((
         http_read_json_dict(Request, Body),
         get_dict(fact_ids, Body, FactIdsIn0),
         ( FactIdsIn0 == [] -> FactIdsIn = [] ; maplist(atom_string_safe, FactIdsIn, FactIdsIn0) ),
         resolve_fact_ids(FactIdsIn, InitialFacts, UnknownIds),
         forward_chain(InitialFacts, FinalFacts, Trace),
         explain_forward(Trace, InitialFacts, Steps, summary(FactLabels, RuleIds)),
         extract_conclusions(FinalFacts, conclusions(Diseases, Actions)),
         maplist(disease_json, Diseases, DiseaseJson),
         maplist(action_json, Actions, ActionJson),
         maplist(step_json, Steps, StepsJson),
         length(FinalFacts, NWM),
         reply_json_dict(_{
             ok: true,
             unknown_fact_ids: UnknownIds,
             facts_used: FactLabels,
             rules_fired: RuleIds,
             reasoning_steps: StepsJson,
             suspected_diseases: DiseaseJson,
             recommended_actions: ActionJson,
             total_facts_in_working_memory: NWM
         })
       ))
    ).

resolve_fact_ids([], [], []).
resolve_fact_ids([Id|Rest], Terms, Unknown) :-
    ( knowledge_base:fact_id_term(Id, Term)
    -> Terms = [Term|Terms1], resolve_fact_ids(Rest, Terms1, Unknown)
    ;  resolve_fact_ids(Rest, Terms, Unknown1), Unknown = [Id|Unknown1]
    ).

atom_string_safe(Atom, Str) :- atom_string(Atom, Str).

step_json(step(N, RuleID, CondLabels, ConclLabel, Expl),
          _{step_number:N, rule_id:RuleID, conditions:CondLabels,
            conclusion:ConclLabel, rule_explanation:Expl}).

disease_json(D, _{id:D, label:Label, description:Desc}) :-
    ( facts:disease_info(D, Label, Desc) -> true ; Label = D, Desc = "" ).

action_json(A, _{id:A, label:Label}) :-
    ( facts:action_info(A, Label) -> true ; Label = A ).

% -----------------------------------------------------------------------------
% API: backward chaining
% POST body: {"fact_ids":[...], "goal_type":"disease"|"action", "goal_id":"dengue"}
% -----------------------------------------------------------------------------
api_backward(Request) :-
    ( option(method(options), Request)
    -> format('Content-type: text/plain~n~n')
    ;  safe_json((
         http_read_json_dict(Request, Body),
         get_dict(fact_ids, Body, FactIdsIn0),
         ( FactIdsIn0 == [] -> FactIdsIn = [] ; maplist(atom_string_safe, FactIdsIn, FactIdsIn0) ),
         get_dict(goal_type, Body, GoalTypeStr),
         get_dict(goal_id, Body, GoalIdStr),
         atom_string(GoalType, GoalTypeStr),
         atom_string(GoalId, GoalIdStr),
         resolve_fact_ids(FactIdsIn, InitialFacts, UnknownIds),
         build_goal(GoalType, GoalId, Goal),
         backward_chain(Goal, InitialFacts, Result),
         explain_backward(Result, Goal, Lines),
         ( Result = success(_) -> Proven = true ; Proven = false ),
         maplist([L,_{text:L}]>>true, Lines, LinesJson),
         reply_json_dict(_{
             ok: true,
             unknown_fact_ids: UnknownIds,
             goal_type: GoalType,
             goal_id: GoalId,
             proven: Proven,
             reasoning_lines: LinesJson
         })
       ))
    ).

build_goal(disease, D, suspected(D)).
build_goal(action, A, recommend(A)).

% -----------------------------------------------------------------------------
% Robust error handling. Never let an API call crash the server;
% always return a well-formed JSON error with a clear message.
% -----------------------------------------------------------------------------
safe_json(Goal) :-
    catch(
        ( call(Goal) -> true ; reply_json_dict(_{ok:false, error:"Request could not be processed (no result)."}, [status(400)]) ),
        Error,
        ( message_to_atom(Error, Msg),
          reply_json_dict(_{ok:false, error:Msg}, [status(400)]) )
    ).

message_to_atom(Error, Msg) :-
    ( catch(format(atom(Msg), "~w", [Error]), _, fail) -> true ; Msg = "Unknown server error" ).

term_to_atom(Term, Atom) :- format(atom(Atom), "~w", [Term]).

% -----------------------------------------------------------------------------
% start_server(+Port)
% -----------------------------------------------------------------------------
start_server(Port) :-
    server_source_dir(ThisDir),
    atomic_list_concat([ThisDir, '/../frontend'], FrontendDir0),
    absolute_file_name(FrontendDir0, FrontendDir),
    set_frontend_dir(FrontendDir),
    http_server(http_dispatch, [port(Port)]),
    format("~n=========================================================~n"),
    format("Febrile Illness Advisory Expert System - server started~n"),
    format("Open your browser at:  http://localhost:~w/~n", [Port]),
    format("=========================================================~n~n").

start_server :-
    ( getenv('PORT', PortAtom) -> atom_number(PortAtom, Port) ; Port = 8000 ),
    start_server(Port).
