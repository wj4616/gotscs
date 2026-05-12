---
name: gotscs
description: "Graph-of-Thought Skill-Creation Skill (GOTSCS) v4.3.0 — all 4 evolution-spec phases COMPLETE. Builds executable Claude Code skills from a text brief, with two operating modes for context-bearing invocations: preservation overlay (--strict, single-context default) and context fusion (--evolve / --evolve-aggressive, multi-context default). v4.3 cumulative deltas vs v4.2.0 — Phase 1: new conditional Wave-2 node N-FUSION-ANALYZE synthesizes brief + spec + skill via precedence stack P1 brief > P2 spec > P3 original > P4 default; new flags --strict / --evolve / --evolve-aggressive / --waiver-justification / --no-fusion-doc / --context-type / --context-spec-type; evolution_mode signal propagated through SIGNAL_STATE 2.2 → 2.3; N-CONTEXT-ANALYZE emits context_advisory + redesign_candidates in evolve mode; 5 new edges (E60-E64); schema cap raised 60 → 65 edges (GOTSCS itself only). Phase 2: N-CONSTRAINTS mode-dependent emission (hard / soft / fusion_constraints FC-01..FC-09); N-DECOMPOSE 8-category task taxonomy (preserve/upgrade/replace/merge/add/remove/resequence/recontract) with atomicity arithmetic; N-AGG-DESIGN consumes fusion_plan as authoritative design seed + emits fusion_task_trace coverage table; external-contract registry §EC-FC04 in briefing-appendix-contract. Phase 3: N-EMIT step 4.4 emits FUSION.md (suppressible via --no-fusion-doc) + REGRESSION.md (always) into produced skill; RATIONALE.md extended with Fusion Redesign Justifications; N-VERIFY V26 residual check (sub-checks a/b/c/d/f BLOCKING in evolve mode; e advisory; covers FC-07 / FC-03 / FC-08 / FC-09); N-SKILL-RENDER §0 GENESIS block (`## GENESIS` heading) in produced skills under evolve+. Phase 4: briefing-core.md §EVOLVE schema extension (EVOLVE-1..6); HC-27 V4.3-ROLLBACK-TRIGGER added to HARD GATES (15 items now); rollback metadata in graph.json + 48-hour rollback window; tests/behavioral-fusion/ scaffold for end-to-end FUSION-01..12 acceptance (wire-up deferred to Phase 5 / external CI harness). 20 nodes (3 conditional), 64 edges, 10 Waves. Schema_version graph-v4-3 IS in force; edge cap 60 → 65 (internal). Backward-compat: v4.2 invocations (single --context, --context-spec, or --strict with 2 contexts) produce identical downstream behavior in evolution_mode in {greenfield, overlay}. Determinism: non-deterministic. Replacement of prior version on disk MUST gate through HC-26 RELEASE-SAFETY-GATE (5-brief regression battery + v4.2.x backup) AND post-release 48-hour rollback window per HC-27."
version: 4.3.0
graph_file: graph.json
hats_file: hats.json
topology: full GoT + Wave-modular + fusion-conditional
waves: 10
nodes: 20
edges: 64
determinism_class: non-deterministic
---

# GOTSCS v4.3.0 — Orchestrator (all 4 evolution-spec phases complete)

A meta-skill that converts a text-form skill concept brief into a complete executable Claude Code skill package, a human-readable specification document, or both. v4.3.0 extends v4.2.0 with the context-fusion pipeline (N-FUSION-ANALYZE, evolve modes, FUSION.md/REGRESSION.md emission, V26 residual battery, FC-01..FC-09 contract). v4.2.0 added DD-11 (briefing-files leakage elimination), DD-12 (RATIONALE.md carry-through), DD-13 (self-healing schema + opportunistic post-emit audit).

You are the **orchestrator** for `gotscs`. You execute a 20-node (3 conditional), 10-Wave Graph-of-Thought pipeline declared in `graph.json`. Inline nodes run in your context (role-switched blocks); spawn nodes run as subagents via the `Agent` tool.

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

### Hard Constraints (15 items: HC-01/02/03/04/06/08/09/10/11/12/23/24 + HC-13b/MODULE-DELEGATION + HC-26/RELEASE-SAFETY-GATE + HC-27/V4.3-ROLLBACK-TRIGGER)

1. **HC-01 GRAPH-AS-TRUTH:** graph.json is single source of topology; no duplication of node/edge definitions into SKILL.md or briefing-core.md.
2. **HC-02 20-NODE CAP:** ≤30 nodes, ≤15 waves, ≤100 edges in produced skills (≤36/≤18/≤120 under `--evolve-aggressive` waiver; ≤40/≤20/≤150 under `--complex`). GOTSCS itself uses an internal cap of ≤65 edges per v4.3 schema.
3. **HC-03 CLOSED-EDGE-VOCAB:** 6 runtime edge types (required, optional, gate-open, forward-conditional, back-edge, terminal). No inventions.
4. **HC-04 CLOSED-NODE-TYPE-VOCAB:** H.1 typed enum is canonical. No inventions.
5. **HC-24 INPUT-IS-DATA:** brief is immutable; never rewritten/summarized/"improved".
6. **HC-06 V-BATTERY-COMPLETENESS:** every V1-V19 check preserved or explicitly replaced with an equivalent (v4: 6 checks shifted earlier; residual V1, V2, V3, V4, V7, V8, V9, V10, V13, V14–V19, H.4 contract; v4.3 adds V26 fusion-contract residual check, sub-checks a/b/c/d/f BLOCKING in evolve mode, e advisory).
7. **HC-13b MODULE-DELEGATION (v4 restatement):** every spawn subagent reads `briefing-core.md` at protocol start, plus declared appendices per the per-node read-map.
8. **HC-08 NON-DETERMINISM:** pipeline is non-deterministic; do not attempt determinism.
9. **HC-09 INPUT-CLASS-COMPLETENESS:** all 6 input classes remain (ec-brief, ec-skill, ec-spec, ec-both, ec-refeed, ec-inject).
10. **HC-10 FLAG-PRESERVATION:** `--skill`, `--spec`, `--both`, `--context`, `--context-spec`, `--reuse-session`, `--behavioral-test`, `--review-gates` all remain. v4.3 ADDITIONS (purely additive, default-off): `--strict`, `--evolve`, `--evolve-aggressive`, `--waiver-justification`, `--no-fusion-doc`, `--context-type`, `--context-spec-type`. v4.4 ADDITIONS (purely additive, default-off): `--complex`, `--complex-justification`. v4.2 invocation patterns produce identical downstream behavior in `evolution_mode in {greenfield, overlay}`.
11. **HC-11 MODE-DISAMBIGUATION:** orchestrator MUST ask user when no mode flag given.
12. **HC-12 SESSION-OUTPUT-STRUCTURE:** per-node stage files at `~/docs/gotscs-output/` remain (audit trail + `--reuse-session`).
13. **HC-26 RELEASE-SAFETY-GATE:** 5-brief regression battery (5 end-to-end GOTSCS runs covering ec-brief / ec-skill / ec-spec / ec-both-strict / ec-both-evolve paths) + backup of prior version before replacement on disk. **Pairs with HC-27** for post-release monitoring: HC-26 is the pre-release gate; HC-27 is the post-release rollback window. Both must be honored for v4.3 deployment.
14. **HC-23 PARALLEL-DISPATCH:** parallel spawn nodes in the same wave MUST be dispatched in a single response (single-response parallel dispatch).
15. **HC-27 V4.3-ROLLBACK-TRIGGER (NEW v4.3 Phase 4):** if ≥1 overlay-mode skill fails regression within 48 hours of v4.3.0 release, revert to v4.2.x via the v4.2.0 SHA-256 baseline at `/tmp/gotscs-v4.2.0-baseline.sha256` and freeze the v4.3 branch until root-caused. Re-engagement requires root-cause fix + fresh 5-brief regression battery per HC-26 RELEASE-SAFETY-GATE (run GOTSCS end-to-end on 5 distinct briefs covering ec-brief / ec-skill / ec-spec / ec-both-strict / ec-both-evolve paths; HC-13b is a separate concern about subagent briefing reads). See briefing-core.md §EVOLVE-6 for full procedure.

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
| AP-V19 | HIGH | HC-26 safety gate (5-brief battery enforces real content delta) |
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

**`--strict-procedural` flag (G-10 — NEW v4.1; default off).** Parse `--strict-procedural` from the invocation flags. If present: export `STRICT_PROCEDURAL=true`. When active, the following advisory classes are promoted to HARD FAIL (pipeline halts at wave barrier with `halt-on-strict-procedural-violation`):
- HC-23 single-response parallel-dispatch violations (V20 fires as HARD FAIL, not advisory)
- exec_type-declaration deviations (inline declared, dispatched as spawn or vice-versa), except when exec_type_conditional gate correctly promoted the exec_type
- V8a/V8b spawn-count metadata claimed-vs-computed mismatch above a delta tolerance of 0
- Wave dispatch-count mismatch (wave declared N spawns; orchestrator dispatched M ≠ N)

**Default off** — this preserves the v3.1.0→v4.0 graceful-degradation contract for normal runs. Enable for high-stakes runs where protocol precision matters more than graceful continuation. N-VERIFY reads `STRICT_PROCEDURAL` env var to determine whether to promote these advisories to HARD FAIL.

**`--strict-dispatch` flag (G-01 companion; default off).** Promotes V20 HC-23 dispatch-granularity advisory to HARD FAIL when set. Subsumed by `--strict-procedural` when both are present.

**`--no-post-audit` flag (NEW v4.2 — DD-13; default off).** Parse `--no-post-audit` from the invocation flags. If present: export `NO_POST_AUDIT=true`. When active, the opportunistic post-emit audit (STEP 10b.5; via `epiphany-audit-v2` when installed) is skipped with an explicit "skipped (--no-post-audit)" status line. Default behavior (flag absent) is to attempt the audit if the audit skill is installed; if not installed, skip silently with a one-line installation hint. The audit is **always advisory-only** — never gates the build, never modifies the produced skill. See N-EMIT.md step 4d for the four-branch behavior matrix.

---

## STEP 0 — INIT + PRC1

### 0.1 Read input + parse context flags
The skill_concept_brief is the user's message (or content passed as argument). Write it to `<session_dir>/skill_concept_brief.txt`.

Parse and export context flags:
```bash
# Parse from the invocation args:
CONTEXT_PATH=""              # set if --context <path> was supplied
CONTEXT_SPEC_PATH=""         # set if --context-spec <path> was supplied
REUSE_SESSION_ID=""          # set if --reuse-session <id> was supplied (P-007)
BEHAVIORAL_TEST=""           # set if --behavioral-test was supplied (P-006)
REVIEW_GATES=""              # set if --review-gates was supplied (NEW v4 / DD-01)
NO_POST_AUDIT=""             # set if --no-post-audit was supplied (NEW v4.2 / DD-13)
STRICT_FLAG=""               # set if --strict was supplied (NEW v4.3)
EVOLVE_FLAG=""               # set if --evolve was supplied (NEW v4.3)
EVOLVE_AGGRESSIVE_FLAG=""    # set if --evolve-aggressive was supplied (NEW v4.3)
WAIVER_JUSTIFICATION=""      # set if --waiver-justification "<text>" was supplied (NEW v4.3)
COMPLEX_FLAG=""              # set if --complex was supplied (NEW v4.4)
COMPLEX_JUSTIFICATION=""     # set if --complex-justification "<text>" was supplied (NEW v4.4; optional)
NO_FUSION_DOC=""             # set if --no-fusion-doc was supplied (NEW v4.3)
CONTEXT_TYPE_HINT=""         # set if --context-type <type> was supplied for --context (NEW v4.3)
CONTEXT_SPEC_TYPE_HINT=""    # set if --context-spec-type <type> was supplied for --context-spec (NEW v4.3)
export CONTEXT_PATH CONTEXT_SPEC_PATH REUSE_SESSION_ID BEHAVIORAL_TEST REVIEW_GATES NO_POST_AUDIT
export STRICT_FLAG EVOLVE_FLAG EVOLVE_AGGRESSIVE_FLAG WAIVER_JUSTIFICATION COMPLEX_FLAG COMPLEX_JUSTIFICATION NO_FUSION_DOC
export CONTEXT_TYPE_HINT CONTEXT_SPEC_TYPE_HINT
```
These env vars are read by N-PREFLIGHT step 3a for HC-25 validation, step 4a for evolution_mode resolution (NEW v4.3), by Wave-conditional dispatch logic, by the optional review-gate hops at STEPs 5b and 8b (`REVIEW_GATES`), and by the opportunistic post-emit audit at STEP 10b.5 (`NO_POST_AUDIT`).

**v4.3 mode flags overview (full semantics in N-PREFLIGHT step 4a):**
- `--strict` — force preservation overlay even when 2+ contexts supplied (backward-compat with v4.2.0 multi-context behavior)
- `--evolve` — force context-fusion mode (default for 2+ contexts; redundant when default)
- `--evolve-aggressive --waiver-justification "<text>"` — fusion with relaxed topology caps (≤36 nodes / ≤18 waves / ≤120 edges); requires waiver string ≥50 chars (FC-09)
- `--complex` — relaxed topology caps (≤40 nodes / ≤20 waves / ≤150 edges) with NO fusion pipeline; mutually exclusive with `--evolve` / `--evolve-aggressive`
- `--no-fusion-doc` — suppress `FUSION.md` emission in evolve mode (audit trail still computed; not persisted)
- Mutually exclusive: `--strict` cannot combine with `--evolve` or `--evolve-aggressive`. `--complex` cannot combine with `--evolve` or `--evolve-aggressive` (REFUSE on conflict).

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
~/.claude/skills/gotscs/scripts/validate-graph.sh --expect-nodes 20 --expect-edges 64
```
Expected: `PRC1 PASS: 20 nodes (3 conditional), 64 edges`

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
Initialize in-memory SIGNAL_STATE (**schema 2.3** — NEW v4.3: adds `evolution_mode`, `contexts_provided_count`, `fusion_plan`, `fusion_decisions`, `fusion_overflow_flag`, `context_advisory`, `redesign_candidates`, `waiver_justification` fields for the fusion pipeline. Preserves all v4.2 (schema 2.2) fields):
```
SIGNAL_STATE = {
  "schema_version": "2.3",
  "mode": MODE,
  "preflight_status": null, "input_class": null, "normalize_digest": null,
  "evolution_mode": null, "contexts_provided_count": null, "waiver_justification": null,
  "topology_digest": null, "decompose_digest": null, "constraints_digest": null,
  "context_inventory": null, "validation_mode": false, "conflict_signals": [],
  "context_advisory": null, "redesign_candidates": null,
  "fusion_plan": null, "fusion_decisions": null, "fusion_overflow_flag": null,
  "design_blueprint": null, "gate_pass": null, "gate_diagnostic": null,
  "registry_result": null, "edges_result": null, "waves_result": null,
  "graph_spec": null, "spec_path": null, "spec_complete": null,
  "modules_result": null, "json_result": null, "skill_render_result": null,
  "verify_pass": null, "verify_result": null, "emit_complete": null,
  "behavioral_result": null, "behavioral_pass": null,
  "review_gate_audit": [], "degradation_notices": [],
  "retry_count_design": 0, "retry_count_artifact": 0, "repair_targets": [],
  "dispatch_log": []
}
executed_nodes = []
```

**Backward-compat note (HC-10).** Schema 2.2 SIGNAL_STATE files remain readable: any pre-v4.3 field absence is treated as `null` (e.g., `evolution_mode` absent → resolved to `overlay` for single-context, `greenfield` for no-context; the v4.3 GAP guard below handles this by accepting both 2.2 and 2.3).

**Sync mode to disk immediately after initialization (using sync-signal.sh helper per P-005):**
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" mode="$MODE"
```

**Assert v4.3 schema fields present (GAP-001 guard, extended).**
```bash
python3 - "$SESSION_DIR/SIGNAL_STATE.json" << 'PYEOF'
import json, sys
ss = json.load(open(sys.argv[1]))
errors = []
sv = ss.get("schema_version")
if sv not in {"2.2", "2.3"}:
    errors.append(f"schema_version={sv!r} (expected '2.2' or '2.3')")
# Schema 2.2 fields (still required)
for f in ("degradation_notices", "review_gate_audit"):
    if f not in ss:
        errors.append(f"missing field: {f}")
# Schema 2.3 fields (required when init-session.sh is from v4.3+; v4.2-init sessions tolerated)
if sv == "2.3":
    for f in ("evolution_mode", "contexts_provided_count", "fusion_plan", "fusion_decisions", "fusion_overflow_flag", "context_advisory", "redesign_candidates", "waiver_justification"):
        if f not in ss:
            errors.append(f"v4.3 missing field: {f}")
if errors:
    print(f"HALT: SIGNAL_STATE schema mismatch — {'; '.join(errors)}. Re-check init-session.sh.", file=sys.stderr)
    sys.exit(1)
print(f"SIGNAL_STATE schema v4 ({sv}): OK")
PYEOF
```
HALT if this assertion fails — it means `init-session.sh` wrote a stale schema and graceful-degradation or fusion state will be silently lost.

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
- If `preflight_status == 'pass'`: read `evolution_mode` and `contexts_provided_count` from `stages/N-PREFLIGHT.md` (NEW v4.3); sync all four fields to disk then proceed to Wave 2:
  ```bash
  ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
    preflight_status="$PREFLIGHT_STATUS" \
    input_class="$INPUT_CLASS" \
    evolution_mode="$EVOLUTION_MODE" \
    contexts_provided_count="$CONTEXTS_PROVIDED_COUNT"
  ```
  When `evolution_mode == 'evolve-aggressive'`: also sync `waiver_justification` (read from `stages/waiver_justification.txt`).

---

## STEP 2 — WAVE 2: N-NORMALIZE (inline) + N-CONTEXT-ANALYZE (spawn, conditional) + N-FUSION-ANALYZE (spawn, conditional, evolve mode only)

**Wave 2 dispatch order (NEW v4.3 — all three nodes have wave: 2 in graph.json but execute in two phases):**
- **Phase 2a (parallel):** N-NORMALIZE (inline) + N-CONTEXT-ANALYZE (spawn, fires only when input_class in {ec-skill, ec-spec, ec-both}). Both written before Phase 2b begins.
- **Phase 2b (sequential after 2a):** N-FUSION-ANALYZE (spawn, fires only when evolution_mode in {evolve, evolve-aggressive}). Depends on Phase 2a output.

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

**Conditional dispatch of N-FUSION-ANALYZE (NEW v4.3 — spec §3.4).** AFTER N-CONTEXT-ANALYZE has written its stage file, evaluate `evolution_mode`. If `evolution_mode in {evolve, evolve-aggressive}`: dispatch N-FUSION-ANALYZE in a SECOND, dependent response (it requires N-CONTEXT-ANALYZE's output, so cannot be parallelized with the first dispatch):

```
Agent(
  description="GOTSCS N-FUSION-ANALYZE: synthesize brief + spec + skill into unified fusion_plan",
  prompt="You are executing node N-FUSION-ANALYZE in the GOTSCS pipeline.
Read briefing-core.md + briefing-appendix-topology.md + briefing-appendix-antipatterns.md (HC-13b per-node read-map).
Read and follow modules/N-FUSION-ANALYZE.md exactly.
Inputs: stages/N-PREFLIGHT.md, stages/N-NORMALIZE.md, stages/N-CONTEXT-ANALYZE.md, plus stages/context-advisory.md when present.
CONTEXT_PATH env var = <value of CONTEXT_PATH>
CONTEXT_SPEC_PATH env var = <value of CONTEXT_SPEC_PATH>
Output: write stages/N-FUSION-ANALYZE.md with the 11 required sections (context_inventory_classified, precedence_stack, delta_matrix, optimization_opportunities, unified_topology, preservation_map, divergence_map, inheritance_map, risk_assessment, fusion_decisions, waiver_justification (if applicable))."
)
```

In `overlay` and `greenfield` modes: skip N-FUSION-ANALYZE entirely; do not write its stage file. The Wave-3 analyzers fall back to v4.2 behavior (consume `context_inventory` directly).

**Wave 2 barrier:** N-NORMALIZE always completes; N-CONTEXT-ANALYZE completes only when fired; N-FUSION-ANALYZE completes only when `evolution_mode in {evolve, evolve-aggressive}`. Confirm `stages/N-NORMALIZE.md` exists; verify `stages/N-CONTEXT-ANALYZE.md` exists IFF `input_class in {ec-skill, ec-spec, ec-both}`; verify `stages/N-FUSION-ANALYZE.md` exists IFF `evolution_mode in {evolve, evolve-aggressive}`. Sync to disk via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" normalize_digest=present
if [[ -f "$SESSION_DIR/stages/N-CONTEXT-ANALYZE.md" ]]; then
  ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
    context_inventory=present validation_mode=true
  if [[ -f "$SESSION_DIR/stages/context-advisory.md" ]]; then
    ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
      context_advisory=present redesign_candidates=present
  fi
fi
if [[ -f "$SESSION_DIR/stages/N-FUSION-ANALYZE.md" ]]; then
  ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
    fusion_plan=present fusion_decisions=present
  # F003 fix: surface overflow flag if N-FUSION-ANALYZE recorded one (truncation visibility for N-VERIFY).
  if grep -qE '^(##\s*)?fusion_overflow_flag:\s*true' "$SESSION_DIR/stages/N-FUSION-ANALYZE.md"; then
    ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" fusion_overflow_flag=true
  fi
fi
```

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

**Dispatch log (G-01/HC-23 enforcement):** Immediately after issuing the three Agent calls (in the same response), append to `SIGNAL_STATE["dispatch_log"]`:
```json
{"wave": 3, "response_id": "<current_response_id>", "spawn_ids": ["N-TOPOLOGY", "N-DECOMPOSE", "N-CONSTRAINTS"]}
```
Use a consistent `response_id` value (e.g., `"wave3-dispatch"`) to mark that all three came from one response. Sync to disk:
```bash
~/.claude/skills/gotscs/scripts/dispatch-parallel.sh "$SESSION_DIR" 3 N-TOPOLOGY N-DECOMPOSE N-CONSTRAINTS
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
- **G-12: Also display any flagged rows (⚠️) from `stages/metadata-diff.md`** (written by N-AGG-DESIGN step 6c). These rows represent unresolved conflicts between brief/spec/skill metadata values; user confirmation closes the ambiguity before Wave 6 proceeds.
- Block until user replies "approve", "modify <text>", or "abort".
- On "approve": continue to STEP 6.
- On "modify <text>": fire E11 RP-01 back-edge to N-AGG-DESIGN with the modify text as remediation_payload. Treat as a normal retry (counts toward `retry_count_design`).
- On "abort": HALT with `halt-on-user-abort-wave5`.
- Log the verdict to `stages/review-gate-wave5.md` (REVIEW_GATE_AUDIT sink per spec line 191).
- This hop is **orchestrator-state, NOT a graph node** (per DD-01 + AP-V29).

---

## STEP 6 — WAVE 6: N-REGISTRY + N-EDGES + N-WAVES (parallel spawn + inline)

Attention-reset: Read `modules/N-WAVES.md` (required for the inline N-WAVES execution below — N-WAVES runs first; N-REGISTRY and N-EDGES read their own modules per HC-13b when dispatched as spawns).

**N-WAVES (inline — run FIRST, before spawns):** Follow `modules/N-WAVES.md` (already loaded by attention-reset above). Read `stages/N-DESIGN-GATE.md` (the passthrough section). Write `stages/N-WAVES.md`.

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

**Dispatch log (G-01/HC-23 enforcement):** After dispatching N-REGISTRY + N-EDGES in the same response, append to dispatch_log:
```bash
~/.claude/skills/gotscs/scripts/dispatch-parallel.sh "$SESSION_DIR" 6 N-REGISTRY N-EDGES
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

**N-JSON exec-type gate (G-02).** Evaluate the exec_type_conditional from `modules/N-JSON.md` BEFORE dispatching anything this wave:
```python
# Read node/edge counts from stages/N-SYNTH-GRAPH.md frontmatter
node_count = <parsed from stages/N-SYNTH-GRAPH.md>
edge_count  = <parsed from stages/N-SYNTH-GRAPH.md>
est_kb = node_count * 1.8 + edge_count * 0.5 + 5
n_json_spawn = (node_count > 12 or edge_count > 20 or est_kb > 20)
```
- If `n_json_spawn=True`: **dispatch N-MODULES AND N-JSON in the same response** (parallel dispatch per HC-23 / I-01). N-MODULES reads from N-SYNTH-GRAPH/N-REGISTRY/N-EDGES (all Wave 8 outputs); N-JSON reads from N-SYNTH-GRAPH. No shared write targets — safe to overlap.
  ```
  Agent(description="GOTSCS N-MODULES: generate per-node module files",
    prompt="Execute N-MODULES per modules/N-MODULES.md.
  Read briefing-core.md and briefing-appendix-contract.md first (HC-13b).
  Input: <session_dir>/stages/N-SYNTH-GRAPH.md
  Output: write each module to <session_dir>/stages/modules/<node_id>.md (per-file emission per P-001).
  Write a thin index manifest to <session_dir>/stages/N-MODULES.md (no embedded module bodies).")

  Agent(description="GOTSCS N-JSON: serialize graph.json and hats.json",
    prompt="Execute N-JSON per modules/N-JSON.md. exec_type_resolved: spawn (n_json_spawn=True gate).
  ...")
  ```
  Log both to dispatch:
  ```bash
  ~/.claude/skills/gotscs/scripts/dispatch-parallel.sh "$SESSION_DIR" 9 N-MODULES N-JSON
  ```

- If `n_json_spawn=False`: dispatch N-MODULES as spawn, execute N-JSON **inline** as role-switched block (scale_gates: 3000 tokens, 300s). N-MODULES can run concurrently while N-JSON runs inline.
  ```
  Agent(description="GOTSCS N-MODULES: generate per-node module files", ...)
  ```
  ```bash
  ~/.claude/skills/gotscs/scripts/dispatch-parallel.sh "$SESSION_DIR" 9 N-MODULES
  ```
  Then execute N-JSON inline.

Execute N-JSON per `modules/N-JSON.md` (inline or spawn per gate above). Write `stages/N-JSON.md`. **N-JSON must complete and its stage file must exist before N-SKILL-RENDER is dispatched (P0-4 ordering constraint).** This is a hard sequential dependency: N-SKILL-RENDER sources scale_gates values from the graph_json_content block; if N-JSON is repaired after a failed first pass, N-SKILL-RENDER must read the repaired values or it will emit a stale §1 Node Registry table (V13(e) failure).

**N-SKILL-RENDER inline (P-002).** Execute N-SKILL-RENDER as an inline role-switched block per `modules/N-SKILL-RENDER.md` **only after `stages/N-JSON.md` exists**. Do NOT run N-SKILL-RENDER concurrently with N-JSON. N-SKILL-RENDER reads 4 stage files (N-NORMALIZE, N-CONSTRAINTS, N-SYNTH-GRAPH, N-JSON) plus `briefing-core.md`. Reads 3 prior stage files (N-NORMALIZE, N-CONSTRAINTS, N-SYNTH-GRAPH) plus `briefing-core.md`. **v4 delta (DD-03):** N-SKILL-RENDER no longer embeds Appendix A briefing inline — it references `briefing-core.md` instead. This drops the N-SKILL-RENDER token budget from 16K (v3.1.0) to 10K (v4). Assembles the full SKILL.md content (§0 HARD GATES with verbatim inventory_items, §1 through §7) and writes to `stages/N-SKILL-RENDER.md`. N-EMIT (STEP 10b) consumes this file directly via `cp` — no re-rendering at emit time. This is the authoritative SKILL.md content for V11 verification.

**Wave 9 barrier:** All Wave 9 stage files must exist (N-MODULES, N-JSON, N-SKILL-RENDER per P-002). Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
  modules_result=present json_result=present skill_render_result=present
```

---

## STEP 10a — WAVE 10: N-VERIFY (spawn) — RESIDUAL BATTERY

Attention-reset: Read `modules/N-VERIFY.md`.

Dispatch N-VERIFY as spawn. **v4 deltas (DD-07):** tier shifted from `model-large` → `model-medium`; `token_budget` cut from 20000 → 12000. The residual battery comprises: V1, V2, V3, V4, **V5-ext** (BLOCKING — INGEST connectivity final gate), V7, V8, V9, V10, **V11** (BLOCKING per P-003 — final attestation after upstream left-shift), V13(a/b/c/e), V14, V15, V16, V17, V18, V19 (final completeness), **V20** (HC-23 dispatch granularity), **V21** (HG-04 closure), **V22** (token-budget arithmetic), **V23** (hats.json array format), **V24** (AP guard orphan check, --context runs, advisory), **V25** (topology label vs. edge-density, advisory), and H.4 contract verification. **V6, V12, V13(d) are pre-shifted upstream** to producing-wave nodes (DD-06 left-shift); V5/V11 were pre-shifted but N-VERIFY retains a final blocking attestation for both.

```
Agent(description="GOTSCS N-VERIFY: run residual V-battery (post-DD-06 left-shift)",
  prompt="Execute N-VERIFY per modules/N-VERIFY.md.
Read briefing-core.md and ALL 5 appendices (briefing-appendix-topology.md, briefing-appendix-contract.md, briefing-appendix-memory.md, briefing-appendix-antipatterns.md, briefing-appendix-vocab.md) first (HC-13b DD-03 read-map — N-VERIFY is the only node that loads the full briefing complement).
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
  - **v4 NEW (DD-06):** If `'registry_v13d_fail' in repair_targets`: fire E50 (N-VERIFY→N-AGG-DESIGN). If `'edges_early_v_fail' in repair_targets`: fire E51 (N-VERIFY→N-AGG-DESIGN). **De-dup rule (F004):** if BOTH `'registry_v13d_fail'` AND `'edges_early_v_fail'` are in repair_targets simultaneously, fire **only E50** — merge both repair notes into the E50 payload and skip E51 to prevent double N-AGG-DESIGN dispatch in the same retry cycle. If `'modules_v6_fail' in repair_targets`: fire E52 (N-VERIFY→N-MODULES).
  Re-run N-VERIFY after re-execution of dispatched targets. Increment `retry_count_artifact`. **Sync to disk:** write updated `retry_count_artifact` and `repair_targets` back to `$SESSION_DIR/SIGNAL_STATE.json` immediately after incrementing.
- If `verify_pass=false` AND `retry_count_artifact >= 1`: emit partial skill with advisory "Verification failed after 1 repair attempt. Review stages/N-VERIFY.md for details."
- If `verify_pass=true`: proceed to N-EMIT. Sync verify_pass + verify_result to disk (NEW v4.2 — closes signal-coverage gap observed in v4.1 runs where `verify_result` stayed `null` despite N-VERIFY producing a valid stage file):
  ```bash
  ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
    verify_pass=true verify_result=present
  ```

---

## STEP 10b — WAVE 10: N-EMIT (inline)

Execute N-EMIT inline per `modules/N-EMIT.md`.
Write output files to `<session_output_base>/<skill_name>/`. **v4.2 output set (DD-11 — briefing files removed):** SKILL.md (with §8 RUNTIME CONVENTIONS inlined), graph.json, graph.schema.json (self-healing per DD-13), hats.json, modules/ (per-skill node count), RATIONALE.md (when rationale-bearing source content exists, per DD-12), tests/run-smoke-tests.sh, tests/behavioral/ scaffolds, tests/run-regression-suite.sh.
Record in `executed_nodes`.

**Back-edge routing (schema-fail):** If N-EMIT step 4b sets `emit_complete=false` with `'schema-fail' in repair_targets`: route via **E59 (N-EMIT→N-JSON)**. N-JSON re-runs steps 1.5(c2)+(c3)+(f) to auto-correct tier normalizations and regenerate the per-skill schema; increment `retry_count_artifact` via sync-signal.sh; then re-attempt N-EMIT. If `retry_count_artifact >= 1` on entry: halt with `halt-on-post-emit-validation-fail`.

Emit to user (select block by MODE):

**MODE=skill:**
```
## GOTSCS Complete

Skill written to: ~/docs/gotscs-output/<skill_name>/

Files:
  SKILL.md                  # includes §8 RUNTIME CONVENTIONS — fully self-contained
  graph.json
  graph.schema.json         # self-healing at smoke-test time (DD-13)
  hats.json
  modules/ (per-skill node count)
  RATIONALE.md              # design intent carry-through (DD-12; emitted when source content exists)
  tests/run-smoke-tests.sh
  tests/run-regression-suite.sh
  tests/behavioral/         # EC2/EC4/EC15 scaffolds

Post-emit audit: <POST_EMIT_AUDIT_STATUS — populated by STEP 10b.5; one of: PASS / PASS-with-findings / ERROR / skipped (...)>

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

## STEP 10b.5 — Opportunistic post-emit audit (NEW v4.2 — DD-13)

**Run iff `NO_POST_AUDIT` is unset AND the audit skill is installed.** The full behavior is documented in `modules/N-EMIT.md` step 4d. This step is orchestrator-state only (NOT a graph node — same pattern as `--review-gates` at STEPs 5b/8b, per AP-V29).

Steps:
1. If `NO_POST_AUDIT=true`: append `Post-emit audit: skipped (--no-post-audit)` to the user-facing emit block. Continue to STEP 10c.
2. If `~/.claude/skills/epiphany-audit-v2/SKILL.md` does not exist: append `Post-emit audit: skipped (epiphany-audit-v2 not installed; optional)` to the user-facing emit block. Continue to STEP 10c.
3. Otherwise: invoke the audit per N-EMIT step 4d's specification. Capture `POST_EMIT_AUDIT_STATUS`. Append it to the user-facing emit block between the file list and the install instructions.

**Three guarantees** (preserved from the N-EMIT step 4d contract):
1. Never fails the build. Audit findings are advisory; the authoritative quality gate is N-VERIFY (STEP 10a).
2. Never silently passes when it didn't actually run. Each of the four branches surfaces an explicit status line; users cannot mistake "no output" for "audit said all good".
3. Read-only. Hard-coded `--audit` flag; never `--fix` or `--improve` against the freshly emitted skill.

Sync via P-005 helper:
```bash
~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
  post_emit_audit_status="$POST_EMIT_AUDIT_STATUS"
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

The Registry contains 20 nodes (17 unconditional + 3 conditional: N-CONTEXT-ANALYZE, N-FUSION-ANALYZE, N-BEHAVIORAL). Schema validation is enforced via `graph.schema.json` at PRC1 (closed-vocab enums on `type`, `exec_type`, `tier` per HC-04).

## §1.5 AGGREGATION POLICIES

> "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."

GOTSCS v4.2.0 declares **three** aggregations (two mid-graph + one final). All policies live in `graph.json` on the aggregator nodes and are restated here for human-readable reference (HC-01: graph.json remains authoritative; this section is documentation-only).

| Aggregator | Wave | Role | Incoming branches | Aggregation policy / Join semantics |
|---|---|---|---|---|
| **N-AGG-DESIGN** | 4 | mid-graph #1 | N-TOPOLOGY, N-DECOMPOSE, N-CONSTRAINTS, +(N-CONTEXT-ANALYZE optional) | `triz-synthesize + contradiction-resolve; AND-join; branch_budget_cap=3 (+1 optional context)` |
| **N-SYNTH-GRAPH** | 7 | mid-graph #2 | N-REGISTRY, N-EDGES, N-WAVES | `weighted-merge + cross-table ID consistency check; AND-join; branch_budget_cap=3` |
| **N-VERIFY** | 10 | final contract-join | N-MODULES, N-JSON, N-SKILL-RENDER | `concatenate + residual V-battery (V1, V2, V3, V4, V5-ext, V7, V8, V9, V10, V11, V13(a/b/c/e), V14, V15, V16, V17, V18, V19, V20, V21, V22, V23, V24, V25, V26(a/b/c/d/e/f) [evolve mode], H.4); AND-join; branch_budget_cap=3` |

**Why TRIZ-synthesize at Wave 4:** the three Wave-3 analyses examine orthogonal axes (topology, decomposition, constraints) that often produce contradictions (e.g., a constraint may demand more nodes than the topology can hold). TRIZ separation principles (in time / in space / in condition / in structure) provide a disciplined contradiction-resolution vocabulary. Documented in `design_blueprint § contradiction_resolutions`.

**Why weighted-merge at Wave 7:** the Wave-6 outputs (Node Registry, Edge Table, Wave Plan) describe the same graph from three views. Weighted-merge prefers Edge Table for connectivity facts, Node Registry for cardinality, and Wave Plan for temporal facts; cross-table ID consistency check catches drift.

**Why concatenate at Wave 10:** the V-battery is composed of independent pass/fail checks, not synthesizable signals. Concatenation preserves the failure detail per check; AND-join derives `verify_pass`. v4 residual battery is ~40% smaller than v3.1.0's full battery because V5/V6/V11/V12/V13(d) shifted upstream per DD-06.

## §2 EDGE TABLE (HC-01 source-of-truth note)

**HC-01 GRAPH-AS-TRUTH:** the canonical Edge Table lives in `graph.json`. This SKILL.md file does NOT duplicate edge definitions.

To inspect:
- Read `graph.json` directly, or
- Run `~/.claude/skills/gotscs/scripts/validate-graph.sh --print-edges`

The Edge Table contains 64 rows. Edge type breakdown: required=15, optional=8, gate-open=3, forward-conditional=23, back-edge=10, terminal=5. Closed-vocab enforcement via `graph.schema.json` (HC-03).

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
| 2 | N-NORMALIZE; N-CONTEXT-ANALYZE (cond.); N-FUSION-ANALYZE (cond. evolve mode) | inline + 2 cond-spawns (phase 2a parallel + phase 2b sequential) | 2 (cond.) | 2 | 180s + 360s (evolve) | 0 | no | 1 |
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
| 2 | 9000–17000 (3000 NORMALIZE + 6000 CONTEXT-ANALYZE [conditional] + 8000 FUSION-ANALYZE [evolve mode only]) |
| 3 | 9000 (2000+4000+3000 — Wave-3 trio at spawn budgets) |
| 4 | 8000 |
| 5 | 2000 |
| 6 | 13000 (5000+5000+3000) |
| 7 | 8000 |
| 8 | 0 (mode=skill skips Wave 8) |
| 9 | 22000 (9000+3000+10000) — N-JSON budget is 3000 inline; promoted to 8000 spawn when node_count>12 or edge_count>20 per exec_type_conditional (G-02); large-skill total rises to ~27000 |
| 10 | 14000 (12000+2000) |
| **Total --skill** | **87000** (small-skill path); ~92000 (large-skill path when N-JSON promotes to spawn) |

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
11. **5-brief safety gate (HC-26 RELEASE-SAFETY-GATE):** N-PREFLIGHT enforces 5-brief regression battery (5 end-to-end GOTSCS runs covering ec-brief / ec-skill / ec-spec / ec-both-strict / ec-both-evolve) + v3.1.0 backup before disk replacement. (HC-13b is a distinct constraint covering subagent briefing-core reads — corrected from prior misattribution.)

### v4.2 deltas (DD-11/12/13)

12. **Briefing-files leakage eliminated (DD-11):** Produced skills no longer ship `briefing-core.md` or the 5 `briefing-appendix-*.md` files (~36 KB removed per produced skill). Build-time scaffolding stays in GOTSCS; runtime conventions referenced by the produced skill's prose are inlined into the produced SKILL.md as **§8 RUNTIME CONVENTIONS** by N-SKILL-RENDER. Produced skills run anywhere without GOTSCS installed. The "Read briefing-core.md" preamble is also removed from the emitted module template (was vestigial copy-paste).

13. **RATIONALE.md companion artifact (DD-12):** N-EMIT now emits `<skill>/RATIONALE.md` (Design Decisions, Contradiction Resolutions, Anti-Patterns Guarded, Calibration Points, Worked Example) when source content exists in the spec / `--context-spec`. Closes the "spec rationale evaporates into produced skill" information-loss channel observed in the v4.1 verified-research-report run.

14. **Self-healing schema (DD-13 / smoke-test integration):** When `graph.schema.json` is the GOTSCS-default and rejects the produced graph.json (e.g., domain-appropriate hats `synthesizer`/`adversarial`/`retriever` not in the closed vocab), the run-smoke-tests.sh template now derives a permissive per-skill schema from observed values and overwrites the file. Eliminates the schema-fallback embarrassment where produced skills shipped schemas that rejected their own state.

15. **Opportunistic post-emit audit (DD-13 / G-15):** New STEP 10b.5 invokes `epiphany-audit-v2 --audit` against the produced SKILL.md when the audit skill is installed; gracefully skips with one-line note when not. Never gates the build, never modifies the produced skill. New `--no-post-audit` flag for explicit opt-out. See N-EMIT.md step 4d for the four-branch behavior matrix.

16. **SIGNAL_STATE sync coverage extended:** Wave 2 barrier now syncs `context_inventory` when N-CONTEXT-ANALYZE fires; STEP 10a barrier syncs `verify_result` after N-VERIFY succeeds. Both fields previously stayed `null` in completed-run SIGNAL_STATE files despite valid stage outputs.

### v4.3 deltas (Phases 1-4 — context-fusion pipeline)

17. **N-FUSION-ANALYZE node (Phase 1):** new conditional Wave-2 spawn (phase 2b, sequential after Phase 2a) synthesizes brief + spec + skill via precedence stack P1 brief > P2 spec > P3 original > P4 default. Fires when `evolution_mode in {evolve, evolve-aggressive}`. Adds 1 node (20 total) and 5 edges (E60-E64). Schema cap raised 60 → 65 edges (GOTSCS itself only).

18. **Mode flags (purely additive, default-off):** `--strict` forces preservation overlay; `--evolve` forces context fusion (default for 2+ contexts); `--evolve-aggressive --waiver-justification "<text ≥50 chars>"` relaxes topology caps to ≤36/≤18/≤120 in produced skills; `--complex` relaxes caps to ≤40/≤20/≤150 without fusion pipeline; `--no-fusion-doc` suppresses FUSION.md emission; `--context-type` / `--context-spec-type` provide classification hints. Mutually exclusive: `--strict` cannot combine with `--evolve` or `--evolve-aggressive`; `--complex` cannot combine with `--evolve` or `--evolve-aggressive`.

19. **8-category task taxonomy (Phase 2):** N-DECOMPOSE emits per-node classification across 8 categories (preserve / upgrade / replace / merge / add / remove / resequence / recontract) with explicit atomicity arithmetic. N-CONSTRAINTS performs mode-dependent emission: hard / soft / fusion_constraints (FC-01..FC-09). N-AGG-DESIGN consumes fusion_plan as authoritative design seed and emits fusion_task_trace coverage table (canonical FC-03 risk_acknowledgment carrier).

20. **FUSION.md + REGRESSION.md emission (Phase 3):** N-EMIT step 4.4 emits FUSION.md (suppressible via `--no-fusion-doc`) + REGRESSION.md (always) into produced skill directory. RATIONALE.md extended with §6 Fusion Redesign Justifications (one block per divergence_map row, JSON-style record per spec §5.1.1).

21. **V26 residual contract (Phase 3):** N-VERIFY V26 sub-checks: (a) every fusion_decisions[] entry has rationale; (b) no external_contract_overridden without brief override; (c) FC-07 functional-contract preservation on recontract; (d) FC-03 risk_acknowledgment present on every fusion_task_trace row with `regression_risk in {medium, high}` AND `authority == "P1 brief"`; (e) FC-08 regression test register present in REGRESSION.md (advisory); (f) waiver_justification present iff `evolution_mode == 'evolve-aggressive'`. Sub-checks a/b/c/d/f BLOCKING in evolve mode; e ADVISORY.

22. **HC-26 / HC-27 release safety (Phase 4):** HC-26 RELEASE-SAFETY-GATE — 5-brief regression battery (ec-brief / ec-skill / ec-spec / ec-both-strict / ec-both-evolve) before disk replacement. HC-27 V4.3-ROLLBACK-TRIGGER — if ≥1 overlay-mode skill fails regression within 48h of release, revert to v4.2.x via SHA-256 baseline at `/tmp/gotscs-v4.2.0-baseline.sha256`. Re-engagement requires root-cause fix + fresh 5-brief battery.

23. **PRC1 expect-edges:** v4.3 ships with 64 edges (was 58 in v4.1, 59 in v4.2; v4.3 added E60-E64 fusion edges). The PRC1 invocation in STEP 0.3 uses `--expect-edges 64` to match `metadata.total_edges`.

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

For `--spec`/`--both`, **N-SPEC-ARTIFACT** (Wave 8) renders the human-readable spec.md (with optional `--review-gates` STEP 8b pause). For `--skill`/`--both`, Wave 9 runs **N-MODULES** (spawn, per-file emission per P-001), **N-JSON** (inline), and **N-SKILL-RENDER** (inline, P-002 dedicated renderer assembling the SKILL.md content with verbatim INVENTORY in §0 HARD GATES). Wave 10's **N-VERIFY** (now `model-medium` per DD-07, 12K tokens per DD-07) runs a residual V-battery — V5/V6/V11/V12/V13(d) are pre-shifted upstream (DD-06). On V-failure it back-edges to the appropriate node (E27/E28/E41 for v3.1.0 paths; E50/E51/E52 NEW v4). **N-EMIT** (inline) writes the artifact set — v4.2 output set (DD-11/12/13): `SKILL.md` (with §8 RUNTIME CONVENTIONS inlined), `graph.json`, `graph.schema.json` (self-healing per DD-13), `hats.json`, `modules/`, `RATIONALE.md` (when rationale-bearing source content exists, per DD-12), `tests/run-smoke-tests.sh`, `tests/behavioral/`, `tests/run-regression-suite.sh`. Briefing files (`briefing-core.md` + 5 appendices) are **not** emitted — removed in DD-11; runtime conventions are inlined into produced SKILL.md §8 instead. When `--behavioral-test` is set, **N-BEHAVIORAL** (Wave 10c, advisory only) runs an end-to-end smoke against the produced skill. Throughout the pipeline, every node declares uniform `## Failure modes` enabling **graceful degradation** (DD-02 / Goal-2): retry exhaustion produces a `degradation_notice:`-tagged stage file rather than a HALT, and the orchestrator surfaces all such notices to the user without blocking emission. Token budget for typical mode is ≈87K (vs v3.1.0's 126K — meeting Goal-1's 20-30% reduction target).
