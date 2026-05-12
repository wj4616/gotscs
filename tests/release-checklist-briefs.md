# GOTSCS v4.3.0 — 5-Brief Regression Battery (Concrete Prompts)

Operator artifact paired with `tests/release-checklist.md`. The checklist is the **procedural** runbook (when, why, in what order); this file is the **concrete fixtures** (what exact text to feed `/gotscs`).

Per HC-26 RELEASE-SAFETY-GATE: each brief is one end-to-end `/gotscs` invocation that exercises one input class. Wall-clock budget: 5–15 min per brief; total ~30–90 min for the full battery.

---

## Setup (run once before the battery)

```bash
# 1. Confirm existing skills exist for --context targets:
test -d ~/.claude/skills/prompt-cog && echo "context target OK"

# 2. Stage a sample enhancement spec to disk for --context-spec targets:
mkdir -p /tmp/gotscs-test-fixtures
cat > /tmp/gotscs-test-fixtures/sample-spec.md <<'EOF'
---
skill_name: text-line-deduper
target_version: 1.0.0
spec_type: skill_specification
node_count: 6
wave_count: 3
topology: linear-pipeline
---

# text-line-deduper

Deduplicate a list of text lines, preserving first-occurrence order.

## INVENTORY
- [PRESERVE-ORDER] First occurrence order preserved
- [HASH-COMPARISON] Lines compared by SHA-256 hash, not string equality (handles whitespace canonically)
- [BOUNDED-MEMORY] Hash set capped at 100k entries; spillover triggers advisory

## Calibration Points
- Whitespace at line ends is stripped before hashing.
- Empty lines are deduplicated like any other line.
EOF

# 3. Reference SHA-256 baselines (already captured during the v4.3 build):
ls -la /tmp/gotscs-v4.2.0-baseline.sha256 /tmp/gotscs-v4.3.0-baseline.sha256

# 4. Output staging:
mkdir -p /tmp/gotscs-battery-runs/{B1,B2,B3,B4,B5}
export GOTSCS_OUTPUT_BASE=/tmp/gotscs-battery-runs
```

**Reference-output strategy.** For Briefs 1-4 (overlay paths), the gold output is the v4.2.0 reference run on the same input. If you have a v4.2.0 install available, capture reference runs FIRST (run each brief against v4.2), then run on v4.3 and diff. For Brief 5 (evolve path), v4.2 falls back to overlay — the diff IS the new behavior.

---

## Brief 1 — `ec-brief` / greenfield path

**Path coverage:** N-PREFLIGHT (input_class=`ec-brief`, evolution_mode=`greenfield`) → N-NORMALIZE → Wave 3-10 with N-CONTEXT-ANALYZE skipped, N-FUSION-ANALYZE skipped. Tests the simplest pipeline: pure brief synthesis.

**Invocation:**
```
/gotscs "<BRIEF-1 text>" --skill
```

**BRIEF-1 text:**
```
Build a skill called log-line-classifier that classifies a list of input log lines into one of four severity buckets: ERROR, WARN, INFO, DEBUG. Each log line is a string; classification rules: lines containing "error", "exception", "fatal", "fail" → ERROR; "warn", "deprecated" → WARN; "info" or no severity keyword → INFO; "debug", "trace" → DEBUG. Output: a count per bucket plus a sample of up to 3 lines per bucket.

Constraints (INVENTORY items — preserve verbatim in HARD GATES):
- [DETERMINISM-EXACT] Same input produces byte-identical output every run.
- [CASE-INSENSITIVE-MATCH] Severity keyword matching is case-insensitive.
- [NO-EXTERNAL-IO] Reads only from the input list; writes only to a single output object.
- [BOUNDED-OUTPUT] Total output ≤2000 tokens regardless of input size; truncate samples first.

Pipeline should: ingest list, fail-fast on non-list input, classify each line, aggregate counts, emit structured output with one mid-graph aggregation.
```

**Post-run verification:**
- Pipeline reaches `emit_complete=true` (no halt)
- `cd ${GOTSCS_OUTPUT_BASE}/B1/log-line-classifier && bash tests/run-smoke-tests.sh` → ALL PASS
- Produced graph: ≥5 nodes, ≥1 mid-graph aggregation, ≥3 ai_advantages
- HARD GATES contains all 4 INVENTORY items VERBATIM (V11 substring match)
- No `FUSION.md` or `REGRESSION.md` (these are evolve-mode-only)
- No `## GENESIS` block in produced SKILL.md
- Diff vs v4.2 reference run: should be near-zero (same brief → same skill modulo non-determinism)

---

## Brief 2 — `ec-skill` / overlay path (single context)

**Path coverage:** N-PREFLIGHT (input_class=`ec-skill`, evolution_mode=`overlay`) → N-CONTEXT-ANALYZE (legacy `preservation_contract` branch — AP-15 in full force) → Wave 3-10. Tests v4.2-baseline overlay behavior under a single context.

**Invocation:**
```
/gotscs "<BRIEF-2 text>" --skill --context ~/.claude/skills/prompt-cog
```

**BRIEF-2 text:**
```
Enhance the prompt-cog skill (provided via --context) to add an --explain flag that, when set, emits a numbered list of the cognitive transformations applied during synthesis (e.g., "1. SCAMPER substitution applied to constraint X"). Otherwise, the skill behavior must be byte-identical to the existing version.

Constraints (INVENTORY items — preserve verbatim):
- [STRICT-OVERLAY-MODE] Every existing INVENTORY item from prompt-cog SKILL.md is preserved verbatim. AP-15 applies — no node replacement without documented structural defect.
- [ADDITIVE-ONLY] The --explain flag is purely additive; existing flags (--minimal, --quiet) unchanged.
- [DEFAULT-OFF] --explain defaults to off; absence produces v4.2-equivalent output.
- [BACKWARD-COMPAT] Callers using prompt-cog without --explain see no behavior change.

Add the flag handling at PREFLIGHT and propagate the explain_mode signal to the synthesis layer.
```

**Post-run verification:**
- N-CONTEXT-ANALYZE emits `preservation_contract` (NOT `context_advisory`)
- Produced skill's HARD GATES contains every original prompt-cog HC-* / AP-* item VERBATIM (V11 substring match)
- Produced skill has all original prompt-cog nodes preserved (per AP-15)
- New `--explain` flag visible in produced SKILL.md STEP 0.1
- No `FUSION.md` / `REGRESSION.md` / `## GENESIS` (overlay mode)
- Diff vs v4.2 reference: should be near-byte-identical (this is the most important overlay-mode regression check after Brief 4)

---

## Brief 3 — `ec-spec` / overlay path (single spec)

**Path coverage:** N-PREFLIGHT (input_class=`ec-spec`, evolution_mode=`overlay`) → N-CONTEXT-ANALYZE in validation_mode (Wave-3 analyzers run as validation branches against spec). Tests --context-spec without --context.

**Invocation:**
```
/gotscs "<BRIEF-3 text>" --skill --context-spec /tmp/gotscs-test-fixtures/sample-spec.md
```

**BRIEF-3 text:**
```
Build the text-line-deduper skill described in the supplied --context-spec. Honor the INVENTORY constraints verbatim. Use a linear pipeline with PREFLIGHT → INGEST → DEDUPER → FORMATTER → PERSISTER topology consistent with the spec's wave_count.
```

**Post-run verification:**
- N-CONTEXT-ANALYZE writes `stages/validation-mode.md`
- Wave-3 analyzers run as validation branches against the spec's claimed values
- Produced skill respects spec frontmatter: `node_count: 6`, `wave_count: 3`, `topology: linear-pipeline`
- HARD GATES contains all 3 INVENTORY items from the spec VERBATIM
- Calibration Points carried into `RATIONALE.md` (DD-12)
- No `FUSION.md` (overlay mode)
- Diff vs v4.2 reference: near-byte-identical

---

## Brief 4 — `ec-both` + `--strict` (v4.2 parity check, **most important**)

**Path coverage:** N-PREFLIGHT (input_class=`ec-both`, evolution_mode=`overlay` due to `--strict`) → both N-CONTEXT-ANALYZE branches run (skill + spec) → N-FUSION-ANALYZE skipped (mode_gate fails) → IC-04 source-precedence applied for skill-vs-spec conflicts. **This is the regression-critical brief**: produced output must match v4.2 byte-for-byte.

**Invocation:**
```
/gotscs "<BRIEF-4 text>" --skill \
  --context ~/.claude/skills/prompt-cog \
  --context-spec /tmp/gotscs-test-fixtures/sample-spec.md \
  --strict
```

**BRIEF-4 text:**
```
Update the prompt-cog skill (--context) to integrate the deduplication semantics described in --context-spec for its synthesis-stage output. The existing prompt-cog topology must be preserved verbatim per --strict (AP-15 in full force); the spec's INVENTORY items are added as additional HARD GATES, never substituted for existing ones.

Where the spec and the existing skill conflict on the same design element (e.g., wave count), apply IC-04 precedence: spec content (level 2) > skill content (level 3) > GOTSCS defaults (level 5). Do NOT use evolve mode — --strict is mandatory.
```

**Post-run verification:**
- evolution_mode resolved to `overlay` (verify in `stages/N-PREFLIGHT.md`)
- N-FUSION-ANALYZE NOT executed (no `stages/N-FUSION-ANALYZE.md`)
- N-CONTEXT-ANALYZE emits `preservation_contract` for the skill side (AP-15 enforced)
- Produced HARD GATES = (every prompt-cog HC) ∪ (every spec INVENTORY item) — verbatim, no substitution
- IC-04 precedence visible in `stages/N-AGG-DESIGN.md § Design Decisions`
- No `FUSION.md` / `REGRESSION.md` / `## GENESIS`
- **Diff vs v4.2 reference run with same inputs and `--strict`: MUST be byte-identical (or whitespace-equivalent). Any divergence is a v4.3 overlay-mode regression and triggers HC-27 rollback per the 48-hour window.**

---

## Brief 5 — `ec-both` + `--evolve` (fusion path, v4.3-only)

**Path coverage:** N-PREFLIGHT (evolution_mode=`evolve`) → N-CONTEXT-ANALYZE emits `context_advisory` + `redesign_candidates` → N-FUSION-ANALYZE synthesizes fusion_plan with precedence stack → mode-dependent emission in N-CONSTRAINTS / N-DECOMPOSE / N-AGG-DESIGN → N-EMIT step 4.4 writes FUSION.md + REGRESSION.md → N-VERIFY V26 sub-checks → produced SKILL.md gets `## GENESIS` block. Tests the entire v4.3 fusion machinery end-to-end.

**Invocation:**
```
/gotscs "<BRIEF-5 text>" --skill \
  --context ~/.claude/skills/prompt-cog \
  --context-spec /tmp/gotscs-test-fixtures/sample-spec.md \
  --evolve
```

**BRIEF-5 text:**
```
Synthesize the ultimate optimized version of prompt-cog (--context) and the deduplication semantics described in --context-spec into a single best-possible skill. Where the existing prompt-cog topology can be improved by integrating dedup-style hashing into its synthesis cache, redesign — do NOT preserve mechanically. The brief authority (P1) explicitly demands optimization for final utility (FC-06).

Optimization targets:
- Merge redundant verification stages into a single hash-cached verifier.
- Generalize the synthesis output schema to support both prompt-cog's existing format AND dedup-style content addressing.
- Eliminate any node whose function is fully subsumed by the merged design.

External contract preserved per FC-04: invocation flags (--minimal, --quiet) MUST remain callable; output schema's required top-level fields MUST be backward-compatible. All other internal details are open to redesign.

Document every divergence from prompt-cog in fusion_decisions[]; tag each with regression_risk; require risk_acknowledgment for medium/high.
```

**Post-run verification (most thorough — this is the v4.3-only path):**
- evolution_mode = `evolve` in `stages/N-PREFLIGHT.md`
- `stages/N-FUSION-ANALYZE.md` exists with all 10 required `## ` sections (fusion_sources, precedence_stack, delta_matrix, preservation_map, divergence_map, inheritance_map, risk_assessment, fusion_decisions, decomposition_tasks, fusion_constraints_applied) + YAML header fields (evolution_mode, gotscs_version, timestamp)
- `stages/N-DECOMPOSE.md` includes `## decomposition_tasks` with 8-category breakdown; atomicity check passes (sum of 8 categories == |countable_topology|)
- `stages/N-CONSTRAINTS.md` includes `## hard_constraints`, `## soft_constraints`, `## fusion_constraints` (FC-01..FC-09 all present)
- `stages/N-AGG-DESIGN.md` includes `## fusion_task_trace` with `risk_acknowledgment` column populated for medium/high divergences
- Produced skill directory contains:
  - `<skill>/FUSION.md` with all 10 `## ` sections
  - `<skill>/REGRESSION.md` with preserved-functionality + diverged-functionality test plans
  - `<skill>/RATIONALE.md` includes `## Fusion Redesign Justifications` section
  - `<skill>/SKILL.md` has bare `## GENESIS` block (NOT `## §0 GENESIS`) with evolution_mode + fusion_sources_count + fusion_decisions_count
- N-VERIFY V26 sub-checks all PASS:
  - V26(a) FUSION.md present + 10 sections + YAML header
  - V26(b) REGRESSION.md present
  - V26(c) FC-07 — every "replaced" node's output_ports is superset of original (or has contract_override)
  - V26(d) FC-03 — every medium/high-risk P1-brief divergence has risk_acknowledgment in fusion_task_trace
  - V26(f) skipped (`evolution_mode != evolve-aggressive`)
- External contract per EC-FC04 preserved: `--minimal` and `--quiet` flags still in produced SKILL.md invocation contract
- `cd <produced-skill> && bash tests/run-smoke-tests.sh` → ALL PASS

---

## Battery completion criteria

| Outcome | Action |
|---|---|
| All 5 briefs reach `emit_complete=true` AND each produced skill's own smoke tests PASS AND Briefs 1-4 byte-match v4.2 reference | **HC-26 satisfied** — proceed to on-disk replacement per `release-checklist.md` Step 3; start HC-27 48-hour window |
| Any brief halts unexpectedly OR any produced smoke test FAILS | **HC-26 fail** — root-cause before retry; do NOT replace v4.2 on disk |
| Brief 4 diff vs v4.2 reference > whitespace-equivalent | **OVERLAY REGRESSION** — most serious failure mode; v4.3 overlay claims byte-equivalence with v4.2 but doesn't deliver. Do NOT release; investigate which v4.3 change leaks into overlay mode |
| Brief 5 V26 sub-check fails (a/b/c/d/f) | **EVOLVE-MODE BUG** — fusion pipeline not contract-compliant; root-cause before retry |

---

## Optional `--evolve-aggressive` brief (Brief 5-aggressive, not required for v4.3.0 release)

For coverage of the FC-09 waiver-justification path. Not part of the mandatory HC-26 battery — promote here only if `--evolve-aggressive` is expected in production usage.

**Invocation:**
```
/gotscs "<BRIEF-5a text>" --skill \
  --context ~/.claude/skills/prompt-cog \
  --context-spec /tmp/gotscs-test-fixtures/sample-spec.md \
  --evolve-aggressive \
  --waiver-justification "Topology relaxation needed: merged pipeline requires 33 nodes due to dual-format output schema and three parallel synthesis branches; cannot fit within standard ≤30 cap."
```

**BRIEF-5a text:** Same as Brief 5 but additionally states the topology will exceed standard HC-02 caps (≤36 nodes / ≤18 waves / ≤120 edges in produced skill); waiver justification ≥50 chars persisted to `stages/waiver_justification.txt`, `FUSION.md`, and produced graph.json metadata per FC-09.

**Additional verification:**
- `stages/waiver_justification.txt` exists with content ≥50 chars
- `<skill>/FUSION.md` `waiver_justification:` field contains the verbatim string
- V26(f) PASSES (was skipped in standard Brief 5)
- Produced skill respects relaxed caps: ≤36 nodes / ≤18 waves / ≤120 edges in graph.json

## `--complex` brief (Brief 5b — NEW v4.4)

Tests the pure-headroom path without fusion pipeline.

**Invocation:**
```
/gotscs "A 35-node skill with 19 waves and 130 edges using multi-path synthesis and second-pass expansion" --skill --complex
```

**Brief text:** States explicitly that the design requires 35 nodes, 19 waves, and 130 edges. No context flags. No waiver justification.

**Additional verification:**
- `stages/complex_mode.txt` exists with content `true`
- `stages/cap_tier.md` exists with `tier: complex`, `max_nodes: 40`, `max_waves: 20`, `max_edges: 150`
- N-FUSION-ANALYZE is NOT dispatched (no `stages/N-FUSION-ANALYZE.md`)
- N-CONTEXT-ANALYZE emits legacy `preservation_contract` (not `context_advisory`)
- V7 PASSES with wave count 19 (≤20 cap)
- Produced skill respects complex caps: ≤40 nodes / ≤20 waves / ≤150 edges in graph.json
- `produced_skill_edge_cap_complex: 150` present in graph.json metadata
