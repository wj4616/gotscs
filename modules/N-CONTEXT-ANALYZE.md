---
node_id: N-CONTEXT-ANALYZE
node_type: ANALYZER
hat: analyzer
exec_type: spawn
tier: model-medium
conditional: true
scale_gates: {token_budget: 6000, time_budget: 300, spawn_budget: 1, retry_budget: 1}
input_ports:
  - port: skill_concept_brief
    format: text
    required: true
  - port: preflight_result
    format: markdown
    signal_field: preflight_status
    required: true
  - port: evolution_mode
    format: signal
    signal_field: evolution_mode
    required: true
  - port: --context
    format: filesystem-path
    required: false
  - port: --context-spec
    format: filesystem-path
    required: false
output_ports:
  - port: context_inventory
    format: markdown
    signal_field: context_inventory
  - port: validation_mode
    format: markdown
    signal_field: validation_mode
  - port: context_advisory
    format: markdown
    signal_field: context_advisory
  - port: redesign_candidates
    format: markdown
    signal_field: redesign_candidates
raises_signals: [context_inventory, validation_mode, context_advisory, redesign_candidates]
required_output_sections: [context_inventory, classification_table, validation_mode_flag]
---

## INPUT ports
- skill_concept_brief: text
- preflight_result: markdown (signal_field: preflight_status — must be 'pass')
- `--context`: filesystem path to existing skill dir (optional)
- `--context-spec`: filesystem path to prior spec.md (optional)

## OUTPUT ports
- context_inventory: markdown (signal_field: context_inventory)
- validation_mode: markdown (single-line flag file `validation_mode: true` written when ec-spec/ec-both)

## AI advantages exploited
- full_corpus_retention                # hold entire context skill/spec in working memory
- cross_document_pattern_recognition   # match nodes across context vs. derived design

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-CONTEXT-ANALYZE: briefing-core only. No appendices required. -->

1. **Determine input class from preflight_result.** Read `stages/N-PREFLIGHT.md`. Extract `input_class` AND `evolution_mode` (NEW v4.3). This node fires only when `input_class in {ec-skill, ec-spec, ec-both}` (HC-19 conditional gate).

   **Mode branch declaration (NEW v4.3 — spec §3.5).** Capture `evolution_mode` for use in step 3:
   - `overlay` (single-context default, OR `--strict` was set): emit the legacy `preservation_contract` exactly as v4.2.0 did. All INVENTORY items, nodes, edges, and aggregation carriers from the original skill are mandatory preservation targets. AP-15 (no-replacement-without-defect) applies in full force. This branch is byte-identical to v4.2.0 behavior — required for backward compatibility (HC-10).
   - `evolve` or `evolve-aggressive` (NEW): emit `context_advisory[]` (recommendations, not mandates) AND `redesign_candidates[]` (items the brief flags for redesign) INSTEAD of the blanket preservation_contract. Hand off to N-FUSION-ANALYZE (Wave-2) which performs the holistic synthesis and emits the unified `fusion_plan`. AP-15 still applies but is interpreted by the precedence stack: brief authority can override AP-15 by demanding redesign, with the cost of a populated `divergence_map` entry and `regression_risk` annotation.
   - `greenfield`: this node MUST NOT have fired (no context flags); reaching this branch with `greenfield` is a contract violation. HALT with `halt-on-mode-classification-mismatch`.

1.5. **v19_context_inventory_check (V19 pre-shifted from N-VERIFY per DD-04).** When `--context` is given: ensure that every node identified during the inventory pass receives a `context_source` field in {preserved, upgraded, replaced, new} and a one-sentence `context_rationale` BEFORE step 3 emits the inventory. Append both fields to each row of the classification table. This early shift means N-VERIFY only performs a residual completeness check (no per-node generation). If any node lacks either field after step 2 below: HALT with `halt-on-missing-context-source` listing the offenders.

2. **Branch on input class.**

   **For ec-skill (`--context <skill-dir>`):**
   a. Read `<skill-dir>/SKILL.md` and `<skill-dir>/graph.json`. Optionally read `<skill-dir>/briefing.md` and `<skill-dir>/modules/N-*.md`.
   b. **Pipeline classification (NEW v4.1).** Determine `pipeline_class`:
      - `graph-native`: skill has `graph.json` with explicit nodes/edges.
      - `linear-pipeline`: sequential steps with mode branches (no graph.json, SKILL.md describes a step-by-step pipeline).
      - `state-machine`: explicit states and transitions.
      - `hybrid`: graph + pipeline mixed.
      Default when graph.json is absent: `linear-pipeline`.
   c. **Per-pipeline_class node extraction (G-04).** Branch on `pipeline_class` determined in step 2.b:

      - **graph-native:** Extract every node from `<skill-dir>/graph.json`. For each node entry in the `nodes` array, derive: `node_id` (from `id` field), `node_type` (from `type`), `hat` (from `hat`), `exec_type` (from `exec_type`). Proceed to classification in step 2.d.
      - **linear-pipeline:** Parse `<skill-dir>/SKILL.md` for `## Section` headings or numbered top-level steps (regex `^## STEP|^## [A-Z]|^\d+\.\s+\*\*[A-Z]`). Each section/step ≥ ~50 lines is a candidate node. Synthesize: `node_id = N-<heading-slug>` (lowercase, hyphens); `node_type` from dominant verb in heading (`extract|ingest|read` → INGEST, `analyze|classify|inspect` → ANALYZER, `decide|gate|check` → GATE, `generate|emit|write` → GENERATOR, `verify|validate|audit` → VERIFIER, `synthesize|aggregate` → AGGREGATION, else GENERATOR); `hat` from H.6 catalogue best match. Warn in output if <3 candidates found. Log extraction method: `extraction_method: linear-pipeline-heading-parse`.
      - **state-machine:** Parse `## States` section or a state-transition table (markdown table with columns State/Event/NextState). Each state row becomes a node (`node_id = N-<state-slug>`); each transition becomes a candidate edge. Synthesize `node_type=GATE` for decision states, `node_type=ACTUATOR` for action states. Log: `extraction_method: state-machine-table-parse`.
      - **hybrid:** Apply graph-native extraction to whatever portion has `graph.json`; apply linear-pipeline extraction to the remaining SKILL.md sections not covered by the graph. Merge candidate lists, dedup by node_id. Log: `extraction_method: hybrid-merge`.
      - **fallback (0 candidates):** If extraction by the above methods yields 0 candidates: emit `pipeline_class: extraction_failed` in the stage file; note which method was tried and what was searched. Pass an empty `context_inventory` with `extraction_failed: true` — let downstream N-AGG-DESIGN decide whether to halt or design from the brief alone. Do NOT silently produce an empty inventory without the failure flag.

      Every extracted candidate, regardless of pipeline_class, MUST receive both `context_source` ∈ {preserved, upgraded, replaced, derived, new} and a one-sentence `context_rationale` BEFORE proceeding to step 2.d. If either field is absent for any candidate after extraction: HALT with `halt-on-missing-context-source` listing the offenders (same as step 1.5 gate).

   d. **Classify each extracted candidate:**
      - **preservation-candidate**: node carries forward unchanged (default if no defect/upgrade rationale)
      - **upgrade-target**: node carries forward with at least one of {corrected `node_type`, larger Protocol section, reduced tier (e.g., `model-large` → `model-medium`)}
      - **replace-target**: node is dropped or replaced. **REQUIRES** documented structural defect from N-TOPOLOGY or N-DECOMPOSE (AP-15: optimization preference alone is insufficient).
   e. Emit `context_inventory` markdown with the classification table (rows: `node_id | classification | rationale | structural_defect (if replace-target) | context_source | context_rationale`) plus a `pipeline_class` line and `extraction_method` note.

   **For ec-spec (`--context-spec <spec-path>`):**
   a. Read `<spec-path>` markdown file. Parse YAML frontmatter (`node_count`, `wave_count`, `topology` are required; pre-validated by N-PREFLIGHT step 3a).
   b. Extract the spec's claimed Node Registry, Edge Table, Wave Plan, and Aggregation Policies verbatim.
   c. Write `stages/validation-mode.md` containing the single line `validation_mode: true`. This file MUST exist before Wave 3 reads it (AP-14 barrier guarantee).
   d. Emit `context_inventory` markdown with the verbatim extracted tables; downstream Wave-3 analyzers will run as validation branches against this content.

   **For ec-both (both flags):**
   a. Run both branches above.
   b. When spec content and skill content conflict on the same design element, apply the **IC-04 source-precedence hierarchy** (briefing-core.md §IC-04): brief audit-fix D-NN override directives (level 1) > spec content (level 2) > skill content (level 3) > brief general text (level 4) > GOTSCS defaults (level 5). If two sources at the same level disagree: flag for REVIEW-GATE-W5; do not silently resolve.
   c. Write `stages/validation-mode.md`.
   d. Emit unified `context_inventory`.

2.5. **Classification arithmetic assertion (F-2.7 fix — Rank-9 audit finding).** After the classification table is fully built but before writing the stage file, run two arithmetic invariant checks:

   **(i) Skill-side accounting (when `--context` was given):** every node from the input skill's graph.json appears in the table exactly once. Compute:
   ```
   preserved_count + upgraded_count + replaced_count == len(input_skill_nodes)
   ```
   If not equal: HALT with `halt-on-classification-arithmetic-fail` listing the discrepancy (which input nodes are unaccounted for OR over-counted across {preserved, upgraded, replaced}).

   **(ii) Target-side accounting:** the produced skill's target node count is the sum of {preserved, upgraded, new, derived} (a `derived` node is one materialized from a `replace-target` per a documented design decision, e.g., monolithic SCORER → SCORER-TECHNICAL + SCORER-CREATIVE per DD-3). Compute:
   ```
   preserved_count + upgraded_count + new_count + derived_count == target_node_count
   ```
   where `target_node_count` is read from spec frontmatter (`node_count` field) when ec-spec / ec-both, OR computed from N-DECOMPOSE's `total_nodes_estimated` when ec-skill alone. If not equal: HALT with `halt-on-classification-arithmetic-fail` listing the discrepancy.

   **Implementation note:** record each row's classification AS IT IS EMITTED (do NOT reclassify after the fact). The two assertion totals are computed by SUMming the recorded classification labels, NOT by re-reading the table — this catches the F-2.7 transient-mismatch class where a subagent emits "3 preserved" then summarizes as "2 preserved" without updating the table.

   **Adversarial check:** a subagent could "round" boundary cases to make totals balance. Mitigation: each row's classification is locked once written; the assertions sum over the locked labels; reclassification requires regenerating the row, leaving an audit trail.

3. **Write outputs.**
   - Write `stages/N-CONTEXT-ANALYZE.md` containing the `context_inventory` block including `pipeline_class`.
   - When validation_mode is fired (ec-spec / ec-both), additionally write `stages/validation-mode.md` with a single line `validation_mode: true`.
   - Emit signals `context_inventory` and (when applicable) `validation_mode`.

3.5. **Mode-dependent emission (NEW v4.3 — spec §3.5).** After the standard outputs are persisted in step 3, branch on `evolution_mode`:

   **Branch: `overlay` (and `greenfield` already halted upstream).** Emit a `## preservation_contract` section in `stages/N-CONTEXT-ANALYZE.md` containing the v4.2.0 hard-preservation rules. Each row is a HC-, AP-, or INV- identifier with a one-line "thou shalt not change" rationale. This is the legacy authoritative output. No further action.

   **Branch: `evolve` or `evolve-aggressive`.** REPLACE the `preservation_contract` section with TWO new sections:

   ```markdown
   ## context_advisory
   <table of recommended-but-not-mandatory preservation items derived from the original skill's HC-, AP-, and INV- corpus. Schema:
     | advisory_id (AD-NN) | source (HC-/AP-/INV-) | recommendation | rationale | risk_of_changing | overrideable_by |
   The `overrideable_by` field MUST be `brief` for default items, `none` for items that constitute the external contract (FC-04: invocation signature, output schema, universal hard constraints).>

   ## redesign_candidates
   <list of items the brief explicitly flags for redesign. Each entry follows spec §3.5 example:
     {
       "candidate_id": "RC-NN",
       "item": "<node | edge | INVENTORY-id>",
       "reason_brief_demands_it": "<verbatim brief substring>",
       "risk_of_changing": "low | medium | high",
       "interacts_with": [<other items that would need to co-evolve>]
     }
   Empty list `[]` is valid (brief did not demand redesign of anything specific).>
   ```

   Write a separate stage file `stages/context-advisory.md` containing both sections (so N-FUSION-ANALYZE has a single canonical location to read the recommendation corpus). Set signals `context_advisory=present`, `redesign_candidates=present`.

   **Brief-scan algorithm for redesign_candidates.** For each item in the original skill's INVENTORY / node list / edge list, scan the brief for substrings matching:
   - "redesign <item>" / "redesigned <item>" / "redesign the <item>" — direct redesign demand.
   - "<item> ... should ... <verb-of-change>" where verb-of-change ∈ {evolve, change, replace, merge, drop, generalize, ultimate, optimize, future-proof, rewrite}.
   - Generic optimization demands ("ultimate optimized version", "best possible", "rewrite from scratch") flag ALL items as candidates with `reason_brief_demands_it` = the matching brief substring.

   When the generic-optimization match fires, the resulting `redesign_candidates[]` may be large. Truncate to the top 10 items by frequency-of-mention in original skill artifacts (most-referenced items most likely to drive design); record `redesign_candidates_truncated: true` with the full list count. N-FUSION-ANALYZE reads the full list from disk if needed.

4. **Wave 2 barrier dependency (AP-14, enforced by orchestrator at SKILL.md STEP 2).** This node's stage file MUST exist before Wave 3 dispatches. The orchestrator is responsible for the barrier — this Protocol step is a contract reminder, not an enforcement mechanism. The module itself completes when its writes succeed; the orchestrator's Wave-2 → Wave-3 transition is what blocks until both `stages/N-CONTEXT-ANALYZE.md` (and optionally `stages/validation-mode.md`) exist.

## Scale gates
- tokens: 6000
- time: 300s
- spawns: 1 (this node IS a spawn; declared in Wave 2 budget)
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit `context_inventory` with empty classification table flagged LOW confidence; orchestrator continues without context-driven Wave-3 validation
- malformed output: re-run step 3 only; preserve classification work
- missing input (--context or --context-spec stat fail): HALT with `halt-context-missing-required-files` — should have been caught by N-PREFLIGHT step 3a; if reached here, second-stage suspicious-target re-validation per HC-25
- format-mismatch on Edge: re-read the context skill dir / context-spec file directly by path

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-CONTEXT-ANALYZE
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
