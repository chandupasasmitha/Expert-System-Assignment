% =============================================================================
% rules.pl
% -----------------------------------------------------------------------------
% The RULE BASE of the Febrile Illness Advisory Expert System.
%
% Every rule is represented uniformly as:
%
%   rule(RuleID, Conditions, Conclusion, Explanation)
%
% where:
%   RuleID      - an atom identifying the rule (r01, r02, ...)
%   Conditions  - a LIST of condition terms. A condition is either:
%                     has_symptom(S)      - a reported symptom
%                     exposure(E)         - a reported exposure/risk factor
%                     fever_duration(D)   - a reported fever-duration bucket
%                     derived(D)          - an intermediate fact derived by
%                                           an earlier rule (multi-level
%                                           chaining)
%                     not(Cond)           - negation-as-failure: Cond must
%                                           NOT currently be in working
%                                           memory
%   Conclusion  - a single term added to working memory when the rule fires:
%                     derived(D) | suspected(Disease) | recommend(Action)
%   Explanation - a human-readable string used by the explanation facility
%
% This uniform representation is what makes ONE generic forward-chaining
% engine and ONE generic backward-chaining engine work over the whole
% knowledge base (see inference_forward.pl / inference_backward.pl) - the
% engines never hard-code disease logic, they only interpret rule/4 facts.
%
% The rule base has 36 rules, organised in four reasoning levels:
%   Level 1 (r01-r12): raw symptoms/exposures -> intermediate clinical patterns
%   Level 2 (r13-r23): intermediate patterns  -> suspected disease
%   Level 3 (r24-r32): suspected disease      -> recommended action
%   Level 4 (r33-r36): safety-net rules for fevers that match no pattern
%
% Every rule is taken from a published source (rule_source/2 below; the
% full references are in facts.pl). No rule is invented by the author.
% =============================================================================

:- module(rules, [rule/4, rule_source/2, rule_level/2]).

% -----------------------------------------------------------------------------
% LEVEL 1: raw facts -> intermediate derived patterns
% -----------------------------------------------------------------------------

rule(r01,
     [has_symptom(bleeding_gums)],
     derived(hemorrhagic_warning_signs),
     "Bleeding gums is a WHO severe-dengue warning sign.").

rule(r02,
     [has_symptom(nosebleed)],
     derived(hemorrhagic_warning_signs),
     "Bleeding from the nose is a WHO severe-dengue warning sign.").

rule(r03,
     [has_symptom(blood_in_vomit_or_stool)],
     derived(hemorrhagic_warning_signs),
     "Blood in vomit or stool is a WHO severe-dengue warning sign.").

rule(r04,
     [has_symptom(persistent_vomiting)],
     derived(hemorrhagic_warning_signs),
     "Persistent vomiting is a WHO severe-dengue warning sign.").

rule(r05,
     [has_symptom(fever), has_symptom(severe_headache), has_symptom(retro_orbital_pain),
      has_symptom(joint_pain)],
     derived(dengue_pattern),
     "Fever with severe headache, pain behind the eyes and joint pain matches the WHO dengue symptom list.").

rule(r06,
     [has_symptom(fever), has_symptom(severe_headache), has_symptom(retro_orbital_pain),
      has_symptom(muscle_pain)],
     derived(dengue_pattern),
     "Fever with severe headache, pain behind the eyes and muscle pain matches the WHO dengue symptom list.").

rule(r07,
     [has_symptom(chills_and_sweating), has_symptom(fever), exposure(malaria_endemic_travel)],
     derived(malaria_pattern),
     "Fever with chills and sweats after time in a malaria area matches the CDC malaria presentation.").

rule(r08,
     [fever_duration(long), has_symptom(abdominal_pain), has_symptom(rose_spots),
      exposure(unhygienic_food_water)],
     derived(typhoid_pattern),
     "Fever lasting over 3 days with stomach pain, rose-coloured spots and contaminated food/water exposure matches CDC typhoid.").

rule(r09,
     [fever_duration(long), has_symptom(abdominal_pain), has_symptom(constipation),
      exposure(unhygienic_food_water)],
     derived(typhoid_pattern),
     "Fever lasting over 3 days with stomach pain, constipation and contaminated food/water exposure matches CDC typhoid.").

rule(r10,
     [has_symptom(cough), has_symptom(sore_throat), has_symptom(runny_nose), has_symptom(sneezing)],
     derived(respiratory_cluster),
     "Cough, sore throat, runny nose and sneezing are the CDC-listed upper respiratory (cold) symptoms.").

rule(r11,
     [has_symptom(fever), has_symptom(severe_joint_pain), has_symptom(skin_rash),
      exposure(mosquito_bite_area)],
     derived(chikungunya_pattern),
     "Fever and joint pain (the most common symptoms) with rash after mosquito exposure matches CDC chikungunya.").

rule(r12,
     [has_symptom(fever), has_symptom(calf_muscle_pain), has_symptom(jaundice),
      exposure(contaminated_water), has_symptom(conjunctivitis)],
     derived(leptospirosis_pattern),
     "Fever, calf pain, jaundice and red eyes after contact with contaminated water matches leptospirosis (CDC, MSF).").

% -----------------------------------------------------------------------------
% LEVEL 2: intermediate patterns -> suspected disease
% -----------------------------------------------------------------------------

rule(r13,
     [derived(dengue_pattern), not(derived(hemorrhagic_warning_signs))],
     suspected(dengue),
     "Dengue pattern present with no warning signs -> suspected (non-severe) dengue.").

rule(r14,
     [derived(dengue_pattern), derived(hemorrhagic_warning_signs)],
     suspected(severe_dengue),
     "Dengue pattern combined with WHO warning signs indicates possible severe dengue.").

rule(r15,
     [derived(malaria_pattern)],
     suspected(malaria),
     "Fever, chills and sweats after time in a malaria area indicates suspected malaria.").

rule(r16,
     [derived(typhoid_pattern)],
     suspected(typhoid),
     "The prolonged-fever/stomach/exposure pattern indicates suspected typhoid fever.").

rule(r17,
     [derived(respiratory_cluster), has_symptom(loss_of_smell_taste), exposure(covid_case_contact)],
     suspected(covid19),
     "Respiratory symptoms plus new loss of taste or smell and contact with a case indicates suspected COVID-19.").

rule(r18,
     [derived(respiratory_cluster), has_symptom(loss_of_smell_taste), not(exposure(covid_case_contact))],
     suspected(covid19),
     "Respiratory symptoms with new loss of taste or smell (a CDC-listed COVID-19 symptom) indicates suspected COVID-19.").

rule(r19,
     [has_symptom(fever), has_symptom(muscle_pain), derived(respiratory_cluster),
      not(has_symptom(loss_of_smell_taste))],
     suspected(influenza),
     "Fever with muscle/body aches and respiratory symptoms matches CDC flu symptoms.").

rule(r20,
     [has_symptom(fever), has_symptom(headache), derived(respiratory_cluster),
      not(has_symptom(loss_of_smell_taste)), not(has_symptom(muscle_pain))],
     suspected(influenza),
     "Fever with headache and respiratory symptoms matches CDC flu symptoms.").

rule(r21,
     [derived(respiratory_cluster), not(has_symptom(fever)), not(has_symptom(loss_of_smell_taste))],
     suspected(common_cold),
     "Respiratory symptoms without fever fit a cold rather than flu (CDC: fever and body aches point to flu).").

rule(r22,
     [derived(chikungunya_pattern)],
     suspected(chikungunya),
     "The fever/joint-pain/rash/mosquito-exposure pattern indicates suspected chikungunya.").

rule(r23,
     [derived(leptospirosis_pattern)],
     suspected(leptospirosis),
     "The fever/calf-pain/jaundice/water-exposure pattern indicates suspected leptospirosis.").

% -----------------------------------------------------------------------------
% LEVEL 3: suspected disease -> recommended action
% -----------------------------------------------------------------------------

rule(r24,  [suspected(severe_dengue)], recommend(seek_emergency_care),
     "WHO: with warning signs, contact a doctor as soon as possible; severe cases need hospital care.").
rule(r25,  [suspected(dengue)], recommend(rest_fluids_paracetamol_watch_warning_signs),
     "WHO: rest, drink plenty of liquids, use paracetamol, avoid NSAIDs and watch for severe symptoms.").
rule(r26,  [suspected(malaria)], recommend(urgent_blood_test_and_antimalarial_treatment),
     "CDC: see a healthcare provider; malaria is curable if diagnosed and treated promptly.").
rule(r27,  [suspected(typhoid)], recommend(see_doctor_for_antibiotics),
     "CDC: antibiotics are used to treat typhoid fever.").
rule(r28,  [suspected(covid19)], recommend(stay_home_and_get_tested),
     "CDC: stay home and away from others; seek care promptly for testing if at higher risk.").
rule(r29,  [suspected(influenza)], recommend(rest_fluids_antivirals_if_high_risk),
     "CDC: antiviral treatment is recommended early for people at higher risk of flu complications.").
rule(r30,  [suspected(common_cold)], recommend(supportive_care_home_rest),
     "CDC: get plenty of rest and fluids; antibiotics do not work against colds.").
rule(r31,  [suspected(chikungunya)], recommend(rest_fluids_pain_relief),
     "CDC: rest, fluids and over-the-counter pain medications may relieve symptoms.").
rule(r32,  [suspected(leptospirosis)], recommend(urgent_medical_review_possible_antibiotics),
     "CDC: see a healthcare provider right away so they can run tests and start antibiotics.").

% -----------------------------------------------------------------------------
% LEVEL 4: safety-net rules for fevers that do not match a specific pattern
% -----------------------------------------------------------------------------

rule(r33,
     [fever_duration(long), not(suspected(dengue)), not(suspected(severe_dengue)),
      not(suspected(malaria)), not(suspected(typhoid))],
     recommend(see_doctor_further_tests),
     "CDC: contact a doctor for a fever that lasts longer than 4 days; no specific pattern was matched.").

rule(r34,
     [has_symptom(fever), exposure(malaria_endemic_travel), not(suspected(malaria))],
     recommend(see_doctor_report_travel),
     "CDC: travellers with fever or flu-like illness after time in a malaria area should see a healthcare provider.").

rule(r35,
     [has_symptom(high_grade_fever), fever_duration(short), not(derived(dengue_pattern)),
      not(derived(malaria_pattern))],
     derived(unspecified_acute_febrile_illness),
     "A high fever (39-40C) that matches no specific pattern is flagged as an unexplained acute fever.").

rule(r36,
     [derived(unspecified_acute_febrile_illness), not(suspected(dengue)), not(suspected(malaria)),
      not(suspected(covid19)), not(suspected(influenza))],
     recommend(see_doctor_further_tests),
     "CDC/NHS: see a doctor if you have a fever and feel very ill, or a high temperature that is not improving.").

% -----------------------------------------------------------------------------
% rule_source(RuleID, SourceKey) - traceability of every rule to the
% reference sources in facts.pl. A rule may cite more than one source.
% -----------------------------------------------------------------------------
rule_source(r01, who_dengue).
rule_source(r02, who_dengue).
rule_source(r03, who_dengue).
rule_source(r04, who_dengue).
rule_source(r05, who_dengue).
rule_source(r06, who_dengue).
rule_source(r07, cdc_malaria_hcp).
rule_source(r08, cdc_typhoid).
rule_source(r08, cdc_typhoid_about).
rule_source(r09, cdc_typhoid).
rule_source(r09, cdc_typhoid_about).
rule_source(r10, cdc_cold).
rule_source(r11, cdc_chik).
rule_source(r11, cdc_chik_about).
rule_source(r12, cdc_lepto).
rule_source(r12, msf_lepto).
rule_source(r13, who_dengue).
rule_source(r14, who_dengue).
rule_source(r15, cdc_malaria_hcp).
rule_source(r16, cdc_typhoid).
rule_source(r17, cdc_covid).
rule_source(r18, cdc_covid).
rule_source(r19, cdc_flu).
rule_source(r19, cdc_coldflu).
rule_source(r20, cdc_flu).
rule_source(r20, cdc_coldflu).
rule_source(r21, cdc_coldflu).
rule_source(r21, cdc_cold).
rule_source(r22, cdc_chik).
rule_source(r23, cdc_lepto).
rule_source(r23, msf_lepto).
rule_source(r24, who_dengue).
rule_source(r25, who_dengue).
rule_source(r26, cdc_malaria).
rule_source(r26, cdc_malaria_hcp).
rule_source(r27, cdc_typhoid_tx).
rule_source(r28, cdc_covid).
rule_source(r29, cdc_flu_tx).
rule_source(r30, cdc_cold_tx).
rule_source(r31, cdc_chik).
rule_source(r32, cdc_lepto).
rule_source(r33, cdc_cold_tx).
rule_source(r34, cdc_malaria).
rule_source(r35, cdc_typhoid).
rule_source(r35, nhs_fever).
rule_source(r36, cdc_typhoid).
rule_source(r36, nhs_fever).

% -----------------------------------------------------------------------------
% rule_level(RuleID, Level) - which reasoning level a rule belongs to, used
% purely for documentation / the Knowledge Base UI page.
% -----------------------------------------------------------------------------
rule_level(R, 1) :- member(R, [r01,r02,r03,r04,r05,r06,r07,r08,r09,r10,r11,r12]).
rule_level(R, 2) :- member(R, [r13,r14,r15,r16,r17,r18,r19,r20,r21,r22,r23]).
rule_level(R, 3) :- member(R, [r24,r25,r26,r27,r28,r29,r30,r31,r32]).
rule_level(R, 4) :- member(R, [r33,r34,r35,r36]).
