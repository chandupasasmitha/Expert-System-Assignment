# Febrile Illness Advisory Expert System

An Expert System, built in **SWI-Prolog**, that provides a preliminary
differential assessment across nine common febrile illnesses (Dengue,
Severe Dengue, Malaria, Typhoid, COVID-19, Influenza, Common Cold,
Chikungunya, Leptospirosis) from self-reported symptoms and exposure
factors - with **genuine forward chaining**, **genuine backward chaining**,
and a full **explanation facility** that shows every fact used and every
rule fired, never just a bare answer.

Built for a university Expert Systems assignment. The submitted report is
`docs/report/Expert_System_Report.pdf`.

> :warning: Educational demo only. **Not** a real medical diagnostic tool.

---

## Project Overview

| | |
|---|---|
| Domain | Preliminary triage/differential-assessment advisor for 9 febrile illnesses |
| Technology | SWI-Prolog (knowledge base, both inference engines, and the HTTP API/backend, all in Prolog) + a plain HTML/CSS/JS frontend served by the same process |
| Facts | 35, each with a cited source (see the report, Section 4) |
| Rules | 36, across 4 reasoning levels (raw facts -> pattern -> disease -> action) |
| Inference | Forward chaining (`prolog/inference_forward.pl`) and backward chaining (`prolog/inference_backward.pl`), both implemented as generic engines that interpret the same `rule/4` knowledge base |
| Explanation | `prolog/explanation.pl` turns every trace/proof-tree into a plain-English reasoning chain |

## Features

- Structured, checkbox/radio-based symptom & exposure input (no Prolog syntax typing required)
- **Forward chaining**: data-driven, fires every applicable rule from your reported facts until a fixpoint is reached
- **Backward chaining**: goal-driven, pick a specific disease or action to investigate and watch the engine recursively try to prove it, including a full explanation when it *fails*
- Full reasoning chain / explanation for every result (facts used, rules applied, step-by-step derivation)
- Knowledge Base inspector page (browse every fact and rule actually loaded)
- 12 predefined demo scenarios for one-click examiner testing
- Robust error handling - the server never crashes on bad/missing input

## Architecture

```
                 ┌───────────────────────────┐
                 │        Person (User)       │
                 └──────────────┬──────────────┘
                                │  interacts with
                                ▼
                 ┌───────────────────────────┐
                 │   Frontend UI (browser)     │
                 │  frontend/index.html/css/js │
                 │  Home → Input → Inference →  │
                 │  Results, Knowledge Base,    │
                 │  Demo tabs                   │
                 └──────────────┬──────────────┘
                                │  fetch() JSON over HTTP
                                ▼
                 ┌───────────────────────────┐
                 │   Backend / API (Prolog)    │
                 │   prolog/server.pl           │
                 │   /api/forward /api/backward │
                 │   /api/facts /api/rules       │
                 │   /api/goals /api/examples    │
                 └──────────────┬──────────────┘
                                │  calls
                 ┌──────────────┴──────────────┐
                 ▼                              ▼
   ┌───────────────────────┐      ┌───────────────────────┐
   │  Forward-Chaining       │      │  Backward-Chaining      │
   │  Engine                 │      │  Engine                  │
   │  inference_forward.pl   │      │  inference_backward.pl   │
   └───────────┬─────────────┘      └───────────┬─────────────┘
               │        both interpret the same             │
               └───────────────────┬──────────────────────┘
                                   ▼
                    ┌───────────────────────────┐
                    │   Knowledge Base             │
                    │   facts.pl  (35 facts)        │
                    │   rules.pl  (36 rules)         │
                    │   knowledge_base.pl (helpers)  │
                    └──────────────┬──────────────┘
                                   │  trace / proof tree
                                   ▼
                    ┌───────────────────────────┐
                    │   Explanation Facility        │
                    │   explanation.pl               │
                    │   trace/proof → plain English   │
                    └──────────────┬──────────────┘
                                   │  JSON reasoning_steps /
                                   │  reasoning_lines
                                   ▼
                (back up through server.pl → the UI's Results tab)
```

The explanation path is not a side-channel: the *same* JSON response that
carries the conclusion also carries `reasoning_steps` (forward) or
`reasoning_lines` (backward), so the UI always renders the answer and its
justification together.

## Technology Stack

- **SWI-Prolog** (>= 9.0) - knowledge base, inference engines, explanation facility, and HTTP server (via `library(http/thread_httpd)`, `http_dispatch`, `http_json`)
- **Vanilla HTML/CSS/JavaScript** - no frontend framework, no build step, no `npm install`
- **Python 3** (optional) - only used to run the automated API test suite (`tests/api_test.py`); not required to run the system itself

## Project Structure

```
expert-system/
├── prolog/
│   ├── facts.pl               # static domain facts, sources, disease/action labels
│   ├── rules.pl                # the 36-rule knowledge base
│   ├── knowledge_base.pl        # aggregation + label/lookup helpers
│   ├── inference_forward.pl     # generic forward-chaining engine
│   ├── inference_backward.pl    # generic backward-chaining engine
│   ├── explanation.pl           # trace/proof-tree → plain English
│   ├── server.pl                # HTTP API + static file serving
│   └── main.pl                  # entry point (swipl main.pl)
├── frontend/
│   ├── index.html               # Home/Input/Inference/Results/KB/Demo tabs
│   ├── css/style.css
│   └── js/app.js                # all frontend logic, talks to /api/*
├── tests/
│   ├── smoke_test.pl            # Prolog-level engine tests (no server needed)
│   └── api_test.py              # end-to-end HTTP API test suite
├── docs/
│   └── report/
│       ├── Expert_System_Report.pdf  # the submitted report
│       ├── build_report.py           # regenerates report.html from the live system
│       ├── make_pdf.js               # renders report.html to PDF (Chrome)
│       └── img/                      # UI screenshots used in the report
├── USER_MANUAL.md
└── README.md                    # this file
```

## Prerequisites

- **SWI-Prolog 9.0 or later** (the only required runtime). Install:
  - Ubuntu/Debian: `sudo apt-get update && sudo apt-get install -y swi-prolog-nox` (or `swi-prolog` for the full desktop version)
  - macOS: `brew install swi-prolog`
  - Windows: download the installer from https://www.swi-prolog.org/download/stable
- A modern web browser (Chrome, Firefox, Edge, Safari)
- *(optional, for automated tests only)* Python 3.8+

No Node.js, npm, pip packages, databases, or any other tooling is required.

## Installation

```bash
# 1. Get the project (unzip it, or clone it, wherever you were given it)
cd expert-system

# 2. Verify SWI-Prolog is installed
swipl --version
# should print something like: SWI-Prolog version 9.0.4 ...
```

That's it - there is no dependency-installation step. The knowledge base,
inference engines and HTTP server are pure SWI-Prolog using only its
standard library; the frontend is plain HTML/CSS/JS served directly by the
Prolog process.

## Configuration

The only configurable value is the **port** the server listens on, via the
`PORT` environment variable (defaults to `8000` if unset):

```bash
PORT=8080 swipl main.pl
```

## Running the Application

```bash
cd expert-system/prolog
swipl main.pl
```

You should see:

```
=========================================================
Febrile Illness Advisory Expert System - server started
Open your browser at:  http://localhost:8000/
=========================================================
Press Ctrl+C to stop the server.
```

Now open **http://localhost:8000/** in your browser. Press `Ctrl+C` in the
terminal to stop the server.

*(If port 8000 is already in use, run `PORT=8001 swipl main.pl` instead and
open `http://localhost:8001/`.)*

## Using the System

1. **Home tab** - read the domain overview, click "Start a Consultation".
2. **Input tab** - tick every symptom/exposure that applies (grouped by
   category); fever duration is a single-choice group. Click "Continue to
   Inference".
3. **Inference tab** - choose:
   - **Forward Chaining** - just click "Run Forward Chaining" to let the
     system reason from your facts to whatever conclusion(s) they support.
   - **Backward Chaining** - pick a goal type (a specific disease, or a
     specific recommended action) and a goal from the dropdown, then click
     "Run Backward Chaining" to see whether *that specific* goal can be
     proven from your facts.
4. **Results tab** - see the final conclusion(s), the facts used, the rules
   applied, and the complete step-by-step reasoning chain.
5. **Knowledge Base tab** - browse every fact and rule in the system
   (useful for a viva/examiner walkthrough).
6. **Demo tab** - one-click predefined scenarios (see the Testing section).

## Forward Chaining Example

Selecting: fever, severe headache, retro-orbital pain, joint pain, and
"lives in/visited a mosquito area" and clicking **Run Forward Chaining**
produces:

```
Step 1 — Rule r05
  IF: fever AND severe headache AND retro-orbital pain AND joint pain
  THEN: [derived pattern] dengue_pattern

Step 2 — Rule r13
  IF: [derived] dengue_pattern AND NOT([derived] hemorrhagic_warning_signs)
  THEN: Suspected: Dengue Fever

Step 3 — Rule r25
  IF: suspected(dengue)
  THEN: Recommendation: Rest, drink plenty of fluids and use paracetamol for
        pain (avoid ibuprofen/aspirin); see a doctor at once if warning
        signs appear.

Final conclusion: Suspected Dengue Fever → rest, fluids, paracetamol.
```

This is a genuine 3-level chain: raw facts -> derived pattern -> suspected
disease -> recommendation, exactly the "User Input -> Facts -> Rules
Applied -> Reasoning -> Final Conclusion" flow the assignment requires.

## Backward Chaining Example

With the same facts loaded, choosing goal type **"Suspected disease"** and
goal **"Malaria"**, then **Run Backward Chaining**, correctly reports the
goal as **NOT PROVEN**, and explains exactly why:

```
Goal: Suspected: Malaria
  Tried Rule r15 (Fever, chills and sweats after time in a malaria area...) - FAILED
    Missing/unproven conditions: [derived] malaria_pattern
RESULT: Goal could NOT be proven from the known facts.
```

Choosing goal **"Dengue"** instead succeeds and shows the full recursive
proof (goal -> rule r13 -> sub-goal dengue_pattern -> rule r05 -> 4 known
facts), exactly mirroring the worked example format in the assignment
brief.

## Testing

```bash
# Prolog-level engine tests (no server needed)
cd expert-system/prolog
swipl ../tests/smoke_test.pl

# Full end-to-end HTTP API test suite (server must be running separately)
swipl main.pl &            # start the server first
python3 ../tests/api_test.py
```

18 automated test cases are run: 9 one-per-disease, 3 safety-net cases
(long fever, fever after malaria-area travel, short high fever), an
empty-input case, 2 invalid-input cases and 3 backward chaining tests
including a deliberate proof failure. The last run is saved in
`tests/last_run_output.txt` (18/18 PASS), and the report's Section 7 has
the full expected-vs-actual table. If the server runs on another port,
set it for the test script too: `PORT=8001 python3 ../tests/api_test.py`.

## Knowledge Base

35 facts and 36 rules, organised into 4 reasoning levels (raw facts ->
intermediate clinical pattern -> suspected disease -> recommended action).
Every fact and rule cites a WHO, CDC, MSF or NHS page (checked on
29 Sep 2026); no rule is the author's own invention. The full fact table,
rule table, sources and quoted evidence are in the report (Section 4 and
Annexes A-B). The same data is also
browsable live in the running app's **Knowledge Base tab**, or via
`GET /api/facts` and `GET /api/rules`.

## Inference Engine

Both engines are **generic** - they contain no disease-specific logic at
all, only the general algorithm, and interpret the same `rule(RuleID,
Conditions, Conclusion, Explanation)` facts from `prolog/rules.pl`:

- **Forward chaining** (`inference_forward.pl`): starts from the reported
  facts, and repeatedly fires the first rule (in knowledge-base order)
  whose conditions are all satisfied and whose conclusion is new, adding
  that conclusion to working memory, until a full pass finds nothing left
  to fire (fixpoint). One rule fires per cycle so that negated conditions
  are always checked against a fully up-to-date working memory.
- **Backward chaining** (`inference_backward.pl`): starts from a chosen
  goal and recursively tries to prove it - either it's already a known
  fact, or some rule concludes it and *all* of that rule's conditions can
  themselves be recursively proven (with `not(Cond)` proven by Cond's
  *failure* to be provable). If every candidate rule fails, the engine
  reports exactly which rules were tried and which of their conditions
  were missing.

## Explanation Facility

`prolog/explanation.pl` converts the forward engine's firing trace into an
ordered list of `step(N, RuleID, Conditions, Conclusion, RuleText)` terms,
and the backward engine's recursive proof tree (or failure-attempt report)
into an indented list of plain-English lines. The API returns both as JSON
(`reasoning_steps` / `reasoning_lines`) and the frontend renders them
directly in the Results tab - the explanation is never an afterthought
bolted onto a bare answer.

## Troubleshooting

| Problem | Fix |
|---|---|
| `swipl: command not found` | Install SWI-Prolog (see Prerequisites) and ensure it's on your `PATH`. |
| `Address already in use` / server won't start | Another process is using port 8000. Run `PORT=8001 swipl main.pl` and open `http://localhost:8001/` instead. |
| Browser shows a blank page or "Could not load the knowledge base" | The Prolog server isn't running, or you opened the HTML file directly (`file://...`) instead of via `http://localhost:8000/`. Always start it with `swipl main.pl` and use the printed URL. |
| Frontend loads but buttons do nothing | Open the browser's developer console (F12) for JS errors; make sure you're not blocking `localhost` requests via a browser extension. |
| `permission_error` or similar Prolog warnings on startup about singleton variables | These are harmless style warnings, not errors - the server still starts. |
| Changes to `.pl` files don't take effect | Stop the server (`Ctrl+C`) and restart it (`swipl main.pl`); Prolog only loads files once at startup. |
| Want to reset everything | The system holds no persistent state (no database/files are written) - every request starts from the facts *you* send in that request. Just refresh the browser. |

---

See **`USER_MANUAL.md`** for a step-by-step guide written for someone who
has never seen this project before, and
**`docs/report/Expert_System_Report.pdf`** for the full assignment report.

## Rebuilding the report (optional)

```bash
cd expert-system/prolog && swipl main.pl          # terminal 1
cd expert-system/docs/report                      # terminal 2
STUDENT_NAME="..." STUDENT_ID="..." REPO_URL="..." python3 build_report.py
npm install puppeteer-core && node make_pdf.js    # needs Google Chrome
```
