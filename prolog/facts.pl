% =============================================================================
% facts.pl
% -----------------------------------------------------------------------------
% Static domain knowledge for the Febrile Illness Advisory Expert System.
%
% This file defines the DECLARATIVE FACT BASE of the system:
%   1. fact_doc/4      - documentation of every input fact the system can
%                         accept from the user (symptom / exposure vocabulary)
%   2. source/5        - the reference sources the domain knowledge was
%                         drawn from (used by fact_doc/4 and rule_source/2)
%   3. disease_info/3  - human-readable name + short description for every
%                         disease the system can suspect
%   4. action_info/2   - human-readable text for every recommended action
%
% NOTE ON "FACTS" vs "WORKING MEMORY":
%   The facts below are the *static* knowledge base facts (the vocabulary and
%   reference knowledge an expert would write down before any consultation).
%   During a consultation, the facts the *user* reports (e.g. has_symptom(fever))
%   are asserted into a *working memory* (see inference_forward.pl /
%   inference_backward.pl) which the inference engine reasons over. Both are
%   "facts" in the classical expert-system sense; this file documents the
%   former, and rules.pl documents how the latter combine.
% =============================================================================

:- module(facts, [fact_doc/4, source/5, disease_info/3, action_info/2]).

% -----------------------------------------------------------------------------
% source(SourceKey, Title, Organisation, Accessed, Url)
% Reliable external sources used to establish domain knowledge. Every URL was
% opened and checked against the facts/rules that cite it on 29 Sep 2026.
% -----------------------------------------------------------------------------
source(who_dengue,     "Dengue and severe dengue - Fact sheet", "World Health Organization (WHO)", "accessed 29 Sep 2026",
       'https://www.who.int/news-room/fact-sheets/detail/dengue-and-severe-dengue').
source(cdc_malaria,    "Symptoms of Malaria", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/malaria/symptoms/index.html').
source(cdc_malaria_hcp, "Clinical Features of Malaria", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/malaria/hcp/clinical-features/index.html').
source(cdc_typhoid,    "Symptoms of Typhoid Fever and Paratyphoid Fever", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/typhoid-fever/signs-symptoms/index.html').
source(cdc_typhoid_about, "About Typhoid Fever and Paratyphoid Fever", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/typhoid-fever/about/index.html').
source(cdc_typhoid_tx, "Treatment of Typhoid Fever and Paratyphoid Fever", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/typhoid-fever/treatment/index.html').
source(cdc_flu,        "Signs and Symptoms of Flu", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/flu/signs-symptoms/index.html').
source(cdc_flu_tx,     "Treating Flu with Antiviral Drugs", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/flu/treatment/index.html').
source(cdc_coldflu,    "Cold Versus Flu", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/flu/about/coldflu.html').
source(cdc_covid,      "Symptoms of COVID-19", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/covid/signs-symptoms/index.html').
source(cdc_cold,       "About Common Cold", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/common-cold/about/index.html').
source(cdc_cold_tx,    "Manage Common Cold", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/common-cold/treatment/index.html').
source(cdc_chik,       "Symptoms of Chikungunya", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/chikungunya/signs-symptoms/index.html').
source(cdc_chik_about, "About Chikungunya", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/chikungunya/about/index.html').
source(cdc_lepto,      "About Leptospirosis", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/leptospirosis/about/index.html').
source(cdc_lepto_hcp,  "Clinical Overview of Leptospirosis", "US Centers for Disease Control and Prevention (CDC)", "accessed 29 Sep 2026",
       'https://www.cdc.gov/leptospirosis/hcp/clinical-overview/index.html').
source(msf_lepto,      "Clinical guidelines - Leptospirosis", "Medecins Sans Frontieres (MSF)", "accessed 29 Sep 2026",
       'https://medicalguidelines.msf.org/en/viewport/CG/english/leptospirosis-16689941.html').
source(nhs_fever,      "High temperature (fever) in adults", "National Health Service (NHS, UK)", "accessed 29 Sep 2026",
       'https://www.nhs.uk/symptoms/high-temperature-fever-in-adults/').

% -----------------------------------------------------------------------------
% fact_doc(FactID, Term, Meaning, SourceKey)
% The complete vocabulary of INPUT facts the UI can collect and assert into
% working memory. 35 facts documented (exceeds the required 20).
% -----------------------------------------------------------------------------
fact_doc(f01, has_symptom(fever),               "Patient currently has fever (38C or above).", nhs_fever).
fact_doc(f02, has_symptom(high_grade_fever),    "Fever is high-grade (39-40C or above).", cdc_typhoid).
fact_doc(f03, fever_duration(short),            "Fever has lasted less than 3 days.", cdc_typhoid).
fact_doc(f04, fever_duration(medium),           "Fever has lasted between 3 and 7 days.", cdc_typhoid).
fact_doc(f05, fever_duration(long),             "Fever has lasted more than 7 days.", cdc_cold_tx).
fact_doc(f06, has_symptom(headache),            "Patient reports headache.", cdc_flu).
fact_doc(f07, has_symptom(severe_headache),     "Headache is severe.", who_dengue).
fact_doc(f08, has_symptom(retro_orbital_pain),  "Pain behind the eyes.", who_dengue).
fact_doc(f09, has_symptom(joint_pain),          "Patient reports joint pain.", who_dengue).
fact_doc(f10, has_symptom(severe_joint_pain),   "Joint pain is severe and disabling.", cdc_chik).
fact_doc(f11, has_symptom(muscle_pain),         "Patient reports muscle or body aches.", cdc_flu).
fact_doc(f12, has_symptom(calf_muscle_pain),    "Muscle pain especially in the calves.", msf_lepto).
fact_doc(f13, has_symptom(skin_rash),           "Patient has a skin rash.", cdc_chik).
fact_doc(f14, has_symptom(bleeding_gums),       "Bleeding gums.", who_dengue).
fact_doc(f15, has_symptom(nosebleed),           "Bleeding from the nose.", who_dengue).
fact_doc(f16, has_symptom(blood_in_vomit_or_stool), "Blood in vomit or stool.", who_dengue).
fact_doc(f17, has_symptom(persistent_vomiting), "Persistent vomiting.", who_dengue).
fact_doc(f18, has_symptom(abdominal_pain),      "Stomach / abdominal pain.", cdc_typhoid).
fact_doc(f19, has_symptom(diarrhea),            "Patient has diarrhoea.", cdc_typhoid).
fact_doc(f20, has_symptom(constipation),        "Patient has constipation.", cdc_typhoid).
fact_doc(f21, has_symptom(rose_spots),          "Rash with flat, rose-coloured spots.", cdc_typhoid).
fact_doc(f22, has_symptom(sore_throat),         "Patient has a sore throat.", cdc_cold).
fact_doc(f23, has_symptom(cough),               "Patient has a cough.", cdc_cold).
fact_doc(f24, has_symptom(shortness_of_breath), "Shortness of breath or difficulty breathing.", cdc_covid).
fact_doc(f25, has_symptom(runny_nose),          "Runny nose or nasal congestion.", cdc_cold).
fact_doc(f26, has_symptom(sneezing),            "Patient is sneezing.", cdc_cold).
fact_doc(f27, has_symptom(chills_and_sweating), "Chills and sweats.", cdc_malaria_hcp).
fact_doc(f28, has_symptom(loss_of_smell_taste), "New loss of taste or smell.", cdc_covid).
fact_doc(f29, has_symptom(conjunctivitis),      "Red eyes (conjunctival suffusion).", cdc_lepto).
fact_doc(f30, has_symptom(jaundice),            "Yellowed skin and eyes (jaundice).", cdc_lepto).
fact_doc(f31, exposure(mosquito_bite_area),     "Lives in or recently visited an area with dengue/chikungunya mosquitoes.", cdc_chik_about).
fact_doc(f32, exposure(contaminated_water),     "Contact with flood water, fresh water or soil that may contain animal urine.", cdc_lepto).
fact_doc(f33, exposure(unhygienic_food_water),  "Food, drinks or water that may be contaminated by sewage.", cdc_typhoid_about).
fact_doc(f34, exposure(covid_case_contact),     "Recent close contact with a confirmed COVID-19 case.", cdc_covid).
fact_doc(f35, exposure(malaria_endemic_travel), "Travel in the past 12 months to an area where malaria occurs.", cdc_malaria_hcp).

% -----------------------------------------------------------------------------
% disease_info(Disease, DisplayName, ShortDescription)
% -----------------------------------------------------------------------------
disease_info(dengue,          "Dengue Fever",
    "A mosquito-borne viral infection causing high fever, severe headache, pain behind the eyes and muscle/joint pain (WHO).").
disease_info(severe_dengue,   "Severe Dengue (Warning Signs Present)",
    "Dengue with warning signs such as bleeding gums or nose, blood in vomit/stool or persistent vomiting (WHO).").
disease_info(malaria,         "Malaria",
    "A mosquito-borne parasitic disease presenting with fever, chills and sweats after time in a malaria area (CDC).").
disease_info(typhoid,         "Typhoid Fever",
    "A bacterial infection spread by food and water contaminated with sewage, causing fever lasting more than 3 days (CDC).").
disease_info(covid19,         "COVID-19",
    "A viral respiratory infection; new loss of taste or smell is a listed symptom (CDC).").
disease_info(influenza,       "Influenza (Flu)",
    "A viral respiratory infection with fever, muscle/body aches, headache and respiratory symptoms (CDC).").
disease_info(common_cold,     "Common Cold",
    "A mild upper respiratory viral infection; fever is usually absent or low grade (CDC).").
disease_info(chikungunya,     "Chikungunya",
    "A mosquito-borne viral infection whose most common symptoms are fever and joint pain, often with rash (CDC).").
disease_info(leptospirosis,   "Leptospirosis",
    "A bacterial infection from water or soil contaminated with animal urine; fever, calf pain, red eyes, jaundice (CDC, MSF).").

% -----------------------------------------------------------------------------
% action_info(Action, DisplayText)
% -----------------------------------------------------------------------------
action_info(seek_emergency_care,
    "Seek medical care immediately - dengue warning signs are present and hospital care may be needed.").
action_info(rest_fluids_paracetamol_watch_warning_signs,
    "Rest, drink plenty of fluids and use paracetamol for pain (avoid ibuprofen/aspirin); see a doctor at once if warning signs appear.").
action_info(urgent_blood_test_and_antimalarial_treatment,
    "See a healthcare provider promptly and mention your travel; malaria is curable if diagnosed and treated promptly.").
action_info(see_doctor_for_antibiotics,
    "See a doctor; typhoid fever is treated with prescribed antibiotics.").
action_info(stay_home_and_get_tested,
    "Stay home and away from others and get tested; seek care promptly if at higher risk of severe illness.").
action_info(rest_fluids_antivirals_if_high_risk,
    "Rest and stay home until fever-free for 24 hours; ask a doctor about antiviral drugs if you are in a higher-risk group.").
action_info(supportive_care_home_rest,
    "Rest and drink plenty of fluids; antibiotics will not help. See a doctor if symptoms last more than 10 days.").
action_info(rest_fluids_pain_relief,
    "Rest, drink fluids and use over-the-counter pain medication; see a doctor if joint pain persists.").
action_info(urgent_medical_review_possible_antibiotics,
    "See a healthcare provider right away for tests; leptospirosis is treated with antibiotics.").
action_info(see_doctor_further_tests,
    "See a doctor for further evaluation - fever is not improving and no specific pattern was matched.").
action_info(see_doctor_report_travel,
    "See a healthcare provider and tell them about your travel to a malaria area.").
