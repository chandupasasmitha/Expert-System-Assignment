% =============================================================================
% knowledge_base.pl
% -----------------------------------------------------------------------------
% Aggregates the static knowledge base (facts.pl) and rule base (rules.pl)
% into a single module, and provides small helper predicates used across the
% inference engines, explanation facility and API layer.
% =============================================================================

:- module(knowledge_base, [
    all_input_fact_ids/1,
    all_rule_ids/1,
    fact_label/2,
    condition_label/2,
    disease_label/2,
    action_label/2,
    num_facts/1,
    num_rules/1,
    fact_id_term/2,
    all_disease_ids/1,
    all_action_ids/1
]).

:- use_module(facts).
:- use_module(rules).

% Every documented input fact id, e.g. [f01, f02, ...]
all_input_fact_ids(Ids) :-
    findall(Id, facts:fact_doc(Id, _, _, _), Ids).

% Every rule id, e.g. [r01, r02, ...]
all_rule_ids(Ids) :-
    findall(Id, rules:rule(Id, _, _, _), Ids).

num_facts(N) :- all_input_fact_ids(Ids), length(Ids, N).
num_rules(N) :- all_rule_ids(Ids), length(Ids, N).

% fact_label(Term, Label) - human-readable label for an input fact term,
% falls back to a generated label if not explicitly documented.
fact_label(Term, Label) :-
    facts:fact_doc(_, Term, Label0, _), !,
    Label = Label0.
fact_label(Term, Label) :-
    format(atom(Label), "~w", [Term]).

% condition_label(Cond, Label) - human readable label for ANY condition term
% that can appear in a rule (positive facts, derived facts, or negations).
condition_label(not(Cond), Label) :- !,
    condition_label(Cond, Inner),
    format(atom(Label), "NOT (~w)", [Inner]).
condition_label(derived(D), Label) :- !,
    format(atom(Label), "[derived] ~w", [D]).
condition_label(suspected(D), Label) :- !,
    disease_label(D, Name),
    format(atom(Label), "Suspected: ~w", [Name]).
condition_label(recommend(A), Label) :- !,
    action_label(A, Text),
    format(atom(Label), "Recommendation: ~w", [Text]).
condition_label(Cond, Label) :-
    fact_label(Cond, Label).

disease_label(Disease, Label) :-
    facts:disease_info(Disease, Label, _), !.
disease_label(Disease, Disease).

action_label(Action, Label) :-
    facts:action_info(Action, Label), !.
action_label(Action, Action).

% fact_id_term(+Id, -Term) - map a JSON-facing fact id (e.g. f01) to its
% Prolog condition term (e.g. has_symptom(fever)). This is the single point
% of translation between the frontend's fact checkboxes and working memory.
fact_id_term(Id, Term) :-
    facts:fact_doc(Id, Term, _, _).

all_disease_ids(Ids) :-
    findall(D, facts:disease_info(D, _, _), Ids).

all_action_ids(Ids) :-
    findall(A, facts:action_info(A, _), Ids).
