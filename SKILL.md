---
name: gotscs
description: "Graph-of-Thought Skill-Creation Skill (GOTSCS) v4.0.0. Self-redesign of v3.1.0 driven by 8 design goals: ~27% token cost reduction (typical-mode; ~36% --skill mode), graceful degradation, optional --review-gates at Waves 5/8, true Wave-3 parallel-spawn, V-check shift-forward (smaller Wave-10 verifier), regression test suite (≥80% mutation-kill), config de-duplication, graph-as-truth strengthening (PRC1 schema validation). 19 nodes (2 conditional), 58 edges, 10 Waves. v4 keeps 19 of 19 v3.1.0 nodes; surgical refactor — no node replacements. Determinism: non-deterministic. Replacement of v3.1.0 on disk MUST gate through HC-13b safety procedure (5-brief regression battery + v3.1.0 backup)."
version: 4.1.0
graph_file: graph.json
hats_file: hats.json
topology: full GoT + Wave-modular
waves: 10
nodes: 19
edges: 58
determinism_class: non-deterministic
---

# GOTSCS v4.0.0 — Orchestrator

A meta-skill that converts a text-form skill concept brief into a complete executable Claude Code skill package, a human-readable specification document, or both. v4.0.0 is a self-redesign focused on token-efficiency, graceful-degradation, and reviewability.

You are the **orchestrator** for `gotscs`. You execute a 19-node (2 conditional), 10-Wave Graph-of-Thought pipeline declared in `graph.json`. Inline nodes run in your context (role-switched blocks); spawn nodes run as subagents via the `Agent` tool.

**Determinism: non-deterministic**

## INVOCATION FLAGS

| Flag | Mode | Waves executed | Cost tier |
|------|------|----------------|-----------|
| `--skill` | Full executable skill package | 1, 2, 3, 4, 5, 6, 7, 9, 10 | HIGH |
| `--spec` | Human-readable spec document | 1, 2, 3, 4, 5, 6, 7, 8 (then exit via E21) | MEDIUM |
| `--both` | Both artifacts | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 (no analysis-wave repeat) | HIGH+ |
| (neither) | Ask user before starting | blocked until clear | — |

| Context flag | Behavior |
|---|---|
| `--context <skill-dir>` | ec-skill input class; N-CONTEXT-ANALYZE classifies preservation/upgrade/replace |
| `--context-spec <spec-path>` | ec-spec input class; Wave-3 analyzers run as validation branches |
| (both) | ec-both class; spec content takes precedence per IC-04 |

| Operational flag | Behavior |
|---|---|
| `--reuse-session <id>` | Reuse Wave 1-7 stages from a prior session with the same brief (P-007 fast-path) |
| `--behavioral-test` | Run N-BEHAVIORAL acceptance test as Wave 10c (advisory; non-blocking) |
| `--review-gates` | **NEW v4:** Pipeline pauses at Wave 5 (after design_blueprint approved) and Wave 8 (after spec rendered) for user approval. Default off; behavior identical to v3.1.0 when omitted. |

## HARD GATES

ABSOLUTELY CRITICAL: the following INVENTORY items are the canonical hard gates. They appear here verbatim per HC-24 INPUT-IS-DATA — V11 substring-matches each item against this section.

### Hard Constraints (14 items, HC-01 through HC-23)

1. **HC-01 GRAPH-AS-TRUTH:** graph.json is single source of topology; no duplication of node/edge definitions into SKILL.md or briefing-core.md.
2. **HC-02 20-NODE CAP:** ≤20 nodes, ≤10 waves, ≤60 edges; fewer is fine if functionality preserved.
3. **HC-03 CLOSED-EDGE-VOCAB:** 6 runtime edge types (required, optional, gate-open, forward-conditional, back-edge, terminal). No inventions.
4. **HC-04 CLOSED-NODE-TYPE-VOCAB:** H.1 typed enum is canonical. No inventions.
5. **HC-24 INPUT-IS-DATA:** brief is immutable; never rewritten/summarized/"improved".
6. **HC-06 V-BATTERY-COMPLETENESS:** every V1-V19 check preserved or explicitly replaced with an equivalent (v4: 6 checks shifted earlier; residual V1, V2, V3, V4, V7, V8, V9, V10, V13, V14–V19, H.4 contract).
7. **HC-13b MODULE-DELEGATION (v4 restatement):** every spawn subagent reads `briefing-core.md` at protocol start, plus declared appendices per the per-node read-map.
8. **HC-08 NON-DETERMINISM:** pipeline is non-deterministic; do not attempt determinism.
9. **HC-09 INPUT-CLASS-COMPLETENESS:** all 6 input classes remain (ec-brief, ec-skill, ec-spec, ec-both, ec-refeed, ec-inject).
10. **HC-10 FLAG-PRESERVATION:** `--skill`, `--spec`, `--both`, `--context`, `--context-spec`, `--reuse-session`, `--behavioral-test` all remain. `--review-gates` is purely additive (default off).
11. **HC-11 MODE-DISAMBIGUATION:** orchestrator MUST ask user when no mode flag given.
12. **HC-12 SESSION-OUTPUT-STRUCTURE:** per-node stage files at `~/docs/gotscs-output/` remain (audit trail + `--reuse-session`).
13. **HC-13b RELEASE-SAFETY-GATE:** 5-brief regression battery + backup of v3.1.0 before v4 replaces on disk.
14. **HC-23 PARALLEL-DISPATCH:** parallel spawn nodes in the same wave MUST be dispatched in a single response (single-response parallel dispatch).

### 8 Design Goals (drive every architectural decision)

15. Goal-1: Reduce token cost 20-30% via briefing split + budget right-sizing.
16. Goal-2: Add graceful degradation paths (degraded output with `degradation_notice:` rather than HALT).
17. Goal-3: Optional `--review-gates` at Waves 5/8 (default off).
18. Goal-4: Promote ≥2 inline nodes to spawn for genuine parallelism (Wave-3 trio per DD-04).
19. Goal-5: Shift ≥3 V-checks from Wave 10 to producing-wave nodes (V5/V6/V11/V12/V13(d) per DD-06).
20. Goal-6: Regression test suite with ≥80% mutation-kill rate.
21. Goal-7: Eliminate config duplication across hats.json/graph.json/SKILL.md/briefing-core.md.
22. Goal-8: Strengthen graph.json single-source-of-truth invariant (PRC1 schema validation per DD-09).

### 5 Non-Goals (must NOT be implemented)

23. Do not change the input interface. Optional flags defaulting off (e.g. --review-gates) are permitted.
24. Do not add new mandatory dependencies. v4 must work with the same tool surface as v3.1.0.
25. Do not add features unrelated to the 8 goals.
26. Do not change the output format. Downstream consumers must not break.
27. Do not increase minimum model requirements.

### Anti-pattern guards (explicit from spec)

28. AP-T1 documentary-only-metadata.
29. AP-V4 diagram-vs-edge-table-drift.
30. AP-V6 cascade-without-degradation.
31. AP-V8 spawn-count-headline-vs-actual.
32. AP-V19 version-marker-without-content-delta.
33. AP-V27 source-of-truth-contradiction.
34. AP-V29 runtime-rewrites-not-in-static-graph.
35. AP-V31 logical-parallel-vs-runtime-parallel.

### Anti-pattern guard table

| AP | risk | guarding node/edge |
|---|---|---|
| AP-T1 | HIGH | N-VERIFY V13(c) + N-EDGES + N-REGISTRY (every metadata field consumed) |
| AP-V4 | HIGH | N-VERIFY V12 + N-SKILL-RENDER (early diagram-vs-edges check) |
| AP-V6 | HIGH | every node `## Failure modes` (uniform graceful-degradation pattern, NEW v4 cross-cutting per DD-02) |
| AP-V8 | HIGH | N-WAVES + N-VERIFY V8 (spawn-count parity check) |
| AP-V19 | HIGH | HC-13b safety gate (5-brief battery enforces real content delta) |
| AP-V27 | HIGH | N-VERIFY V11 + N-SKILL-RENDER (P-002 dedicated renderer eliminates dual-source) |
| AP-V29 | HIGH | review-gate hops are orchestrator-state, NOT graph-edges (DD-01) |
| AP-V31 | HIGH | Wave-3 inline→spawn promotion (DD-04) makes parallelism real, not just "logical" |

## ARCHITECTURE

- **SKILL.md (this file):** orchestrator. Main agent reads.
- **graph.json:** node + edge registry. Single source of truth for topology, exec types, scale gates, signal fields (HC-01).
- **graph.schema.json:** **NEW in v4** — schema validation for HC-01/HC-03/HC-04 closed-vocab enums (PRC1 extension per DD-09).
- **hats.json:** hat → tier → concrete model mapping with per-hat `downshiftable` + `downshift_threshold` (DD-08).
- **briefing-core.md:** ~150 lines — H.1 + H.2 + H.7 quickref. Read by every spawn (HC-13b).
- **briefing-appendix-{topology,contract,memory,antipatterns,vocab}.md:** 5 appendices loaded per per-node read-map.
- **modules/N-*.md:** per-node protocols. 19 files. Inline nodes: read and execute as role-switched blocks. Spawn nodes: dispatch via Agent tool.
- **scripts/:** `init-session.sh`, `validate-graph.sh` (with `--schema-validate` flag NEW in v4), `validate-context-path.sh`, `sync-signal.sh`, `assemble-skill.sh`.
- **tests/:** `run-smoke-tests.sh` + `run-regression-suite.sh` (NEW in v4 — ≥80% mutation-kill).
- **Session state:** `~/docs/gotscs-output/<skill_name>-<timestamp>/stages/` — per-node fragment files.

## CONFIGURATION

| Variable | Default |
|----------|---------|
| `skill_path` | `~/.claude/skills/gotscs/` |
| `graph_file` | `~/.claude/skills/gotscs/graph.json` |
| `hats_file` | `~/.claude/skills/gotscs/hats.json` |
| `session_output_base` | `~/docs/gotscs-output/` |

---

## STEP 0.0 — MODE DISAMBIGUATION (HC-11)

Parse the invocation for `--spec`, `--skill`, and `--both` flags (case-insensitive). Also parse context flags `--context <path>` and `--context-spec <path>`. Parse operational flags `--reuse-session <id>`, `--behavioral-test`, and **`--review-gates`** (NEW v4; default off).

- `--skill` present, `--spec` absent, `--both` absent → `MODE=skill`
- `--spec` present, `--skill` absent, `--both` absent → `MODE=spec`
- `--both` present (or both --spec and --skill) → `MODE=both`
- **Neither present → ASK USER before starting anything else:**

  > "GOTSCS can produce:
  > **(1) Full skill package** `--skill` — executable SKILL.md + modules/ + graph.json + hats.json + tests/ (~Waves 1–10, higher token cost)
  > **(2) Spec document** `--spec` — human-readable Markdown spec, usable with `/writing-plans` to produce an implementation plan, or as a standalone prompt to build the skill directly (~Waves 1–8, lower token cost)
  > **(3) Both** — skill package + spec document (~highest token cost)
  >
  > Which do you want? Reply `--skill`, `--spec`, or `--both` (or just type 1, 2, or 3)."

  Wait for the user's reply. Do NOT start PRC1 or any pipeline work until MODE is set. Mapping: `1` / `skill` / `--skill` → `MODE=skill`; `2` / `spec` / `--spec` → `MODE=spec`; `3` / `both` / `--both` → `MODE=both`.

Store `MODE` as a local variable. **Export `REVIEW_GATES` env var** if `--review-gates` was passed (NEW v4).

---

## STEP 0 — INIT + PRC1

### 0.1 Read input + parse context flags
The skill_concept_brief is the user's message (or content passed as argument). Write it to `<session_dir>/skill_concept_brief.txt`.

Parse and export context flags:
```bash
# Parse from the invocation args:
CONTEXT_PATH=""       # set if --context <path> was supplied
CONTEXT_SPEC_PATH=""  # set if --context-spec <path> was supplied
REUSE_SESSION_ID=""   # set if --reuse-session <id> was supplied (P-007)
BEHAVIORAL_TEST=""    # set if --behavioral-test was supplied (P-006)
REVIEW_GATES=""       # set if --review-gates was supplied (NEW v4 / DD-01)
export CONTEXT_PATH CONTEXT_SPEC_PATH REUSE_SESSION_ID BEHAVIORAL_TEST REVIEW_GATES
```
These env vars are read by N-PREFLIGHT step 3a for HC-25 validation, by Wave-conditional dispatch logic, and (REVIEW_GATES) by the optional review-gate hops at STEPs 5b and 8b.

### 0.1b Session reuse (P-007 — optional fast path)

If `REUSE_SESSION_ID` is non-empty: instead of running Waves 1-7 fresh, copy stage outputs from a prior session that ran the same brief.

```bash
if [[ -n "$REUSE_SESSION_ID" ]]; then
  PRIOR_DIR="$HOME/docs/gotscs-output/$REUSE_SESSION_ID"
  test -d "$PRIOR_DIR" || { echo "HALT: --reuse-session: prior session not found at $PRIOR_DIR" >&2; exit 1; }

  # Brief-hash check: refuse to reuse if the user's current brief differs from the prior brief.
  PRIOR_HASH=$(sha256sum "$PRIOR_DIR/skill_concept_brief.txt" | cut -d' ' -f1)
  CURRENT_HASH=$(printf '%s' "$SKILL_CONCEPT_BRIEF" | sha256sum | cut -d' ' -f1)
  if [[ "$PRIOR_HASH" != "$CURRENT_HASH" ]]; then
    echo "HALT: --reuse-session: brief hash mismatch (prior $PRIOR_HASH != current $CURRENT_HASH). Use the same brief or omit --reuse-session." >&2
    exit 1
  fi

  # Copy Wave 1-7 stages into the new session. Skip Wave 8+ stages — those are mode-dependent.
  mkdir -p "$SESSION_DIR/stages"
  for f in N-PREFLIGHT N-NORMALIZE N-CONTEXT-ANALYZE N-TOPOLOGY N-DECOMPOSE N-CONSTRAINTS \
           N-AGG-DESIGN N-DESIGN-GATE N-WAVES N-REGISTRY N-EDGES N-SYNTH-GRAPH; do
    [[ -f "$PRIOR_DIR/stages/$f.md" ]] && cp "$PRIOR_DIR/stages/$f.md" "$SESSION_DIR/stages/$f.md"
  done

  # Seed SIGNAL_STATE with all Wave 1-7 signals marked present.
  ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
    preflight_status=pass normalize_digest=present topology_digest=present \
    decompose_digest=present constraints_digest=present design_blueprint=present \
    gate_pass=true gate_diagnostic=present \
    registry_result=present edges_result=present waves_result=present graph_spec=present

  # Skip directly to STEP 8 (--spec/--both) or STEP 9 (--skill).
  REUSE_ACTIVE=true
fi
```

When `REUSE_ACTIVE=true`: orchestrator skips STEPs 1-7 entirely and resumes from STEP 8 (mode-conditional) or STEP 9. Token cost for the analysis half drops to ~zero. Brief mismatch HALTs immediately to prevent cross-brief contamination.

### 0.2 Load graph + hats
Read `graph.json`. Read `hats.json`. Resolve Tier → model_id via `hats.json.default_models`.

### 0.3 PRC1 — Pre-Run Check
Run via Bash tool:
```bash
~/.claude/skills/gotscs/scripts/validate-graph.sh --expect-nodes 19 --expect-edges 58
```
Expected: `PRC1 PASS: 19 nodes (2 conditional), 58 edges`

**v4 PRC1 schema-validation extension (DD-09 / Goal-8).** After expect-nodes/expect-edges check, run:
```bash
~/.claude/skills/gotscs/scripts/validate-graph.sh --schema-validate
```
HALT on schema mismatch (closed-vocab enum violation on `type`, `exec_type`, `tier`, or `edge_type`). This guards AP-V21 / AP-V27.

If PRC1 fails: HALT with "PRC1 failed: <specific issue>. Re-install GOTSCS from ~/projects/graph/skills/gotscs/."

### 0.4 Init session
Derive `$SKILL_NAME_SLUG` from the first few words of the skill_concept_brief: lowercase, replace non-alphanumeric with `-`, collapse runs, strip leading/trailing `-`. Keep ≤30 chars. This is a temporary session label — the canonical `skill_name` is determined by N-NORMALIZE.

**Pre-flight HC-25 output-base validation (F007 fix — TOCTOU).** If `GOTSCS_OUTPUT_BASE` env var is set, validate it BEFORE init-session.sh creates any directories:
```bash
if [[ -n "${GOTSCS_OUTPUT_BASE:-}" ]]; then
  ~/.claude/skills/gotscs/scripts/validate-context-path.sh output-base "$GOTSCS_OUTPUT_BASE" \
    || { echo "HALT: halt-suspicious-target on GOTSCS_OUTPUT_BASE — refused before session init" >&2; exit 1; }
fi
```
This relocates the suspicious-target check from N-PREFLIGHT step 3a (which still validates --context/--context-spec there) to BEFORE the filesystem write in init-session.sh.

Run via Bash tool:
```bash
SESSION_DIR=$(~/.claude/skills/gotscs/scripts/init-session.sh "$SKILL_NAME_SLUG")
echo "$SESSION_DIR"
printf '%s' "$SKILL_CONCEPT_BRIEF" > "$SESSION_DIR/skill_concept_brief.txt"
```

### 0.5 SIGNAL_STATE init
Initialize in-memory SIGNAL_STATE (**schema 2.2** — NEW v4: adds `review_gate_audit` array and `degradation_notices` array for graceful-degradation tracking; preserves all v3.1.0 fields):
```
SIGNAL_STATE = {
  "schema_version": "2.2",
  "mode": MODE,
  "preflight_status": null, "input_class": null, "normalize_digest": null,
  "topology_digest": null, "decompose_digest": null, "constraints_digest": null,
  "context_inventory": null, "validation_mode": false, "conflict_signals": [],
  "design_blueprint": null, "gate_pass": null, "gate_diagnostic": null,
  "registry_result": null, "edges_result": null, "waves_result": null,
  "graph_spec": null, "spec_path": null, "spec_complete": null,
  "modules_result": null, "json_result": null, "skill_render_result": null,
  "verify_pass": null, "verify_result": null, "emit_complete": null,
  "behavioral_result": null, "behavioral_pass": null,
  "review_gate_audit": [], "degradation_notices": [],
  "retry_count_design": 0, "retry_count_artifact": 0, "repair_targets": []
}
executed_nodes = []
```

**Sync mode to disk immediately after initialization (using sync-signal.sh helper per P-005):**
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" mode="$MODE"
```

**Assert v4 schema fields present (GAP-001 guard).**
```bash
python3 - "$SESSION_DIR/SIGNAL_STATE.json" << 'PYEOF'
import json, sys
ss = json.load(open(sys.argv[1]))
errors = []
if ss.get("schema_version") != "2.2":
    errors.append(f"schema_version={ss.get('schema_version')!r} (expected '2.2')")
if "degradation_notices" not in ss:
    errors.append("missing field: degradation_notices")
if "review_gate_audit" not in ss:
    errors.append("missing field: review_gate_audit")
if errors:
    print(f"HALT: SIGNAL_STATE schema mismatch — {'; '.join(errors)}. Re-check init-session.sh.", file=sys.stderr)
    sys.exit(1)
print("SIGNAL_STATE schema v4 (2.2): OK")
PYEOF
```
HALT if this assertion fails — it means `init-session.sh` wrote a stale schema and graceful-degradation state will be silently lost.

---

## STEP 1 — WAVE 1: N-PREFLIGHT (inline)

**Skip STEPs 1-7 if `REUSE_ACTIVE=true` (P-007).** Stage files have already been copied from the prior session; jump directly to STEP 8 (or STEP 9 when MODE=skill).

Attention-reset: Read `modules/N-PREFLIGHT.md`.

Execute N-PREFLIGHT as an inline role-switched block:
- Role: gate hat — validate and classify input
- The `CONTEXT_PATH` and `CONTEXT_SPEC_PATH` env vars (set in STEP 0.1) are available to the HC-25 validation step within the module.
- Follow protocol in N-PREFLIGHT.md exactly
- Write output to `<session_dir>/stages/N-PREFLIGHT.md`
- Record: `executed_nodes.append("N-PREFLIGHT")`

**Wave 1 barrier:** Evaluate signals.
- If `preflight_status == 'refuse'` or `preflight_status == 'halt'`: read the REFUSAL output from stages/N-PREFLIGHT.md and emit it to the user. STOP. Do not proceed to Wave 2.
- If `preflight_status == 'pass'`: sync to disk then proceed to Wave 2:
  ```bash
  ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" preflight_status="$PREFLIGHT_STATUS" input_class="$INPUT_CLASS"
  ```

---

## STEP 2 — WAVE 2: N-NORMALIZE (inline) + N-CONTEXT-ANALYZE (spawn, conditional)

Execute N-NORMALIZE as inline role-switched block per `modules/N-NORMALIZE.md`. Write `stages/N-NORMALIZE.md`. Set `SIGNAL_STATE["normalize_digest"] = "present"`.

**Conditional dispatch of N-CONTEXT-ANALYZE.** Read `stages/N-PREFLIGHT.md` for `input_class`. If `input_class in {ec-skill, ec-spec, ec-both}`: dispatch N-CONTEXT-ANALYZE in the same response (single dispatch per HC-23 parallel-dispatch):

```
Agent(
  description="GOTSCS N-CONTEXT-ANALYZE: classify --context skill / --context-spec spec",
  prompt="You are executing node N-CONTEXT-ANALYZE in the GOTSCS pipeline.
Read briefing-core.md and briefing-appendix-vocab.md first (HC-13b per-node read-map).
Read and follow modules/N-CONTEXT-ANALYZE.md exactly.
Input: stages/N-PREFLIGHT.md + (--context <path> AND/OR --context-spec <path>) from CLI args.
CONTEXT_PATH env var = <value of CONTEXT_PATH>
CONTEXT_SPEC_PATH env var = <value of CONTEXT_SPEC_PATH>
Output: write stages/N-CONTEXT-ANALYZE.md and (when ec-spec/ec-both) stages/validation-mode.md."
)
```

Otherwise (input_class=ec-brief or ec-refeed or ec-inject): skip N-CONTEXT-ANALYZE; do not write its stage files.

**Wave 2 barrier:** N-NORMALIZE always completes; N-CONTEXT-ANALYZE completes only when fired. Confirm `stages/N-NORMALIZE.md` exists; verify `stages/N-CONTEXT-ANALYZE.md` exists IFF `input_class in {ec-skill, ec-spec, ec-both}`.

---

## STEP 3 — WAVE 3: N-TOPOLOGY + N-DECOMPOSE + N-CONSTRAINTS (parallel SPAWN, HC-23)

**v4 REWRITE (DD-04):** Wave-3 trio promoted from inline to spawn for genuine parallelism (Goal-4). Dispatch all three Agent calls in a SINGLE response (HC-23 single-response parallel dispatch). Each subagent reads `briefing-core.md` + its declared appendix per the per-node read-map (DD-03).

```
# DISPATCH ALL THREE IN SAME RESPONSE
Agent(description="GOTSCS N-TOPOLOGY: H.3 topology derivation",
  prompt="Execute N-TOPOLOGY per modules/N-TOPOLOGY.md.
Read briefing-core.md and briefing-appendix-topology.md first (HC-13b).
Input: stages/N-NORMALIZE.md (+ stages/validation-mode.md if exists)
Output: stages/N-TOPOLOGY.md")

Agent(description="GOTSCS N-DECOMPOSE: H.1 decomposition",
  prompt="Execute N-DECOMPOSE per modules/N-DECOMPOSE.md.
Read briefing-core.md first (HC-13b).
Input: stages/N-NORMALIZE.md (+ stages/validation-mode.md if exists)
Output: stages/N-DECOMPOSE.md")

Agent(description="GOTSCS N-CONSTRAINTS: INVENTORY + AP catalogue",
  prompt="Execute N-CONSTRAINTS per modules/N-CONSTRAINTS.md.
Read briefing-core.md and briefing-appendix-antipatterns.md first (HC-13b).
Input: stages/N-NORMALIZE.md (+ stages/validation-mode.md if exists)
Output: stages/N-CONSTRAINTS.md")
```

Record all three in `executed_nodes`.

**Wave 3 barrier:** All three stage files must exist. Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
  normalize_digest=present topology_digest=present decompose_digest=present constraints_digest=present
```

---

## STEP 4 — WAVE 4: N-AGG-DESIGN (spawn)

Attention-reset: Read `modules/N-AGG-DESIGN.md`.

Dispatch N-AGG-DESIGN as a subagent spawn:
```
Agent(
  description="GOTSCS N-AGG-DESIGN: mid-graph aggregation of topology+decompose+constraints",
  prompt="You are executing node N-AGG-DESIGN in the GOTSCS pipeline.
Read briefing-core.md, briefing-appendix-memory.md, and briefing-appendix-antipatterns.md (HC-13b per-node read-map).
Read and follow modules/N-AGG-DESIGN.md exactly.
Input stage files:
  - <session_dir>/stages/N-TOPOLOGY.md
  - <session_dir>/stages/N-DECOMPOSE.md
  - <session_dir>/stages/N-CONSTRAINTS.md
  - <session_dir>/stages/N-CONTEXT-ANALYZE.md (optional — consume if exists, per HC-18/AP-19)
Output: write <session_dir>/stages/N-AGG-DESIGN.md
Emit signal design_blueprint on completion."
)
```

**Wave 4 barrier:** Await spawn completion. Verify `stages/N-AGG-DESIGN.md` exists. Set `SIGNAL_STATE["design_blueprint"] = "present"`. Sync to disk.

---

## STEP 5 — WAVE 5: N-DESIGN-GATE (inline gate) + optional review-gate hop

Attention-reset: Read `modules/N-DESIGN-GATE.md`.

Execute N-DESIGN-GATE as inline role-switched block. Read `stages/N-AGG-DESIGN.md`. Evaluate HC-08 criteria (and HC-09 if --context was given). Write `stages/N-DESIGN-GATE.md` with `gate_pass:bool`, `gate_diagnostic:markdown`, and `design_blueprint (passthrough)`.

**Wave 5 barrier:** Read `stages/N-DESIGN-GATE.md`. Extract `gate_pass`.
- If `gate_pass=true`: proceed to STEP 5b (review-gate hop) or STEP 6.
- If `gate_pass=false` AND `retry_count_design < 1`: fire E11 RP-01 back-edge to STEP 4 (N-AGG-DESIGN). Pass `gate_diagnostic` as the remediation_payload. Increment `retry_count_design`. **Sync to disk:** update `retry_count_design` field in `$SESSION_DIR/SIGNAL_STATE.json`. Re-run STEP 4, then STEP 5.
- If `gate_pass=false` AND `retry_count_design >= 1`: HALT with `halt-on-design-gate-fail` listing the specific failing HC-08/HC-09 criterion.

### STEP 5b — Optional review-gate hop (--review-gates flag)

**NEW v4 (DD-01 + Goal-3).** If `REVIEW_GATES` env var is set AND `gate_pass=true`:
- Display the design_blueprint passthrough section to the user.
- Block until user replies "approve", "modify <text>", or "abort".
- On "approve": continue to STEP 6.
- On "modify <text>": fire E11 RP-01 back-edge to N-AGG-DESIGN with the modify text as remediation_payload. Treat as a normal retry (counts toward `retry_count_design`).
- On "abort": HALT with `halt-on-user-abort-wave5`.
- Log the verdict to `stages/review-gate-wave5.md` (REVIEW_GATE_AUDIT sink per spec line 191).
- This hop is **orchestrator-state, NOT a graph node** (per DD-01 + AP-V29).

---

## STEP 6 — WAVE 6: N-REGISTRY + N-EDGES + N-WAVES (parallel spawn + inline)

Attention-reset: Read `modules/N-REGISTRY.md`.

**N-WAVES (inline — run FIRST, before spawns):** Follow `modules/N-WAVES.md`. Read `stages/N-DESIGN-GATE.md` (the passthrough section). Write `stages/N-WAVES.md`.

**IMPORTANT: DISPATCH N-REGISTRY AND N-EDGES IN A SINGLE RESPONSE** (two Agent tool calls in one message per HC-23). This is true parallelism — do NOT dispatch one, wait, then dispatch the other.

**N-REGISTRY spawn:**
```
Agent(description="GOTSCS N-REGISTRY: generate Node Registry from design_blueprint",
  prompt="Execute N-REGISTRY per modules/N-REGISTRY.md.
Read briefing-core.md and briefing-appendix-contract.md first (HC-13b).
Input: <session_dir>/stages/N-DESIGN-GATE.md (passthrough section contains design_blueprint)
Output: <session_dir>/stages/N-REGISTRY.md")
```

**N-EDGES spawn (same response as N-REGISTRY):**
```
Agent(description="GOTSCS N-EDGES: generate Edge Table from design_blueprint",
  prompt="Execute N-EDGES per modules/N-EDGES.md.
Read briefing-core.md and briefing-appendix-contract.md first (HC-13b).
Input: <session_dir>/stages/N-DESIGN-GATE.md (passthrough section contains design_blueprint)
Output: <session_dir>/stages/N-EDGES.md")
```

**Wave 6 barrier:** All three stage files must exist. Record in `executed_nodes`. Sync Wave 6 signals to disk via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
  registry_result=present edges_result=present waves_result=present
```

---

## STEP 7 — WAVE 7: N-SYNTH-GRAPH (spawn)

Attention-reset: Read `modules/N-SYNTH-GRAPH.md`.

Dispatch N-SYNTH-GRAPH as spawn:
```
Agent(description="GOTSCS N-SYNTH-GRAPH: artifact-synthesis of registry+edges+waves",
  prompt="Execute N-SYNTH-GRAPH per modules/N-SYNTH-GRAPH.md.
Read briefing-core.md and briefing-appendix-memory.md first (HC-13b).
Input stage files:
  - <session_dir>/stages/N-REGISTRY.md
  - <session_dir>/stages/N-EDGES.md
  - <session_dir>/stages/N-WAVES.md
Output: <session_dir>/stages/N-SYNTH-GRAPH.md")
```

**Wave 7 barrier:** Verify `stages/N-SYNTH-GRAPH.md` exists. Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" graph_spec=present
```

---

## STEP 8 — WAVE 8: N-SPEC-ARTIFACT (inline, mode-conditional) + optional review-gate hop

**Skip this step if `MODE=skill`.** When `MODE=skill`, Wave 8 is empty; orchestrator proceeds directly from Wave 7 to Wave 9.

Attention-reset: Read `modules/N-SPEC-ARTIFACT.md`.

Execute N-SPEC-ARTIFACT as inline role-switched block. Read `stages/N-SYNTH-GRAPH.md` (graph_spec) + `stages/N-AGG-DESIGN.md` (design_blueprint) + `stages/N-NORMALIZE.md` (skill_name, shapes, success criteria) + `stages/N-CONSTRAINTS.md` (inventory_items, anti-patterns).

**Dual-write contract (per F011 fix):** N-SPEC-ARTIFACT writes the rendered spec to BOTH `stages/N-SPEC-ARTIFACT.md` AND `<session_output_base>/<skill_name>-spec.md`.

**Wave 8 barrier:** Both writes must succeed. Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" spec_path="$SPEC_PATH" spec_complete=true
```

### STEP 8b — Optional review-gate hop (--review-gates flag)

**NEW v4 (DD-01 + Goal-3).** If `REVIEW_GATES` env var is set AND `MODE in {spec, both}`:
- Display the rendered spec.md path and a brief preview to the user.
- Block until user replies "approve" or "abort".
- On "approve": continue to STEP 9 (skill mode) or terminate (spec mode).
- On "abort": HALT with `halt-on-user-abort-wave8`.
- Log to `stages/review-gate-wave8.md`.

**Mode-fork at end of Wave 8:**
- If `MODE=spec`: fire E21 terminal → SPEC_OUTPUT. Print the spec-complete exit block from N-SPEC-ARTIFACT step 7. STOP.
- If `MODE=both`: continue to STEP 9.

---

## STEP 9 — WAVE 9: N-MODULES (spawn) + N-JSON (inline) + N-SKILL-RENDER (inline)

**MODE=spec exits at STEP 8 — this step only runs for MODE=skill or MODE=both.**

Attention-reset: Read `modules/N-MODULES.md`.

Dispatch N-MODULES as spawn (writes per-file outputs to `stages/modules/<node_id>.md` per P-001):
```
Agent(description="GOTSCS N-MODULES: generate per-node module files",
  prompt="Execute N-MODULES per modules/N-MODULES.md.
Read briefing-core.md and briefing-appendix-contract.md first (HC-13b).
Input: <session_dir>/stages/N-SYNTH-GRAPH.md
Output: write each module to <session_dir>/stages/modules/<node_id>.md (per-file emission per P-001).
Write a thin index manifest to <session_dir>/stages/N-MODULES.md (no embedded module bodies).")
```

Execute N-JSON inline per `modules/N-JSON.md`. Write `stages/N-JSON.md`. **N-JSON must complete and its stage file must exist before N-SKILL-RENDER is dispatched (P0-4 ordering constraint).** This is a hard sequential dependency: N-SKILL-RENDER sources scale_gates values from the graph_json_content block; if N-JSON is repaired after a failed first pass, N-SKILL-RENDER must read the repaired values or it will emit a stale §1 Node Registry table (V13(e) failure).

**N-SKILL-RENDER inline (P-002).** Execute N-SKILL-RENDER as an inline role-switched block per `modules/N-SKILL-RENDER.md` **only after `stages/N-JSON.md` exists**. Do NOT run N-SKILL-RENDER concurrently with N-JSON. N-SKILL-RENDER reads 4 stage files (N-NORMALIZE, N-CONSTRAINTS, N-SYNTH-GRAPH, N-JSON) plus `briefing-core.md`. Reads 3 prior stage files (N-NORMALIZE, N-CONSTRAINTS, N-SYNTH-GRAPH) plus `briefing-core.md`. **v4 delta (DD-03):** N-SKILL-RENDER no longer embeds Appendix A briefing inline — it references `briefing-core.md` instead. This drops the N-SKILL-RENDER token budget from 16K (v3.1.0) to 10K (v4). Assembles the full SKILL.md content (§0 HARD GATES with verbatim inventory_items, §1 through §7) and writes to `stages/N-SKILL-RENDER.md`. N-EMIT (STEP 10b) consumes this file directly via `cp` — no re-rendering at emit time. This is the authoritative SKILL.md content for V11 verification.

**Wave 9 barrier:** All Wave 9 stage files must exist (N-MODULES, N-JSON, N-SKILL-RENDER per P-002). Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
  modules_result=present json_result=present skill_render_result=present
```

---

## STEP 10a — WAVE 10: N-VERIFY (spawn) — RESIDUAL BATTERY

Attention-reset: Read `modules/N-VERIFY.md`.

Dispatch N-VERIFY as spawn. **v4 deltas (DD-07):** tier shifted from `model-large` → `model-medium`; `token_budget` cut from 20000 → 12000. The residual battery comprises: V1, V2, V3, V4, V7, V8, V9, V10, V13(a/b/c/e), V14, V15, V16, V17, V18, V19 (final completeness), and H.4 contract verification. **V5, V6, V11, V12, V13(d) are pre-shifted upstream** to producing-wave nodes (DD-06 left-shift), making the Wave-10 verifier ~40% smaller.

```
Agent(description="GOTSCS N-VERIFY: run residual V-battery (post-DD-06 left-shift)",
  prompt="Execute N-VERIFY per modules/N-VERIFY.md.
Read briefing-core.md and briefing-appendix-contract.md first (HC-13b).
Input stage files:
  - <session_dir>/stages/N-MODULES.md
  - <session_dir>/stages/N-JSON.md
  - <session_dir>/stages/N-SKILL-RENDER.md
  - All prior stages at <session_dir>/stages/
Output: <session_dir>/stages/N-VERIFY.md")
```

**Wave 10a barrier:** Read `stages/N-VERIFY.md`. Extract `verify_pass`.
- If `verify_pass=false` AND `retry_count_artifact < 1`: route back-edges by failure type — V11 only triggers SKILL-RENDER repair (N-MODULES regeneration cannot fix rendered SKILL.md):
  - If `repair_targets == ['V11']` (V11 only): fire **E41 only** (N-VERIFY→N-SKILL-RENDER) — re-render SKILL.md so the INVENTORY items are correctly embedded.
  - Else if `'V12' in repair_targets` (with or without others): fire E27 (N-VERIFY→N-MODULES) AND E28 (N-VERIFY→N-JSON); also fire E41 if `'V11' in repair_targets`.
  - Else (general module/registry failures, no V11/V12): fire E27 (N-VERIFY→N-MODULES) only.
  - **v4 NEW (DD-06):** If `'registry_v13d_fail' in repair_targets`: fire E50 (N-VERIFY→N-AGG-DESIGN). If `'edges_early_v_fail' in repair_targets`: fire E51 (N-VERIFY→N-AGG-DESIGN). If `'modules_v6_fail' in repair_targets`: fire E52 (N-VERIFY→N-MODULES).
  Re-run N-VERIFY after re-execution of dispatched targets. Increment `retry_count_artifact`. **Sync to disk:** write updated `retry_count_artifact` and `repair_targets` back to `$SESSION_DIR/SIGNAL_STATE.json` immediately after incrementing.
- If `verify_pass=false` AND `retry_count_artifact >= 1`: emit partial skill with advisory "Verification failed after 1 repair attempt. Review stages/N-VERIFY.md for details."
- If `verify_pass=true`: proceed to N-EMIT.

---

## STEP 10b — WAVE 10: N-EMIT (inline)

Execute N-EMIT inline per `modules/N-EMIT.md`.
Write output files to `<session_output_base>/<skill_name>/`. **v4 output set:** SKILL.md, graph.json, graph.schema.json (NEW), hats.json, modules/ (19 files), briefing-core.md, briefing-appendix-{topology,contract,memory,antipatterns,vocab}.md (5 files), tests/run-smoke-tests.sh, tests/run-regression-suite.sh (NEW v4).
Record in `executed_nodes`.

Emit to user (select block by MODE):

**MODE=skill:**
```
## GOTSCS Complete

Skill written to: ~/docs/gotscs-output/<skill_name>/

Files:
  SKILL.md
  graph.json
  graph.schema.json
  hats.json
  modules/ (19 files)
  briefing-core.md
  briefing-appendix-{topology,contract,memory,antipatterns,vocab}.md
  tests/run-smoke-tests.sh
  tests/run-regression-suite.sh

To install:
  cp -r ~/docs/gotscs-output/<skill_name>/ ~/.claude/skills/<skill_name>/

To validate:
  ~/.claude/skills/<skill_name>/tests/run-smoke-tests.sh
  ~/.claude/skills/<skill_name>/tests/run-regression-suite.sh   # ≥80% mutation-kill
```

**MODE=both:**
```
## GOTSCS Complete

Spec:   ~/docs/gotscs-output/<skill_name>-spec.md
Skill:  ~/docs/gotscs-output/<skill_name>/

To generate an implementation plan from the spec:
  /writing-plans ~/docs/gotscs-output/<skill_name>-spec.md

To install the skill:
  cp -r ~/docs/gotscs-output/<skill_name>/ ~/.claude/skills/<skill_name>/

To validate the skill:
  ~/.claude/skills/<skill_name>/tests/run-smoke-tests.sh
  ~/.claude/skills/<skill_name>/tests/run-regression-suite.sh
```

---

## STEP 10c — WAVE 10c: N-BEHAVIORAL (spawn, conditional per P-006)

**Skip this step unless `BEHAVIORAL_TEST=true` (set by `--behavioral-test` flag at STEP 0.1) AND `MODE in ['skill','both']`.**

When firing: dispatch N-BEHAVIORAL as spawn. Reads `stages/N-EMIT.md` and `stages/N-NORMALIZE.md`. Synthesizes a representative fixture from `input_shape`, runs the produced skill against it via subagent, performs structural checks, writes `stages/N-BEHAVIORAL.md`.

```
Agent(description="GOTSCS N-BEHAVIORAL: behavioral acceptance test of produced skill",
  prompt="Execute N-BEHAVIORAL per modules/N-BEHAVIORAL.md.
Read briefing-core.md first (HC-13b).
Input stage files:
  - <session_dir>/stages/N-EMIT.md (must show emit_complete=true and skill_path)
  - <session_dir>/stages/N-NORMALIZE.md (for fixture synthesis from input_shape)
Output: <session_dir>/stages/N-BEHAVIORAL.md with fixture, run_log, structural_checks, behavioral_pass.
Note: behavioral_pass is INFORMATIONAL — does not block shipping. Skill artifact at skill_path already passed N-VERIFY.")
```

**Wave 10c barrier:** N-BEHAVIORAL is informational only. **Stage-file guard:** if `stages/N-BEHAVIORAL.md` is missing (catastrophic subagent crash before any output), set `behavioral_pass=null` and surface "Behavioral acceptance: ADVISORY (N-BEHAVIORAL did not complete)". Do NOT halt — the skill artifact has already shipped via N-EMIT. Otherwise, read `stages/N-BEHAVIORAL.md` and surface `behavioral_pass`:
- `behavioral_pass=true` → "Behavioral acceptance: PASS"
- `behavioral_pass=false` → "Behavioral acceptance: FAIL — review stages/N-BEHAVIORAL.md before installing"
- `behavioral_pass=null` → "Behavioral acceptance: ADVISORY (fixture synthesis not feasible for this input shape)"

Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
  behavioral_result=present behavioral_pass="$BEHAVIORAL_PASS"
```

---

## STEP 10d — FINAL SIGNAL_STATE INVARIANT (P-005)

After N-EMIT completes, sync `emit_complete=true` and assert no required field is null:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" emit_complete=true

python3 - "$SESSION_DIR/SIGNAL_STATE.json" "$MODE" << 'PYEOF'
import json, sys
ss = json.load(open(sys.argv[1])); mode = sys.argv[2]
# Mode-conditional required fields. spec_path/spec_complete only required when MODE in {spec,both}.
core = ["preflight_status", "input_class", "normalize_digest", "topology_digest",
        "decompose_digest", "constraints_digest", "design_blueprint", "gate_pass"]
spec_only = ["spec_path", "spec_complete"]
skill_only = ["registry_result", "edges_result", "waves_result", "graph_spec",
              "modules_result", "json_result", "skill_render_result", "verify_pass", "emit_complete"]
required = core[:]
if mode in ("spec","both"): required += spec_only
if mode in ("skill","both"): required += skill_only
missing = [k for k in required if ss.get(k) is None]
if missing:
    print(f"WARN: SIGNAL_STATE has null required fields after run: {missing}", file=sys.stderr)
    sys.exit(0)  # advisory, not blocking — partial success can still ship
print("SIGNAL_STATE invariant: all required fields populated.")
PYEOF
```

This catches sync-coverage gaps in the orchestrator (a Wave barrier that forgot to call `sync-signal.sh`) without blocking emission. Failures here indicate orchestrator drift, not skill defects.

---

## FAILURE MODES

| Failure | Action |
|---------|--------|
| No flag | Ask user; block pipeline until MODE is unambiguous |
| PRC1 fails | HALT; do not run pipeline |
| PRC1 schema-validate fails (NEW v4) | HALT; closed-vocab enum violation in graph.json |
| N-PREFLIGHT refuses | Emit refusal to user; stop |
| HC-25 validation fails | HALT with diagnostic from validate-context-path.sh |
| Any Wave node timeout | Retry once; on second timeout proceed with best-effort + advisory |
| N-DESIGN-GATE fails twice | HALT: `halt-on-design-gate-fail` listing failing HC-08/HC-09 criterion |
| N-WAVES Wave-count > 10 after EC8 pruning reaches EC2 floor | HALT: "Input requires >10 Waves to satisfy GOTSCS contract — split into smaller briefs." |
| N-VERIFY fails twice (MODE=skill or MODE=both) | Emit partial skill with diagnostic; spec artifact (if MODE=both) already written — report spec path even if skill fails |
| N-SPEC-ARTIFACT fails (MODE=spec or MODE=both) | Retry once inline; on second failure emit advisory "Spec generation failed — run /gotscs --spec again" |
| N-BEHAVIORAL timeout or fixture-synthesis failure | Set `behavioral_pass=null`; emit advisory "Behavioral acceptance: ADVISORY"; pipeline continues — skill artifact is already shipped |
| N-EMIT post-emit smoke test fails twice (P-004) | HALT: `halt-on-post-emit-validation-fail`; surface partial skill with diagnostic listing every failed check; advise user to inspect `stages/modules/` and `stages/N-SKILL-RENDER.md` |
| `--review-gates` user replies "abort" at Wave 5 | HALT `halt-on-user-abort-wave5` |
| `--review-gates` user replies "abort" at Wave 8 | HALT `halt-on-user-abort-wave8` |
| Any node retry exhaustion → graceful degradation per DD-02 | Continue with `degradation_notice:`; orchestrator propagates to N-VERIFY (informational) |

## PIPELINE DIAGRAM

```
[skill_concept_brief]
       |
       v
  [N-PREFLIGHT] --[refuse/halt]--> [REFUSE_OUTPUT]
       |
  (preflight_status=pass)
       |
    /     \
   v       v (conditional: ec-skill/ec-spec/ec-both)
[N-NORMALIZE]  [N-CONTEXT-ANALYZE]*
   |              |
   gate-open (3)  optional edges to Wave 3
   /    |    \
  v     v     v
[N-TOPOLOGY]*[N-DECOMPOSE]*[N-CONSTRAINTS]*    (* = spawn; v4 promotion DD-04)
  \          |           /
   \  (required, AND)   / + optional context_inventory
    v         v         v
       ((N-AGG-DESIGN))*  <- MID-GRAPH AGGREGATION (Wave 4)
              |
       [N-DESIGN-GATE]    <- QUALITY GATE (Wave 5)
              |
        [optional --review-gates hop @ W5]   <- DD-01 orchestrator-state
              |
     forward-conditional (3 copies; gate_condition: gate_pass==true)
    /         |         \
   v          v          v
[N-REGISTRY]*[N-EDGES]*[N-WAVES]
    \          |         /
     \  (required, AND)  /
      v        v        v
        ((N-SYNTH-GRAPH))*  <- SYNTHESIS (Wave 7; type=SYNTHESIS per HC-16)
               |
     +--[MODE=spec/both]--> [N-SPEC-ARTIFACT] --> [optional --review-gates hop @ W8] --> spec output
     |                       ^   ^   ^   ^
     |          (also reads: N-AGG-DESIGN [E42], N-NORMALIZE [E44],
     |                       N-CONSTRAINTS [E45], N-CONTEXT-ANALYZE [E46 optional])
     |                              |
     |                  (MODE=spec: STOP → SPEC_OUTPUT)
     |                  (MODE=both: continue)
     |
forward-conditional (3 copies; gate_condition: MODE in ['skill','both'])
    /         |         \
   v          v          v
[N-MODULES]* [N-JSON]  [N-SKILL-RENDER]
    \          |        /
  (required, AND-join — 3 inputs)
      v        v        v
       ((N-VERIFY))*     <- residual V-battery (Wave 10; smaller post-DD-06 left-shift)
            |
(verify_pass=true)    (verify_pass=false, retry_count_artifact<1)
            v                 |
        [N-EMIT]   E27: back-edge to N-MODULES
        [output]   E28: back-edge to N-JSON (if 'V12' in repair_targets)
            |      E41: back-edge to N-SKILL-RENDER (if 'V11' in repair_targets)
            |      E50/E51: back-edge to N-AGG-DESIGN (NEW v4 DD-06)
            |      E52: back-edge to N-MODULES (NEW v4 DD-06)
            |
      [SKILL_OUTPUT]  --[--behavioral-test]--> [N-BEHAVIORAL]* (advisory, Wave 10c)

* = spawn node
```

---

## §1 NODE REGISTRY (HC-01 source-of-truth note)

**HC-01 GRAPH-AS-TRUTH:** the canonical Node Registry lives in `graph.json`. This SKILL.md file does NOT duplicate the registry table content (NEW v4 directive per Goal-7 + Goal-8 + DD-09; was redundantly embedded in v3.1.0).

To inspect:
- Read `graph.json` directly, or
- Run `~/.claude/skills/gotscs/scripts/validate-graph.sh --print-registry`

The Registry contains 19 nodes (17 unconditional + 2 conditional: N-CONTEXT-ANALYZE, N-BEHAVIORAL). Schema validation is enforced via `graph.schema.json` at PRC1 (closed-vocab enums on `type`, `exec_type`, `tier` per HC-04).

## §1.5 AGGREGATION POLICIES

> "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."

GOTSCS v4.0.0 declares **three** aggregations (two mid-graph + one final). All policies live in `graph.json` on the aggregator nodes and are restated here for human-readable reference (HC-01: graph.json remains authoritative; this section is documentation-only).

| Aggregator | Wave | Role | Incoming branches | Aggregation policy / Join semantics |
|---|---|---|---|---|
| **N-AGG-DESIGN** | 4 | mid-graph #1 | N-TOPOLOGY, N-DECOMPOSE, N-CONSTRAINTS, +(N-CONTEXT-ANALYZE optional) | `triz-synthesize + contradiction-resolve; AND-join; branch_budget_cap=3 (+1 optional context)` |
| **N-SYNTH-GRAPH** | 7 | mid-graph #2 | N-REGISTRY, N-EDGES, N-WAVES | `weighted-merge + cross-table ID consistency check; AND-join; branch_budget_cap=3` |
| **N-VERIFY** | 10 | final contract-join | N-MODULES, N-JSON, N-SKILL-RENDER | `concatenate + residual V-battery (V1, V2, V3, V4, V7, V8, V9, V10, V13(a/b/c/e), V14, V15, V16, V17, V18, V19, H.4); AND-join; branch_budget_cap=3` |

**Why TRIZ-synthesize at Wave 4:** the three Wave-3 analyses examine orthogonal axes (topology, decomposition, constraints) that often produce contradictions (e.g., a constraint may demand more nodes than the topology can hold). TRIZ separation principles (in time / in space / in condition / in structure) provide a disciplined contradiction-resolution vocabulary. Documented in `design_blueprint § contradiction_resolutions`.

**Why weighted-merge at Wave 7:** the Wave-6 outputs (Node Registry, Edge Table, Wave Plan) describe the same graph from three views. Weighted-merge prefers Edge Table for connectivity facts, Node Registry for cardinality, and Wave Plan for temporal facts; cross-table ID consistency check catches drift.

**Why concatenate at Wave 10:** the V-battery is composed of independent pass/fail checks, not synthesizable signals. Concatenation preserves the failure detail per check; AND-join derives `verify_pass`. v4 residual battery is ~40% smaller than v3.1.0's full battery because V5/V6/V11/V12/V13(d) shifted upstream per DD-06.

## §2 EDGE TABLE (HC-01 source-of-truth note)

**HC-01 GRAPH-AS-TRUTH:** the canonical Edge Table lives in `graph.json`. This SKILL.md file does NOT duplicate edge definitions.

To inspect:
- Read `graph.json` directly, or
- Run `~/.claude/skills/gotscs/scripts/validate-graph.sh --print-edges`

The Edge Table contains 58 rows. Edge type breakdown: required=15, optional=6, gate-open=3, forward-conditional=20, back-edge=9, terminal=5. Closed-vocab enforcement via `graph.schema.json` (HC-03).

## §3 MODE MATRIX (from N-WAVES)

| mode | Active Waves | Spawn budget | Tier downshifts | Latency target | Inactive edge IDs |
|---|---|---|---|---|---|
| MINIMAL | 1-7, 9, 10 (skill mode); 1-8 (spec mode) | 5 (halved from 10, floor) | All `downshiftable: true` hats → fallback tier (gate, extractor, analyzer, generator, persister, verifier). Formatter NOT downshifted (DD-08 sets `downshiftable: false`) | ≤30 min | none (topology non-skippable per H.3) |
| STANDARD | All Waves | 10 (full) | none | ≤45 min | none |
| DEEP | All Waves | 15 (1.5×) | none | ≤90 min | none |

Note: GOTSCS pipeline topology is non-skippable (every wave's output is a required input for the next), so the MINIMAL/STANDARD/DEEP distinction is in tier downshifts and spawn budgets, not in active waves. Mode-conditional waves (Wave 8 spec-only, Wave 9 skill/both, Wave 10c behavioral conditional) are still gated by --skill/--spec/--both/--behavioral-test flags, NOT by latency mode.

## §4 WAVE PLAN (from N-WAVES)

| Wave # | Nodes | Type | Spawn budget | Cumulative spawn | Wall-clock target | Failure grace | Attention-reset Read | Depends on |
|---|---|---|---|---|---|---|---|---|
| 1 | N-PREFLIGHT | sequential gate | 0 (inline) | 0 | 60s | 0 (fail-fast) | yes (Wave 1 entry) | — |
| 2 | N-NORMALIZE; N-CONTEXT-ANALYZE (cond.) | inline + cond-spawn | 1 (cond.) | 1 | 180s | 0 | no | 1 |
| 3 | N-TOPOLOGY, N-DECOMPOSE, N-CONSTRAINTS | **fan-out parallel-spawn** (HC-23 single-response dispatch; v4 promotion per DD-04) | 3 | 4 | 240s (parallel) | 0 | yes (entry to Wave-3) | 2 |
| 4 | N-AGG-DESIGN | mid-graph aggregation #1 | 1 | 5 | 600s | 1 (partial OK after retry) | yes (aggregation entry) | 3 |
| 5 | N-DESIGN-GATE | inline gate (+ optional review-gate hop when --review-gates) | 0 (inline) | 5 | 120s | 0 | no | 4 |
| 6 | N-REGISTRY, N-EDGES, N-WAVES | mixed (2 spawn parallel-dispatched per HC-23 + 1 inline) | 2 | 7 | 360s | 0 | no | 5 |
| 7 | N-SYNTH-GRAPH | mid-graph aggregation #2 | 1 | 8 | 600s | 1 | yes (aggregation entry) | 6 |
| 8 | N-SPEC-ARTIFACT (mode-conditional: spec/both only) | inline (+ optional review-gate hop) | 0 (inline) | 8 | 360s | 0 | no | 7 |
| 9 | N-MODULES, N-JSON, N-SKILL-RENDER (mode-conditional: skill/both only) | mixed (1 spawn + 2 inline) | 1 | 9 | 600s | 0 | no | 7 (or 8 in --both) |
| 10 | N-VERIFY, N-EMIT, N-BEHAVIORAL (cond. on --behavioral-test) | spawn + inline + cond-spawn | 2 | 11 (incl. behavioral) | 720s | 1 (V-fail emits partial skill) | no | 9 |

**Token budget per wave (typical mode = ec-skill --skill flag + --context, --behavioral off):**

| Wave | Budget |
|---|---|
| 1 | 2000 |
| 2 | 9000 (3000 NORMALIZE + 6000 CONTEXT-ANALYZE) |
| 3 | 9000 (2000+4000+3000 — Wave-3 trio at spawn budgets) |
| 4 | 8000 |
| 5 | 2000 |
| 6 | 13000 (5000+5000+3000) |
| 7 | 8000 |
| 8 | 0 (mode=skill skips Wave 8) |
| 9 | 22000 (9000+3000+10000) |
| 10 | 14000 (12000+2000) |
| **Total --skill** | **87000** |

## §5 OPTIMIZATIONS (v4 specific)

The 11 cross-cutting deltas vs v3.1.0:

1. **Briefing split (DD-03):** monolithic `briefing.md` → `briefing-core.md` (~150 lines: H.1+H.2+H.7) + 5 appendices (`topology`, `contract`, `memory`, `antipatterns`, `vocab`) loaded per per-node read-map.
2. **Exec-type promotions (DD-04):** Wave-3 trio (N-TOPOLOGY, N-DECOMPOSE, N-CONSTRAINTS) inline → spawn for genuine parallelism (Goal-4).
3. **V-check left-shifts (DD-06):** V19, V13(d), V12+V5, V6, V11 shifted from Wave-10 to producing-wave nodes (Goal-5). Wave-10 N-VERIFY is ~40% smaller.
4. **Tier shifts (DD-07):** N-SPEC-ARTIFACT model-small → model-medium; N-VERIFY model-large → model-medium (smaller residual battery permits downshift).
5. **Token-budget cuts:** N-REGISTRY -17%, N-EDGES -17%, N-WAVES -25%, N-MODULES -25%, N-JSON -25%, N-SKILL-RENDER -37%, N-VERIFY -40%. Total Goal-1 reduction ≈ 30K tokens.
6. **Graceful-degradation cross-cutting pattern (DD-02):** every node declares `## Failure modes` table + `degradation_notice:` frontmatter on retry exhaustion; non-blocking (Goal-2 / CR-06 / AP-V6).
7. **`--review-gates` flag (DD-01):** optional human-review hops at Waves 5 and 8 (orchestrator-state hops, not graph edges per AP-V29). Goal-3.
8. **Regression suite (DD-10):** `tests/run-regression-suite.sh` with ≥80% mutation-kill rate (Goal-6).
9. **Schema validation (DD-09):** `graph.schema.json` + `validate-graph.sh --schema-validate` enforces closed-vocab enums on `type`/`exec_type`/`tier`/`edge_type` at PRC1 (Goal-8).
10. **HC-13b restatement:** spawn subagents read `briefing-core.md` first plus declared appendices; consolidates v3.1.0's HC-13.
11. **5-brief safety gate (HC-13b):** N-PREFLIGHT enforces 5-brief regression battery + v3.1.0 backup before disk replacement.

## §5.5 FAILURE MODES (cross-cutting graceful-degradation per DD-02)

Every node declares a uniform `## Failure modes` table covering 4 categories:

| Failure category | Trigger | Action |
|---|---|---|
| `timeout` | wall-clock target exceeded | Retry once; on second timeout emit `degradation_notice:` and continue |
| `malformed` | output fails schema/format check | Retry once with diagnostic feedback; on second failure emit `degradation_notice:` |
| `missing_input` | required input stage file absent | HALT (input is upstream contract violation) |
| `subagent_crash` | spawn subagent terminated without writing stage file | Retry once; on second crash emit `degradation_notice:` and use best-effort fallback content |

**Degradation notice frontmatter format** (placed at top of stage file):
```yaml
degradation_notice:
  category: timeout | malformed | subagent_crash
  retry_count: 1
  timestamp: <ISO-8601>
  detail: "<short diagnostic>"
  fallback_content: true
```

The orchestrator collects all `degradation_notice:` entries into `SIGNAL_STATE["degradation_notices"]` and propagates to N-VERIFY for informational reporting (does NOT block emission).

## §6 GoT CONTROLLER (orchestrator dispatch instructions)

- **Inline:** STEP 1 (N-PREFLIGHT), STEP 2 (N-NORMALIZE), STEP 5 (N-DESIGN-GATE), STEP 6 (N-WAVES), STEP 8 (N-SPEC-ARTIFACT), STEP 9 (N-JSON, N-SKILL-RENDER), STEP 10b (N-EMIT), STEP 10d (final invariant).
- **Spawn:** STEP 2 (N-CONTEXT-ANALYZE — conditional), STEP 3 (Wave-3 trio — parallel-dispatch in single response per HC-23 — NEW v4 promotion), STEP 4 (N-AGG-DESIGN), STEP 6 (N-REGISTRY + N-EDGES — parallel-dispatch in single response per HC-23), STEP 7 (N-SYNTH-GRAPH), STEP 9 (N-MODULES), STEP 10a (N-VERIFY), STEP 10c (N-BEHAVIORAL — conditional).
- **Barriers:** each Wave has a barrier check per the orchestrator STEP-N description. Wave barriers verify stage files exist and sync SIGNAL_STATE to disk via `sync-signal.sh` (P-005).
- **Optional review-gate hops (NEW v4):** STEP 5b and STEP 8b are orchestrator-state pauses, NOT graph nodes (AP-V29). Active only when `REVIEW_GATES` env var is set.

## §7 PIPELINE NARRATIVE

GOTSCS v4 ingests a text-form skill-concept brief plus mode/context flags, validates and classifies it through the **N-PREFLIGHT** gate (Wave 1), then runs **N-NORMALIZE** (Wave 2) inline to extract the canonical `skill_name`, `input_shape`, `output_shape`, and `success_criteria`. When `--context` or `--context-spec` is supplied, **N-CONTEXT-ANALYZE** spawns in parallel with N-NORMALIZE to classify host-skill preservation/upgrade/replace semantics. Wave 3 then runs the orthogonal-axis trio — **N-TOPOLOGY** (H.3 topology derivation), **N-DECOMPOSE** (H.1 decomposition), **N-CONSTRAINTS** (INVENTORY + AP catalogue) — as **true parallel spawns dispatched in a single response** (HC-23). This is the v4 signature parallelism upgrade (DD-04 / Goal-4): v3.1.0 ran these inline and back-to-back; v4 dispatches them concurrently for wall-clock savings.

The Wave-3 outputs converge at **N-AGG-DESIGN** (Wave 4 mid-graph aggregation #1), which applies TRIZ separation principles + contradiction-resolution to produce a `design_blueprint`. **N-DESIGN-GATE** (Wave 5) evaluates HC-08/HC-09 quality criteria; on `gate_pass=false` it back-edges to N-AGG-DESIGN once. **NEW v4:** when `--review-gates` is set, STEP 5b inserts a human-review pause after gate-pass, allowing approve/modify/abort verdicts as orchestrator-state hops (NOT graph nodes per AP-V29). Wave 6 fans out to **N-REGISTRY** + **N-EDGES** (parallel spawn) and **N-WAVES** (inline) — generating the three component artifacts. **N-SYNTH-GRAPH** (Wave 7 mid-graph aggregation #2) merges them via weighted-merge + cross-table consistency audit (V8/V12 early checks).

For `--spec`/`--both`, **N-SPEC-ARTIFACT** (Wave 8) renders the human-readable spec.md (with optional `--review-gates` STEP 8b pause). For `--skill`/`--both`, Wave 9 runs **N-MODULES** (spawn, per-file emission per P-001), **N-JSON** (inline), and **N-SKILL-RENDER** (inline, P-002 dedicated renderer assembling the SKILL.md content with verbatim INVENTORY in §0 HARD GATES). Wave 10's **N-VERIFY** (now `model-medium` per DD-07, 12K tokens per DD-07) runs a residual V-battery — V5/V6/V11/V12/V13(d) are pre-shifted upstream (DD-06). On V-failure it back-edges to the appropriate node (E27/E28/E41 for v3.1.0 paths; E50/E51/E52 NEW v4). **N-EMIT** (inline) writes the artifact set including v4 NEW files (`graph.schema.json`, briefing-core + 5 appendices, `tests/run-regression-suite.sh`). When `--behavioral-test` is set, **N-BEHAVIORAL** (Wave 10c, advisory only) runs an end-to-end smoke against the produced skill. Throughout the pipeline, every node declares uniform `## Failure modes` enabling **graceful degradation** (DD-02 / Goal-2): retry exhaustion produces a `degradation_notice:`-tagged stage file rather than a HALT, and the orchestrator surfaces all such notices to the user without blocking emission. Token budget for typical mode is ≈87K (vs v3.1.0's 126K — meeting Goal-1's 20-30% reduction target).
