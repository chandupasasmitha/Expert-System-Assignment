% =============================================================================
% explanation.pl
% -----------------------------------------------------------------------------
% The EXPLANATION FACILITY (Section 4 of the assignment guidelines).
%
% Turns the raw trace produced by the forward-chaining engine, or the raw
% proof tree produced by the backward-chaining engine, into:
%   - a list of plain-English reasoning steps ("Reasoning Chain")
%   - the flat list of facts that contributed ("Facts Used")
%   - the flat list of rule IDs that were applied ("Rules Applied")
%   - the final conclusion(s) in friendly text
% so the UI never just shows a bare answer - it always shows how the system
% got there.
% =============================================================================

:- module(explanation, [
    explain_forward/4,
    explain_backward/3,
    extract_conclusions/2
]).

:- use_module(library(yall)).
:- use_module(knowledge_base).
:- use_module(facts).

% -----------------------------------------------------------------------------
% explain_forward(+Trace, +InitialFacts, -Steps, -Summary)
%   Trace        : list of fired(RuleID, Conds, Concl) from forward_chain/3,
%                  in firing order.
%   Steps        : list of step(Index, RuleID, ConditionLabels, ConclusionLabel,
%                                RuleExplanation) - one per fired rule, ready
%                  to render as the reasoning chain in the UI.
%   Summary      : summary(FactsUsedLabels, RuleIdsApplied)
% -----------------------------------------------------------------------------
explain_forward(Trace, InitialFacts, Steps, summary(FactsUsedLabels, RuleIds)) :-
    explain_forward_steps(Trace, 1, Steps),
    findall(RID, member(fired(RID,_,_), Trace), RuleIds),
    maplist([F,L]>>(knowledge_base:fact_label(F,L)), InitialFacts, FactsUsedLabels).

explain_forward_steps([], _, []).
explain_forward_steps([fired(RuleID, Conds, Concl)|Rest], N, [Step|StepsRest]) :-
    maplist([C,L]>>(knowledge_base:condition_label(C,L)), Conds, CondLabels),
    conclusion_label(Concl, ConclLabel),
    ( rules:rule(RuleID, _, _, Expl) -> true ; Expl = "" ),
    Step = step(N, RuleID, CondLabels, ConclLabel, Expl),
    N1 is N + 1,
    explain_forward_steps(Rest, N1, StepsRest).

conclusion_label(suspected(D), Label) :- !,
    knowledge_base:disease_label(D, Name),
    format(atom(Label), "Suspected: ~w", [Name]).
conclusion_label(recommend(A), Label) :- !,
    knowledge_base:action_label(A, Text),
    format(atom(Label), "Recommendation: ~w", [Text]).
conclusion_label(derived(D), Label) :- !,
    format(atom(Label), "[derived pattern] ~w", [D]).
conclusion_label(Other, Label) :-
    format(atom(Label), "~w", [Other]).

% -----------------------------------------------------------------------------
% extract_conclusions(+FinalFacts, -Conclusions)
%   Conclusions = conclusions(SuspectedDiseases, RecommendedActions)
%   pulled out of the final working memory produced by forward_chain/3.
% -----------------------------------------------------------------------------
extract_conclusions(FinalFacts, conclusions(Diseases, Actions)) :-
    findall(D, member(suspected(D), FinalFacts), Diseases),
    findall(A, member(recommend(A), FinalFacts), Actions).

% -----------------------------------------------------------------------------
% explain_backward(+Result, +Goal, -Lines)
%   Result : success(ProofTree) | failure(Goal, Attempts) from backward_chain/3
%   Lines  : flat list of indented text lines describing the full recursive
%            reasoning chain, e.g.
%              "Goal: Suspected: Dengue Fever"
%              "  Required by Rule r13: ..."
%              "    To prove derived(dengue_pattern):"
%              "      Required by Rule r05: ..."
%              "        fever: KNOWN (reported by user)"
%              "  => PROVEN"
% -----------------------------------------------------------------------------
explain_backward(success(Proof), Goal, Lines) :-
    !,
    conclusion_label(Goal, GoalLabel),
    format(atom(Header), "Goal: ~w", [GoalLabel]),
    render_proof(Proof, 1, ProofLines),
    append([Header|ProofLines], ["RESULT: Goal successfully PROVEN."], Lines).
explain_backward(failure(Goal, Attempts), Goal, Lines) :-
    conclusion_label(Goal, GoalLabel),
    format(atom(Header), "Goal: ~w", [GoalLabel]),
    maplist(render_attempt(1), Attempts, AttemptLinesNested),
    append(AttemptLinesNested, AttemptLines),
    append([Header|AttemptLines], ["RESULT: Goal could NOT be proven from the known facts."], Lines).

render_proof(known(Fact), Depth, [Line]) :-
    !,
    knowledge_base:condition_label(Fact, L),
    indent(Depth, Ind),
    format(atom(Line), "~w~w : KNOWN (reported / given fact)", [Ind, L]).
render_proof(negated(Cond), Depth, [Line]) :-
    !,
    knowledge_base:condition_label(Cond, L),
    indent(Depth, Ind),
    format(atom(Line), "~wNOT(~w) : holds because ~w could not be proven", [Ind, L, L]).
render_proof(derived(RuleID, Concl, Expl, SubProofs), Depth, Lines) :-
    conclusion_label(Concl, ConclLabel),
    indent(Depth, Ind),
    format(atom(L1), "~wTo prove ~w -> uses Rule ~w: ~w", [Ind, ConclLabel, RuleID, Expl]),
    Depth1 is Depth + 1,
    maplist(render_proof_at(Depth1), SubProofs, SubLinesNested),
    append(SubLinesNested, SubLines),
    format(atom(L2), "~w=> ~w established.", [Ind, ConclLabel]),
    append([L1|SubLines], [L2], Lines).

render_proof_at(Depth, Proof, Lines) :- render_proof(Proof, Depth, Lines).

render_attempt(Depth, attempt(none, Missing), Lines) :- !,
    indent(Depth, Ind),
    maplist(knowledge_base:condition_label, Missing, MissingLabels),
    format(atom(Line), "~wNo rule in the knowledge base concludes this goal. Missing: ~w", [Ind, MissingLabels]),
    Lines = [Line].
render_attempt(Depth, attempt(RuleID, Missing), Lines) :-
    indent(Depth, Ind),
    ( rules:rule(RuleID, _, _, Expl) -> true ; Expl = "" ),
    format(atom(L1), "~wTried Rule ~w (~w) - FAILED", [Ind, RuleID, Expl]),
    ( Missing == []
    -> Lines = [L1]
    ;  maplist(knowledge_base:condition_label, Missing, MissingLabels),
       format(atom(L2), "~w  Missing/unproven conditions: ~w", [Ind, MissingLabels]),
       Lines = [L1, L2]
    ).

indent(Depth, Ind) :-
    N is Depth * 2,
    length(Spaces, N),
    maplist(=(' '), Spaces),
    atomic_list_concat(Spaces, Ind).
