#!/usr/bin/env python3
"""
API-level test suite for the Febrile Illness Advisory Expert System.
Exercises the running HTTP server end-to-end (frontend/backend/Prolog engine
all together) and prints a pass/fail table. This is what docs/testing.md's
results table is generated from.
"""
import json
import os
import urllib.request

BASE = "http://localhost:" + os.environ.get("PORT", "8000")

def post(path, body):
    req = urllib.request.Request(
        BASE + path, data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=5) as r:
        return json.loads(r.read())

def get(path):
    with urllib.request.urlopen(BASE + path, timeout=5) as r:
        return json.loads(r.read())

CASES = [
    ("TC01", "Classic non-severe dengue", ["f01","f07","f08","f09","f31"], "dengue", "rest_fluids_paracetamol_watch_warning_signs"),
    ("TC02", "Severe dengue (warning signs)", ["f01","f07","f08","f09","f31","f17","f14"], "severe_dengue", "seek_emergency_care"),
    ("TC03", "Malaria after endemic travel", ["f01","f27","f35"], "malaria", "urgent_blood_test_and_antimalarial_treatment"),
    ("TC04", "Typhoid fever", ["f05","f18","f21","f33"], "typhoid", "see_doctor_for_antibiotics"),
    ("TC05", "COVID-19 with known contact", ["f23","f22","f25","f26","f28","f34"], "covid19", "stay_home_and_get_tested"),
    ("TC06", "Influenza", ["f01","f11","f23","f22","f25","f26"], "influenza", "rest_fluids_antivirals_if_high_risk"),
    ("TC07", "Common cold", ["f25","f26","f22","f23"], "common_cold", "supportive_care_home_rest"),
    ("TC08", "Chikungunya", ["f01","f10","f13","f31"], "chikungunya", "rest_fluids_pain_relief"),
    ("TC09", "Leptospirosis", ["f01","f12","f30","f29","f32"], "leptospirosis", "urgent_medical_review_possible_antibiotics"),
    ("TC10", "Ambiguous prolonged fever (fallback/boundary)", ["f01","f05"], None, "see_doctor_further_tests"),
    ("TC11", "No symptoms at all (edge case)", [], None, None),
    ("TC17", "Fever after malaria-area travel, no chills (r34)", ["f01","f35"], None, "see_doctor_report_travel"),
    ("TC18", "Short high fever, no pattern (r35 -> r36)", ["f01","f02","f03"], None, "see_doctor_further_tests"),
]

results = []
rules_by_case = {}
print(f"{'ID':5} {'Scenario':40} {'Expected Disease':16} {'Actual':16} {'Expected Action':32} {'Actual':32} Status")
for tid, name, facts, exp_disease, exp_action in CASES:
    r = post("/api/forward", {"fact_ids": facts})
    diseases = [d["id"] for d in r["suspected_diseases"]]
    actions = [a["id"] for a in r["recommended_actions"]]
    disease_ok = (exp_disease is None and diseases == []) or (exp_disease in diseases)
    action_ok = (exp_action is None and actions == []) or (exp_action in actions)
    status = "PASS" if (disease_ok and action_ok) else "FAIL"
    results.append((tid, status, r["rules_fired"]))
    rules_by_case[tid] = r["rules_fired"]
    print(f"{tid:5} {name[:40]:40} {str(exp_disease):16} {str(diseases):16} {str(exp_action)[:32]:32} {str(actions)[:32]:32} {status}")

print("\n--- Rules fired per case ---")
for tid, fired in rules_by_case.items():
    print(f"{tid:5} {', '.join(fired) if fired else '(none)'}")

# Invalid / missing input handling
print("\n--- Error handling tests ---")
try:
    r = post("/api/forward", {"fact_ids": ["f99", "not_a_real_id"]})
    print("TC12 unknown fact ids -> ok:", r["ok"], "unknown:", r["unknown_fact_ids"], "PASS" if r["ok"] else "FAIL")
except Exception as e:
    print("TC12 FAILED with exception:", e)

try:
    req = urllib.request.Request(BASE + "/api/forward", data=b"{}", headers={"Content-Type":"application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=5) as r:
        print("TC13 missing fact_ids key -> unexpected 200", r.read())
except urllib.error.HTTPError as e:
    body = json.loads(e.read())
    print("TC13 missing fact_ids key -> HTTP", e.code, body, "PASS" if e.code == 400 else "FAIL")

# Backward chaining: success and deliberate failure
print("\n--- Backward chaining tests ---")
r = post("/api/backward", {"fact_ids": ["f01","f07","f08","f09","f31"], "goal_type":"disease", "goal_id":"dengue"})
print("TC14 prove dengue from dengue facts -> proven:", r["proven"], "PASS" if r["proven"] else "FAIL")

r = post("/api/backward", {"fact_ids": ["f01","f07","f08","f09","f31"], "goal_type":"disease", "goal_id":"malaria"})
print("TC15 prove malaria from dengue facts (should fail) -> proven:", r["proven"], "PASS" if not r["proven"] else "FAIL")
print("       attempted rule lines include failure diagnostics:", any("FAILED" in l["text"] for l in r["reasoning_lines"]))

r = post("/api/backward", {"fact_ids": ["f01","f10","f13","f31"], "goal_type":"action", "goal_id":"rest_fluids_pain_relief"})
print("TC16 prove chikungunya recommend action -> proven:", r["proven"], "PASS" if r["proven"] else "FAIL")

# Knowledge base introspection
kb = get("/api/facts")
rl = get("/api/rules")
print(f"\nKnowledge base size -> facts={kb['count']} rules={len(rl['rules'])}",
      "PASS" if kb['count'] >= 20 and len(rl['rules']) >= 20 else "FAIL")

print("\nAll API tests completed.")
