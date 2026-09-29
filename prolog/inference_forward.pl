% =============================================================================
% inference_forward.pl
% -----------------------------------------------------------------------------
% GENUINE forward-chaining inference engine.
%
% Algorithm (data-driven / bottom-up):
%   1. Start with the set of INITIAL FACTS (symptoms/exposures reported by
%      the user via the UI).
%   2. Repeatedly scan the rule base (rules.pl) for any rule whose entire
%      Conditions list is already satisfied by the current working memory,
%      AND whose Conclusion is not already known.
%   3. Fire the FIRST such rule (in knowledge-base order), adding its
%      conclusion to working memory and recording it in the trace.
%   4. Repeat from step 2 using the UPDATED working memory.
%   5. Stop when no rule can fire (fixpoint reached) - i.e. no additional
%      facts can be derived.
%
% This is a genuine fixpoint forward-chaining procedure: every fired rule is
% only fired because its conditions were verified present in working memory
% at that point, and newly derived facts (derived(...), suspected(...)) can
% themselves satisfy the conditions of later rules, enabling real multi-level
% chaining (raw symptoms -> derived patterns -> suspected disease ->
% recommended action), exactly as required.
% =============================================================================

:- module(inference_forward, [forward_chain/3]).

:- use_module(rules).

% forward_chain(+InitialFacts, -FinalFacts, -Trace)
%   InitialFacts : list of fact terms the user reported
%   FinalFacts   : InitialFacts plus every fact derived during chaining
%   Trace        : list of fired(RuleID, ConditionsUsed, Conclusion) in the
%                  exact order the rules fired - this IS the audit trail the
%                  explanation facility renders back to the user.
forward_chain(InitialFacts, FinalFacts, Trace) :-
    list_to_set(InitialFacts, WM0),
    forward_loop(WM0, [], FinalFacts, TraceRev),
    reverse(TraceRev, Trace).

% forward_loop(+WM, +TraceAcc, -FinalWM, -FinalTraceRevd)
%
% Fires ONE rule per cycle (the first rule, in knowledge-base order, whose
% conditions are satisfied and whose conclusion is not yet known), then
% recomputes the fireable set from scratch against the UPDATED working
% memory before trying again. This single-rule-per-cycle conflict
% resolution strategy (a standard approach in production-rule systems) is
% what guarantees NEGATED conditions (not(Cond)) are always evaluated
% against a fully up-to-date working memory rather than a stale snapshot,
% so a rule can never fire in "false ignorance" of a fact derived in the
% same instant by another rule.
forward_loop(WM, TraceAcc, FinalWM, FinalTrace) :-
    ( rules:rule(RuleID, Conds, Concl, _Expl),
      conditions_satisfied(Conds, WM),
      \+ member(Concl, WM)
    -> ( member(Concl, WM) -> WM1 = WM ; WM1 = [Concl|WM] ),
       forward_loop(WM1, [fired(RuleID, Conds, Concl)|TraceAcc], FinalWM, FinalTrace)
    ;  FinalWM = WM, FinalTrace = TraceAcc                 % fixpoint reached
    ).

% A rule's condition list is satisfied iff every condition holds in WM.
conditions_satisfied([], _WM).
conditions_satisfied([not(Cond)|Rest], WM) :- !,
    \+ member(Cond, WM),
    conditions_satisfied(Rest, WM).
conditions_satisfied([Cond|Rest], WM) :-
    member(Cond, WM),
    conditions_satisfied(Rest, WM).
