% =============================================================================
% inference_backward.pl
% -----------------------------------------------------------------------------
% GENUINE backward-chaining (goal-driven / top-down) inference engine.
%
% Algorithm:
%   1. The user (or the API) picks a GOAL to investigate, e.g. suspected(dengue)
%      or recommend(seek_emergency_care).
%   2. To prove a Goal:
%        a. If Goal is already a known (reported) fact -> proven directly.
%        b. Otherwise, find a rule whose Conclusion unifies with Goal, and
%           recursively try to prove EVERY condition in that rule's
%           Conditions list (this is the recursive descent that makes it
%           backward chaining - conditions become new sub-goals).
%        c. A negated condition not(Cond) is proven when Cond CANNOT be
%           proven from the known facts/rules (negation as finite failure).
%        d. If a rule's conditions cannot all be proven, the engine tries
%           the NEXT rule (if any) that also concludes Goal, exactly like
%           Prolog backtracking over alternative ways to justify a goal.
%   3. If every rule (and every alternative) concluding Goal fails, the goal
%      is reported as NOT PROVEN, together with a report of every rule that
%      was attempted and exactly which of its conditions were missing - this
%      is what lets the UI "state whether the goal was successfully proven".
%
% The full recursive proof tree is returned so the explanation facility can
% render the exact chain: goal -> rule used -> sub-goals -> sub-rules -> ...
% -> known facts, mirroring the required example in the assignment brief.
% =============================================================================

:- module(inference_backward, [backward_chain/3]).

:- use_module(rules).

% backward_chain(+Goal, +KnownFacts, -Result)
%   Result = success(ProofTree)
%          | failure(Goal, AttemptReports)
%
%   ProofTree is one of:
%     known(Fact)
%     negated(Cond)                          - not(Cond) proven by absence
%     derived(RuleID, Concl, Explanation, SubProofs)
%
%   AttemptReports is a list of attempt(RuleID, MissingConditions) - every
%   rule that concludes Goal, and which of its conditions could not be
%   proven, so the UI can explain exactly why the goal failed.
backward_chain(Goal, KnownFacts, success(Proof)) :-
    bc_prove(Goal, KnownFacts, Proof), !.
backward_chain(Goal, KnownFacts, failure(Goal, Attempts)) :-
    findall(attempt(RuleID, Missing),
            ( rules:rule(RuleID, Conds, Goal, _Expl),
              missing_conditions(Conds, KnownFacts, Missing)
            ),
            Attempts0),
    ( Attempts0 == [] -> Attempts = [attempt(none, [Goal])] ; Attempts = Attempts0 ).

% --- core recursive prover -----------------------------------------------

bc_prove(Fact, KnownFacts, known(Fact)) :-
    member(Fact, KnownFacts), !.
bc_prove(Goal, KnownFacts, derived(RuleID, Goal, Expl, SubProofs)) :-
    rules:rule(RuleID, Conds, Goal, Expl),
    bc_prove_all(Conds, KnownFacts, SubProofs).

bc_prove_all([], _KnownFacts, []).
bc_prove_all([not(Cond)|Rest], KnownFacts, [negated(Cond)|RestProofs]) :- !,
    \+ bc_prove(Cond, KnownFacts, _),
    bc_prove_all(Rest, KnownFacts, RestProofs).
bc_prove_all([Cond|Rest], KnownFacts, [Proof|RestProofs]) :-
    bc_prove(Cond, KnownFacts, Proof),
    bc_prove_all(Rest, KnownFacts, RestProofs).

% --- failure diagnostics ---------------------------------------------------

% missing_conditions(+Conds, +KnownFacts, -Missing)
% Missing = the sub-list of Conds that could NOT be proven, used to explain
% exactly why a candidate rule did not fire.
missing_conditions([], _KnownFacts, []).
missing_conditions([not(Cond)|Rest], KnownFacts, Missing) :-
    ( \+ bc_prove(Cond, KnownFacts, _)
    -> missing_conditions(Rest, KnownFacts, Missing)
    ;  missing_conditions(Rest, KnownFacts, Missing0),
       Missing = [not(Cond)|Missing0]
    ).
missing_conditions([Cond|Rest], KnownFacts, Missing) :-
    ( bc_prove(Cond, KnownFacts, _)
    -> missing_conditions(Rest, KnownFacts, Missing)
    ;  missing_conditions(Rest, KnownFacts, Missing0),
       Missing = [Cond|Missing0]
    ).
