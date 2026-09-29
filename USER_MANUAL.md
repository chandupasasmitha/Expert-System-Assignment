# User Manual

**Febrile Illness Advisory Expert System**

This manual is written for someone who has **never seen this project
before** - a lecturer, examiner, or fellow student running it for the
first time. Follow the steps in order.

> :warning: This is an educational university assignment demo. It is **not**
> a real medical tool. Do not use it to make real health decisions.

---

## 1. System Purpose

This is an Expert System that takes symptoms and exposure/risk factors you
report, reasons over a documented medical knowledge base (35 facts, 36
rules), and produces:

- one or more **suspected illnesses** (out of 9 possible febrile illnesses)
- a matching **recommended next action**
- a full, step-by-step **explanation** of exactly how it reached that
  conclusion (never just a bare answer)

It can reason in two directions: **forward chaining** (start from your
symptoms, see what conclusions they support) and **backward chaining**
(pick a specific illness or action and ask "can this be proven from my
symptoms?").

## 2. Required Software

- **SWI-Prolog**, version 9.0 or later. This is the *only* thing you need
  to install. Get it from https://www.swi-prolog.org/download/stable, or:
  - Ubuntu/Debian: `sudo apt-get install -y swi-prolog-nox`
  - macOS (Homebrew): `brew install swi-prolog`
  - Windows: run the official installer
- A web browser (Chrome, Firefox, Edge or Safari - any modern browser).

Nothing else. No Node.js, no Python packages, no database, no internet
connection needed once SWI-Prolog is installed (the app is fully local).

## 3. Installation

1. Obtain the project folder (unzip the delivered archive, or copy the
   `expert-system/` folder to your computer).
2. Open a terminal (Command Prompt / PowerShell on Windows, Terminal on
   macOS/Linux).
3. Check SWI-Prolog is installed:
   ```
   swipl --version
   ```
   You should see a version number printed (e.g. `SWI-Prolog version
   9.0.4`). If you get "command not found", install SWI-Prolog first (see
   Section 2) and try again.

There is no further installation step - no `npm install`, no `pip
install`, nothing to compile.

## 4. Starting the System

1. In your terminal, navigate into the project's `prolog` folder:
   ```
   cd expert-system/prolog
   ```
2. Start the server:
   ```
   swipl main.pl
   ```
3. Wait for this message to appear:
   ```
   =========================================================
   Febrile Illness Advisory Expert System - server started
   Open your browser at:  http://localhost:8000/
   =========================================================
   Press Ctrl+C to stop the server.
   ```
   (You may also see one or two harmless yellow "Warning: Singleton
   variable" lines above this - these are just Prolog style notices, not
   errors, and can be ignored.)
4. **Leave this terminal window open** - closing it stops the server.

If you see an error instead, mentioning the port is already in use, run
this instead and use port 8001 in the next step:
```
PORT=8001 swipl main.pl              (macOS / Linux)
$env:PORT=8001; swipl main.pl        (Windows PowerShell)
set PORT=8001 && swipl main.pl       (Windows Command Prompt)
```

## 5. Opening the UI

Open your web browser and go to:

```
http://localhost:8000/
```

(or `http://localhost:8001/` if you used the alternate port above).

You should see the **Home** page with the title "Febrile Illness Advisory
Expert System" and a row of tabs at the top: Home, 1. Input, 2. Inference,
3. Results, Knowledge Base, Demo / Testing.

## 6. Entering Information

1. From the Home page, click **"Start a Consultation"** (or click the
   **"1. Input"** tab directly).
2. You will see groups of clickable "chips" - Fever, Fever Duration,
   Headache/Eye Pain, Joint & Muscle Pain, Skin & Bleeding Signs,
   Gastrointestinal, Respiratory, Other Systemic Signs, and Exposure/Risk
   Factors.
3. Click every chip that applies to the scenario you want to test. A
   selected chip turns blue. Clicking it again de-selects it.
   - "Fever Duration" only lets you pick **one** option at a time (short,
     medium, or long) since these are mutually exclusive.
   - You do not have to select anything at all - leaving everything blank
     tests the "no symptoms" case (no rule fires, and the system says so).
4. Click **"Continue to Inference"**.

*(Tip: you don't have to work this out yourself - see Section 11 for
ready-made example inputs, or use the Demo tab described in Section 13.)*

## 7. Running Forward Chaining

1. On the **"2. Inference"** tab, you'll see how many facts you selected.
2. Under **"Forward Chaining"** (the left-hand box), click **"Run Forward
   Chaining"**.
3. You are taken to the **Results** tab automatically.

Forward chaining starts from your reported facts and fires every rule that
applies, deriving new facts step by step, until nothing more can be
derived - arriving at whatever conclusion(s) your facts genuinely support.

## 8. Running Backward Chaining

1. On the **"2. Inference"** tab, under **"Backward Chaining"** (the
   right-hand box):
   - Choose a **Goal type**: "Suspected disease" or "Recommended action".
   - Choose a specific **Goal** from the dropdown (e.g. "Dengue Fever", or
     "Seek emergency medical care immediately...").
2. Click **"Run Backward Chaining"**.
3. You are taken to the **Results** tab automatically.

Backward chaining starts from the *specific goal you picked* and works
backward, trying to prove it using your reported facts. It will clearly
state whether the goal was **PROVEN** or **NOT PROVEN**, and show exactly
why.

## 9. Understanding Results

The **Results** tab always shows, top to bottom:

1. A badge showing which mode you used (**FORWARD CHAINING** or **BACKWARD
   CHAINING**).
2. **Final Conclusion(s)** - the suspected disease(s) and/or recommended
   action(s) (forward chaining), or whether your chosen goal was proven
   (backward chaining). A red-tinted card means a severe/urgent result.
3. (Forward mode) **Facts Used** and **Rules Applied** - pill-style tags
   listing every input fact and every rule ID that fired.
4. **Reasoning Chain**:
   - *Forward mode*: a numbered list of steps, each showing which rule
     fired, its IF conditions, and its THEN conclusion, in the exact order
     they fired.
   - *Backward mode*: an indented, terminal-style trace showing the goal,
     which rule was tried to prove it, its sub-goals, and so on down to
     the known facts (or, if it failed, exactly which rules were tried and
     which conditions were missing).

## 10. Understanding Explanations

The system is designed to **never** just show you an answer. Every result
traces back through the exact rules that were used. If you want to verify
a rule's exact wording or source, switch to the **Knowledge Base** tab and
look up its Rule ID (e.g. "r13") in the Rules table - it shows the same
Rule ID, its full IF/THEN, and the plain-English explanation used in the
Results tab, plus which reference source it came from.

## 11. Example Inputs

| Scenario | Symptoms to select |
|---|---|
| Classic (non-severe) Dengue | Fever, Severe headache, Pain behind the eyes, Joint pain, Lives in/visited a mosquito area |
| Severe Dengue | (all of the above) + Persistent vomiting, Bleeding gums |
| Malaria | Fever, Chills and sweats, Travel to a malaria area |
| Typhoid | Fever > 7 days, Stomach/abdominal pain, Rash with rose-coloured spots, Contaminated food/water |
| COVID-19 | Cough, Sore throat, Runny nose, Sneezing, Loss of smell/taste, Contact with a COVID-19 case |
| Common Cold | Runny nose, Sneezing, Sore throat, Cough (no fever) |

(Full list of all 12 built-in scenarios: see Section 13, the Demo tab.)

## 12. Example Outputs

For the "Classic Dengue" input above, running **Forward Chaining** produces:

- **Suspected: Dengue Fever** - "A mosquito-borne viral infection causing
  high fever, severe headache, pain behind the eyes and muscle/joint pain (WHO)."
- **Recommendation:** "Rest, drink plenty of fluids and use paracetamol for
  pain (avoid ibuprofen/aspirin); see a doctor at once if warning signs appear."
- **Reasoning Chain:** 3 steps (Rule r05 -> derives the dengue pattern;
  Rule r13 -> suspects dengue since no warning signs are present; Rule r25
  -> gives the recommendation).

## 13. Using the Demo Tab (fastest way to explore)

Click the **"Demo / Testing"** tab. You'll see 12 ready-made scenarios,
each with a short description, covering all 9 diseases plus 3 edge cases.
For each one you can:

- Click **"Run Forward"** to instantly load that scenario's facts and run
  forward chaining, jumping straight to the Results tab.
- Click **"Load into Input"** to load the facts into the Input tab without
  running anything yet, so you can inspect or modify the selection first.

This is the recommended way for an examiner to quickly see the system
cover every disease during a live demonstration.

## 14. Common Errors and What They Mean

| What you see | What it means | What to do |
|---|---|---|
| "Could not load the knowledge base from the backend..." on page load | The Prolog server isn't running, or isn't reachable at this address. | Check the terminal running `swipl main.pl` is still open and shows "server started". Refresh the browser. |
| A red box saying "Something went wrong: ..." after clicking Run | The server hit an unexpected input (e.g. no goal picked for backward chaining). | Read the message - it explains what was wrong. Common cause: you clicked "Run Backward Chaining" without selecting a Goal. |
| "these fact IDs were not recognised and were ignored: ..." | You (or a script calling the API directly) sent a fact ID that doesn't exist in the knowledge base. | Harmless - the system ignores unknown IDs and continues; check the Knowledge Base tab for valid fact IDs. |
| "GOAL NOT PROVEN" in backward chaining | This is not an error - it's a correct result. Your selected goal genuinely cannot be established from the facts you reported. | Read the reasoning chain below it; it lists exactly which rule(s) were tried and which condition(s) were missing. |
| Terminal shows `Warning: Singleton-marked variable...` | A harmless Prolog style warning from loading the code. | Ignore it - the server still starts and works normally. |
| Terminal shows an error and the server does not start | Usually port 8000 is already in use. | Run `PORT=8001 swipl main.pl` instead, and browse to `http://localhost:8001/`. |

If you get stuck beyond what's listed here, see the **Troubleshooting**
table in `README.md`.
