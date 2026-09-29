// =============================================================================
// app.js - Frontend logic for the Febrile Illness Advisory Expert System.
// Talks to the Prolog HTTP API (server.pl) via fetch(). No frameworks.
// =============================================================================

const state = {
  facts: [],              // [{id, term, meaning, source}]
  rules: [],
  goals: { diseases: [], actions: [] },
  examples: [],
  selected: new Set(),    // selected fact ids
  lastResult: null
};

// Grouping of fact ids into UI categories (kept in sync with prolog/facts.pl)
const FACT_GROUPS = [
  { title: "Fever", ids: ["f01", "f02"] },
  { title: "Fever Duration (pick one)", ids: ["f03", "f04", "f05"], radio: true, radioName: "fever_duration" },
  { title: "Headache / Eye Pain", ids: ["f06", "f07", "f08"] },
  { title: "Joint & Muscle Pain", ids: ["f09", "f10", "f11", "f12"] },
  { title: "Skin & Bleeding Signs", ids: ["f13", "f14", "f15", "f16"] },
  { title: "Gastrointestinal", ids: ["f17", "f18", "f19", "f20", "f21"] },
  { title: "Respiratory", ids: ["f22", "f23", "f24", "f25", "f26"] },
  { title: "Other Systemic Signs", ids: ["f27", "f28", "f29", "f30"] },
  { title: "Exposure / Risk Factors", ids: ["f31", "f32", "f33", "f34", "f35"] }
];

// ---------------------------------------------------------------- utilities
async function apiGet(path) {
  const res = await fetch(path);
  const data = await res.json();
  if (!data.ok) throw new Error(data.error || "Unknown API error");
  return data;
}
async function apiPost(path, body) {
  const res = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  const data = await res.json().catch(() => ({ ok: false, error: "Invalid JSON response from server." }));
  if (!res.ok || !data.ok) throw new Error(data.error || `Server returned HTTP ${res.status}`);
  return data;
}
function el(tag, cls, html) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (html !== undefined) e.innerHTML = html;
  return e;
}
function toast(msg) {
  let t = document.getElementById("toast");
  if (!t) {
    t = el("div", "toast"); t.id = "toast";
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.classList.remove("show"), 3500);
}

// ---------------------------------------------------------------- tabs
function showTab(name) {
  document.querySelectorAll(".tab-panel").forEach(p => p.classList.remove("active"));
  document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
  document.getElementById("tab-" + name).classList.add("active");
  const btn = document.querySelector(`.tab-btn[data-tab="${name}"]`);
  if (btn) btn.classList.add("active");
}
document.getElementById("tabs").addEventListener("click", (e) => {
  const btn = e.target.closest(".tab-btn");
  if (btn) showTab(btn.dataset.tab);
});
document.querySelectorAll("[data-goto]").forEach(b =>
  b.addEventListener("click", () => showTab(b.dataset.goto))
);
document.getElementById("btn-start").addEventListener("click", () => showTab("input"));
document.getElementById("btn-to-inference").addEventListener("click", () => {
  document.getElementById("selected-count").textContent = state.selected.size;
  showTab("inference");
});

// ---------------------------------------------------------------- input tab
function renderFactGroups() {
  const wrap = document.getElementById("fact-groups");
  wrap.innerHTML = "";
  const byId = Object.fromEntries(state.facts.map(f => [f.id, f]));
  FACT_GROUPS.forEach(group => {
    const gDiv = el("div", "fact-group");
    gDiv.appendChild(el("h4", null, group.title));
    const chips = el("div", "fact-chips");
    group.ids.forEach(id => {
      const fact = byId[id];
      if (!fact) return;
      const label = el("label", "chip");
      label.title = fact.term;
      const input = document.createElement("input");
      input.type = group.radio ? "radio" : "checkbox";
      if (group.radio) input.name = group.radioName;
      input.value = id;
      input.addEventListener("change", () => {
        if (group.radio) {
          group.ids.forEach(otherId => { state.selected.delete(otherId); });
          chips.querySelectorAll(".chip").forEach(c => c.classList.remove("selected"));
        }
        if (input.checked) {
          state.selected.add(id);
          label.classList.add("selected");
        } else {
          state.selected.delete(id);
          label.classList.remove("selected");
        }
      });
      label.appendChild(input);
      label.appendChild(document.createTextNode(friendlyFactText(fact)));
      chips.appendChild(label);
    });
    gDiv.appendChild(chips);
    wrap.appendChild(gDiv);
  });
}
function friendlyFactText(fact) {
  // Strip trailing period and keep it short for a chip label
  const m = fact.meaning.replace(/\.$/, "");
  return m.length > 55 ? m.slice(0, 52) + "..." : m;
}
document.getElementById("btn-clear-input").addEventListener("click", () => {
  state.selected.clear();
  document.querySelectorAll("#fact-groups input").forEach(i => { i.checked = false; });
  document.querySelectorAll("#fact-groups .chip").forEach(c => c.classList.remove("selected"));
  toast("Cleared all selections.");
});

function applyFactSelection(ids) {
  state.selected = new Set(ids);
  document.querySelectorAll("#fact-groups input").forEach(input => {
    const on = state.selected.has(input.value);
    input.checked = on;
    input.closest(".chip").classList.toggle("selected", on);
  });
  document.getElementById("selected-count").textContent = state.selected.size;
}

// ---------------------------------------------------------------- inference tab
function renderGoalOptions() {
  const typeSel = document.getElementById("goal-type");
  const goalSel = document.getElementById("goal-id");
  function fill() {
    goalSel.innerHTML = "";
    const list = typeSel.value === "disease" ? state.goals.diseases : state.goals.actions;
    list.forEach(g => {
      const opt = document.createElement("option");
      opt.value = g.id;
      opt.textContent = g.label;
      goalSel.appendChild(opt);
    });
  }
  typeSel.addEventListener("change", fill);
  fill();
}

document.getElementById("btn-run-forward").addEventListener("click", async () => {
  try {
    const data = await apiPost("/api/forward", { fact_ids: Array.from(state.selected) });
    state.lastResult = { mode: "forward", data };
    renderForwardResults(data);
    showTab("results");
  } catch (err) {
    renderError(err);
    showTab("results");
  }
});

document.getElementById("btn-run-backward").addEventListener("click", async () => {
  try {
    const goalType = document.getElementById("goal-type").value;
    const goalId = document.getElementById("goal-id").value;
    if (!goalId) { toast("Pick a goal first."); return; }
    const data = await apiPost("/api/backward", {
      fact_ids: Array.from(state.selected),
      goal_type: goalType,
      goal_id: goalId
    });
    state.lastResult = { mode: "backward", data };
    renderBackwardResults(data);
    showTab("results");
  } catch (err) {
    renderError(err);
    showTab("results");
  }
});

// ---------------------------------------------------------------- results tab
function renderError(err) {
  const wrap = document.getElementById("results-content");
  wrap.innerHTML = "";
  wrap.appendChild(el("div", "error-box", "Something went wrong: " + escapeHtml(err.message || String(err))));
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function renderForwardResults(data) {
  const wrap = document.getElementById("results-content");
  wrap.innerHTML = "";

  const header = el("p", "muted", `Mode: <span class="badge method-forward">FORWARD CHAINING</span>`);
  wrap.appendChild(header);

  if (data.unknown_fact_ids && data.unknown_fact_ids.length) {
    wrap.appendChild(el("div", "error-box",
      "Note: these fact IDs were not recognised and were ignored: " + data.unknown_fact_ids.join(", ")));
  }

  wrap.appendChild(el("div", "section-title", "Final Conclusion(s)"));
  const summary = el("div", "result-summary");
  if (data.suspected_diseases.length === 0 && data.recommended_actions.length === 0) {
    summary.appendChild(el("p", "muted", "No conclusions were derived from the given facts."));
  }
  data.suspected_diseases.forEach(d => {
    const severe = /severe/i.test(d.id);
    const card = el("div", "conclusion-card" + (severe ? " severe" : ""));
    card.appendChild(el("div", "cc-title", "Suspected: " + escapeHtml(d.label)));
    card.appendChild(el("div", "cc-desc", escapeHtml(d.description)));
    summary.appendChild(card);
  });
  data.recommended_actions.forEach(a => {
    const card = el("div", "conclusion-card");
    card.appendChild(el("div", "cc-title", "Recommendation"));
    card.appendChild(el("div", "cc-action", escapeHtml(a.label)));
    summary.appendChild(card);
  });
  wrap.appendChild(summary);

  wrap.appendChild(el("div", "section-title", `Facts Used (${data.facts_used.length})`));
  const factsPills = el("div", "pill-list");
  data.facts_used.forEach(f => factsPills.appendChild(el("span", "pill", escapeHtml(f))));
  if (data.facts_used.length === 0) factsPills.appendChild(el("span", "pill", "(none - empty input)"));
  wrap.appendChild(factsPills);

  wrap.appendChild(el("div", "section-title", `Rules Applied (${data.rules_fired.length})`));
  const rulesPills = el("div", "pill-list");
  data.rules_fired.forEach(r => rulesPills.appendChild(el("span", "pill", r)));
  if (data.rules_fired.length === 0) rulesPills.appendChild(el("span", "pill", "(none fired)"));
  wrap.appendChild(rulesPills);

  wrap.appendChild(el("div", "section-title", "Reasoning Chain (step by step)"));
  if (data.reasoning_steps.length === 0) {
    wrap.appendChild(el("p", "muted", "No rules fired, so there is no reasoning chain to show."));
  }
  data.reasoning_steps.forEach(step => {
    const box = el("div", "trace-step");
    box.appendChild(el("div", "ts-rule", `Step ${step.step_number} &mdash; Rule ${step.rule_id}`));
    box.appendChild(el("div", null, escapeHtml(step.rule_explanation)));
    box.appendChild(el("div", "ts-arrow", "IF:"));
    step.conditions.forEach(c => box.appendChild(el("span", "ts-cond", "&bull; " + escapeHtml(c))));
    box.appendChild(el("div", "ts-arrow", "THEN:"));
    box.appendChild(el("div", "ts-concl", escapeHtml(step.conclusion)));
    wrap.appendChild(box);
  });
}

function renderBackwardResults(data) {
  const wrap = document.getElementById("results-content");
  wrap.innerHTML = "";

  const header = el("p", "muted", `Mode: <span class="badge method-backward">BACKWARD CHAINING</span> &nbsp; Goal type: ${escapeHtml(data.goal_type)} &nbsp; Goal: ${escapeHtml(data.goal_id)}`);
  wrap.appendChild(header);

  if (data.unknown_fact_ids && data.unknown_fact_ids.length) {
    wrap.appendChild(el("div", "error-box",
      "Note: these fact IDs were not recognised and were ignored: " + data.unknown_fact_ids.join(", ")));
  }

  wrap.appendChild(el("div", "section-title", "Final Conclusion"));
  const summary = el("div", "result-summary");
  const card = el("div", "conclusion-card" + (data.proven ? "" : " severe"));
  card.appendChild(el("div", "cc-title", data.proven ? "GOAL PROVEN ✓" : "GOAL NOT PROVEN ✗"));
  card.appendChild(el("div", "cc-desc",
    data.proven
      ? "The selected goal is supported by the facts you provided, via the reasoning chain below."
      : "The selected goal could NOT be established from the facts you provided. See the attempted rules below."));
  summary.appendChild(card);
  wrap.appendChild(summary);

  wrap.appendChild(el("div", "section-title", "Recursive Reasoning Chain"));
  const box = el("div", "bc-lines");
  const text = data.reasoning_lines.map(l => l.text).join("\n")
    .replace(/successfully PROVEN\./, '<span class="proven">successfully PROVEN.</span>')
    .replace(/could NOT be proven/, '<span class="not-proven">could NOT be proven</span>');
  box.innerHTML = text;
  wrap.appendChild(box);
}

// ---------------------------------------------------------------- knowledge base tab
function renderFacts() {
  const tbody = document.querySelector("#facts-table tbody");
  tbody.innerHTML = "";
  state.facts.forEach(f => {
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${f.id}</td><td class="mono">${escapeHtml(f.term)}</td><td>${escapeHtml(f.meaning)}</td><td>${escapeHtml(f.source)}</td>`;
    tbody.appendChild(tr);
  });
  document.getElementById("fact-count").textContent = state.facts.length;
}
function renderRules() {
  const tbody = document.querySelector("#rules-table tbody");
  tbody.innerHTML = "";
  state.rules.forEach(r => {
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${r.id}</td><td>${r.level}</td>
      <td class="mono">${r.conditions.map(escapeHtml).join("<br>AND ")}</td>
      <td class="mono">${escapeHtml(r.conclusion)}</td>
      <td>${escapeHtml(r.explanation)}</td>
      <td class="src">${r.source.split(" | ").map(escapeHtml).join("<br><br>")}</td>`;
    tbody.appendChild(tr);
  });
  document.getElementById("rule-count").textContent = state.rules.length;
}
document.querySelectorAll(".kb-subtab-btn").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".kb-subtab-btn").forEach(b => b.classList.remove("active"));
    document.querySelectorAll(".kb-sub-panel").forEach(p => p.classList.remove("active"));
    btn.classList.add("active");
    document.getElementById("kb-" + btn.dataset.sub).classList.add("active");
  });
});

// ---------------------------------------------------------------- demo tab
function renderExamples() {
  const wrap = document.getElementById("examples-list");
  wrap.innerHTML = "";
  state.examples.forEach(ex => {
    const card = el("div", "example-card");
    const left = el("div");
    left.appendChild(el("div", "ex-title", escapeHtml(ex.name)));
    left.appendChild(el("div", "ex-desc", escapeHtml(ex.description)));
    card.appendChild(left);
    const actions = el("div", "example-actions");
    const fBtn = el("button", "btn btn-primary btn-sm", "Run Forward");
    fBtn.addEventListener("click", async () => {
      applyFactSelection(ex.fact_ids);
      try {
        const data = await apiPost("/api/forward", { fact_ids: ex.fact_ids });
        renderForwardResults(data);
        showTab("results");
      } catch (err) { renderError(err); showTab("results"); }
    });
    const loadBtn = el("button", "btn btn-ghost btn-sm", "Load into Input");
    loadBtn.addEventListener("click", () => {
      applyFactSelection(ex.fact_ids);
      showTab("input");
      toast(`Loaded "${ex.name}" (${ex.fact_ids.length} facts).`);
    });
    actions.appendChild(loadBtn);
    actions.appendChild(fBtn);
    card.appendChild(actions);
    wrap.appendChild(card);
  });
}

// ---------------------------------------------------------------- boot
async function boot() {
  try {
    const [factsData, rulesData, goalsData, examplesData] = await Promise.all([
      apiGet("/api/facts"),
      apiGet("/api/rules"),
      apiGet("/api/goals"),
      apiGet("/api/examples")
    ]);
    state.facts = factsData.facts;
    state.rules = rulesData.rules;
    state.goals = { diseases: goalsData.diseases, actions: goalsData.actions };
    state.examples = examplesData.examples;

    renderFactGroups();
    renderGoalOptions();
    renderFacts();
    renderRules();
    renderExamples();
  } catch (err) {
    document.getElementById("fact-groups").innerHTML =
      `<div class="error-box">Could not load the knowledge base from the backend: ${escapeHtml(err.message)}.
       Make sure the Prolog server (swipl main.pl) is running.</div>`;
  }
}
boot();
