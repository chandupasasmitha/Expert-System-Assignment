:- ['../prolog/facts'].
:- ['../prolog/rules'].
:- ['../prolog/knowledge_base'].
:- ['../prolog/inference_forward'].
:- ['../prolog/inference_backward'].
:- ['../prolog/explanation'].

:- initialization(run_smoke, main).

run_smoke :-
    knowledge_base:num_facts(NF), knowledge_base:num_rules(NR),
    format("FACTS=~w RULES=~w~n", [NF,NR]),

    % Test 1: classic non-severe dengue
    F1 = [has_symptom(fever), has_symptom(severe_headache), has_symptom(retro_orbital_pain),
          has_symptom(joint_pain), exposure(mosquito_bite_area)],
    forward_chain(F1, Final1, Trace1),
    extract_conclusions(Final1, conclusions(D1,A1)),
    length(Trace1, T1Len),
    format("~nTEST1 dengue -> diseases=~w actions=~w (rules_fired=~w)~n", [D1,A1,T1Len]),

    % Test 2: severe dengue
    F2 = [has_symptom(fever), has_symptom(severe_headache), has_symptom(retro_orbital_pain),
          has_symptom(joint_pain), exposure(mosquito_bite_area),
          has_symptom(persistent_vomiting), has_symptom(bleeding_gums)],
    forward_chain(F2, Final2, _Trace2),
    extract_conclusions(Final2, conclusions(D2,A2)),
    format("TEST2 severe dengue -> diseases=~w actions=~w~n", [D2,A2]),

    % Test 3: malaria
    F3 = [has_symptom(fever), has_symptom(chills_and_sweating), exposure(malaria_endemic_travel)],
    forward_chain(F3, Final3, _),
    extract_conclusions(Final3, conclusions(D3,A3)),
    format("TEST3 malaria -> diseases=~w actions=~w~n", [D3,A3]),

    % Test 4: typhoid
    F4 = [fever_duration(long), has_symptom(abdominal_pain), has_symptom(rose_spots),
          exposure(unhygienic_food_water)],
    forward_chain(F4, Final4, _),
    extract_conclusions(Final4, conclusions(D4,A4)),
    format("TEST4 typhoid -> diseases=~w actions=~w~n", [D4,A4]),

    % Test 5: covid
    F5 = [has_symptom(cough), has_symptom(sore_throat), has_symptom(runny_nose), has_symptom(sneezing),
          has_symptom(loss_of_smell_taste), exposure(covid_case_contact)],
    forward_chain(F5, Final5, _),
    extract_conclusions(Final5, conclusions(D5,A5)),
    format("TEST5 covid -> diseases=~w actions=~w~n", [D5,A5]),

    % Test 6: flu
    F6 = [has_symptom(fever), has_symptom(muscle_pain), has_symptom(cough), has_symptom(sore_throat),
          has_symptom(runny_nose), has_symptom(sneezing)],
    forward_chain(F6, Final6, _),
    extract_conclusions(Final6, conclusions(D6,A6)),
    format("TEST6 flu -> diseases=~w actions=~w~n", [D6,A6]),

    % Test 7: common cold
    F7 = [has_symptom(runny_nose), has_symptom(sneezing), has_symptom(sore_throat), has_symptom(cough)],
    forward_chain(F7, Final7, _),
    extract_conclusions(Final7, conclusions(D7,A7)),
    format("TEST7 cold -> diseases=~w actions=~w~n", [D7,A7]),

    % Test 8: chikungunya
    F8 = [has_symptom(fever), has_symptom(severe_joint_pain), has_symptom(skin_rash), exposure(mosquito_bite_area)],
    forward_chain(F8, Final8, _),
    extract_conclusions(Final8, conclusions(D8,A8)),
    format("TEST8 chikungunya -> diseases=~w actions=~w~n", [D8,A8]),

    % Test 9: leptospirosis
    F9 = [has_symptom(fever), has_symptom(calf_muscle_pain), has_symptom(jaundice),
          exposure(contaminated_water), has_symptom(conjunctivitis)],
    forward_chain(F9, Final9, _),
    extract_conclusions(Final9, conclusions(D9,A9)),
    format("TEST9 leptospirosis -> diseases=~w actions=~w~n", [D9,A9]),

    % Test 10: fallback (ambiguous prolonged fever)
    F10 = [has_symptom(fever), fever_duration(long)],
    forward_chain(F10, Final10, _),
    extract_conclusions(Final10, conclusions(D10,A10)),
    format("TEST10 fallback -> diseases=~w actions=~w~n", [D10,A10]),

    % Test 11: no symptoms edge case
    F11 = [],
    forward_chain(F11, Final11, _),
    extract_conclusions(Final11, conclusions(D11,A11)),
    format("TEST11 empty -> diseases=~w actions=~w~n", [D11,A11]),

    % Test 12: fever after malaria-area travel without chills (safety net r34)
    F12 = [has_symptom(fever), exposure(malaria_endemic_travel)],
    forward_chain(F12, Final12, _),
    extract_conclusions(Final12, conclusions(D12,A12)),
    format("TEST12 malaria-travel fever -> diseases=~w actions=~w~n", [D12,A12]),

    % --- Backward chaining tests ---
    format("~n--- BACKWARD CHAINING ---~n"),
    backward_chain(suspected(dengue), F1, BC1),
    ( BC1 = success(_) -> format("BC1 prove suspected(dengue) from F1: SUCCESS~n") ; format("BC1 FAILED: ~w~n",[BC1]) ),
    explain_backward(BC1, suspected(dengue), Lines1),
    forall(member(L,Lines1), format("  ~w~n",[L])),

    backward_chain(suspected(malaria), F1, BC2),
    ( BC2 = success(_) -> format("BC2 prove suspected(malaria) from F1 (dengue facts): unexpectedly SUCCESS~n")
    ; format("BC2 prove suspected(malaria) from F1 (dengue facts): correctly FAILED~n") ),

    format("~nALL SMOKE TESTS COMPLETED OK~n").
