---
node_id: N-FUSION-ANALYZE
node_type: AGGREGATION
hat: aggregator
exec_type: spawn
tier: model-large
conditional: true
mode_gate: "evolution_mode in ['evolve', 'evolve-aggressive']"
scale_gates: {token_budget: 8000, time_budget: 300, spawn_budget: 1, retry_budget: 1}
input_ports:
  - port: skill_concept_brief
    format: text
    required: true
  - port: normalize_digest
    format: markdown
    signal_field: normalize_digest
    required: true
  - port: context_inventory
    format: markdown
    signal_field: context_inventory
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
  - port: fusion_plan
    format: markdown
    signal_field: fusion_plan
  - port: fusion_decisions
    format: markdown
    signal_field: fusion_decisions
raises_signals: [fusion_plan, fusion_decisions, fusion_overflow_flag]
required_output_sections: [context_inventory_classified, precedence_stack, delta_matrix, optimization_opportunities, unified_topology, preservation_map, divergence_map, inheritance_map, risk_assessment, fusion_decisions]
---

## INPUT ports
- skill_concept_brief: text — the user's brief / optimization objective (P1 authority).
- normalize_digest: markdown — N-NORMALIZE's distilled brief representation (provides INVENTORY items + signals derived from the brief).
- context_inventory: markdown — N-CONTEXT-ANALYZE's classification of context-derived items.
- evolution_mode: signal — `evolve` | `evolve-aggressive` (this node only fires when in one of those modes).
- `--context`: filesystem path to the reference skill (P3 authority).
- `--context-spec`: filesystem path to the enhancement spec (P2 authority).

## OUTPUT ports
- fusion_plan: markdown (signal_field: fusion_plan) — unified topology proposal + maps.
- fusion_decisions: markdown (signal_field: fusion_decisions) — complete audit trail of every override.

## AI advantages exploited
- multi_perspective_simulation        # holds brief / spec / skill perspectives concurrently to compute deltas
- cross_document_pattern_recognition  # matches identical concepts across heterogeneous sources
- topology_aware_reasoning            # proposes graph-level synthesis, not local patches
- full_corpus_retention               # holds three artifact corpora in working memory through the precedence pass

## Role in pipeline (spec §3.4)
N-FUSION-ANALYZE is a Wave-2 conditional node that fires only when `evolution_mode in {evolve, evolve-aggressive}`. It replaces the legacy "preservation contract" emission of N-CONTEXT-ANALYZE with a holistic **fusion plan** that treats the brief, spec, and original skill as design peers and synthesizes the best possible unified topology.

It runs AFTER N-CONTEXT-ANALYZE (which still runs first to extract per-source artifacts) and BEFORE the Wave-3 analyzers (N-TOPOLOGY / N-DECOMPOSE / N-CONSTRAINTS) which consume `fusion_plan` instead of (or in addition to) `context_inventory`.

In `overlay` mode, this node is skipped entirely (mode_gate fails); the v4.2 pipeline executes unchanged.

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-FUSION-ANALYZE: briefing-core + briefing-appendix-topology + briefing-appendix-antipatterns + briefing-appendix-contract (§EC-FC04 external-contract registry). (briefing-appendix-vocab consulted on-demand for AP-15 framing.) -->

1. **Mode-gate guard.** Read `stages/N-PREFLIGHT.md`. Extract `evolution_mode`. If `evolution_mode not in ['evolve', 'evolve-aggressive']`: write a one-line stage file `## fusion_skipped\nmode=<mode>` and emit `fusion_plan_emitted: false`. The orchestrator will treat the absent fusion_plan as a no-op for downstream nodes (which fall back to legacy context_inventory consumption). Stop.

2. **Load and classify all contexts (spec §3.4 step 1).** Read each available context source and append to `context_inventory[]`. Auto-detect type per spec §3.2 unless an override is supplied via `CONTEXT_TYPE_HINT` / `CONTEXT_SPEC_TYPE_HINT` env vars.

   Auto-detection rules:

   | Context source | Auto-detection rule | Confidence floor |
   |---|---|---|
   | `<CONTEXT_PATH>` | `SKILL.md` AND `graph.json` AND `modules/` present → `skill_executable`. `modules/` only → `module_library`. Multiple subdirs each looking like skills → `skill_family`. | 0.85 |
   | `<CONTEXT_SPEC_PATH>` | YAML frontmatter with `spec_type` field OR title contains "GOTSCS" / "enhancement spec" / topology delta tables → `spec_enhancement`. Otherwise free-text markdown → `design_brief`. | 0.80 |
   | `skill_concept_brief.txt` | Always classified as `design_brief` (the user's prompt is the optimization objective). | 1.00 |

   When auto-detection confidence falls below the floor, log `auto_detect_uncertain: true` for that source. The session does NOT halt; downstream uses the best-guess type but flags the uncertainty in `fusion_decisions[]`.

   When the override env var is set, auto-detection is bypassed and the override value is recorded with `source: "user-override"`.

   Emit `context_inventory[]` rows of the form:
   ```
   { path, detected_type, confidence, role, override_applied, auto_detect_uncertain }
   ```
   where `role` is the fixed role per type:
   - `skill_executable` → role: "reference"
   - `spec_enhancement` → role: "design_intent"
   - `design_brief` → role: "optimization_objective"
   - `skill_family` → role: "pattern_library"
   - `module_library` → role: "component_library"

3. **Extract topology from each context independently (spec §3.4 step 2).**
   - **Original skill (`skill_executable`):** parse `graph.json` for nodes[], edges[], waves; parse `SKILL.md` for INVENTORY[] (HARD GATES section, HC-* items); enumerate aggregation carriers (nodes with `aggregation_policy` field).
   - **Spec (`spec_enhancement`):** parse YAML frontmatter (`target_version`, `node_count` if present); extract topology delta tables (sections titled "Modified Module", "New Module", "Removed Module", or YAML blocks with `action: preserve | upgrade | replace | merge | add | remove`). Capture proposed node IDs, edge IDs, and policy changes.
   - **Brief (`design_brief`):** infer topology intent via keyword scan:
     - "faster" / "parallel" / "concurrent" → implies parallelization (more spawn nodes; stronger parallel_dispatch fanout).
     - "simpler" / "merge" / "consolidate" → implies node merging.
     - "ultimate" / "best possible" / "optimal" → implies aggressive global optimization (sets `brief_redesign_intent: aggressive`).
     - "preserve" / "minimal change" / "conservative" → implies preservation bias (sets `brief_redesign_intent: conservative`; downgrades to overlay if user did not explicitly ask for fusion).
     - "future-proof" / "adaptable" / "any future design" → implies generalization preference for flexible nodes.
     - Brief silence on a given dimension is recorded as `brief_silent: true` for that dimension.

4. **Compute delta matrix (spec §3.4 step 3).** For every node / edge / policy / INVENTORY item that appears in any context, record what each context says. One row per item:
   ```json
   {
     "item_id": "<N-FOO | E12 | HC-07 | AGG-3 | INV-19>",
     "item_kind": "node | edge | policy | inventory | aggregation_carrier",
     "original_skill": { "action": "preserve | upgrade | replace | absent", "details": <verbatim signature> },
     "spec":           { "action": "preserve | upgrade | replace | merge | add | remove | silent", "details": <verbatim spec text or null> },
     "brief":          { "action": "evolve | preserve | silent", "intent": <inferred intent or null>, "quote": <brief substring or null> },
     "resolved_action": "<action chosen by precedence resolution in step 6>",
     "authority": "<P1 brief | P2 spec | P3 original | P4 default>",
     "rationale": "<why this action won — cite the winning source verbatim>"
   }
   ```
   The matrix is the canonical input for steps 5–7. Persist to `stages/fusion-delta-matrix.json` (raw) AND embedded in the rendered fusion_plan.

5. **Identify optimization opportunities (spec §3.4 step 4).** Scan the delta matrix for:
   - **Mergeable nodes:** original node X and (spec-added OR brief-implied) capability Y that overlap >70% in their `output_ports` or `raises_signals`.
   - **Removable edges:** edges in the original graph that exist solely to route around an absent capability now provided by a new node.
   - **Reorderable waves:** new pipeline logic implied by brief or spec that could collapse adjacent waves OR resequence dependents.
   - **Generalizable INVENTORY:** original INVENTORY items that are domain-specific where the brief implies a more general contract.

   Each opportunity is recorded as:
   ```json
   {
     "opportunity_id": "OPT-<NN>",
     "kind": "merge | remove | reorder | generalize",
     "items": ["<item_id>", ...],
     "rationale": "<why this is an optimization>",
     "authority_required": "<minimum precedence level needed to act on this — typically P1 brief>",
     "blocked_by_external_contract": <true if the item is in the skill's external contract (FC-04)>
   }
   ```

6. **Apply precedence stack (spec §3.3).** Resolve every conflict in the delta matrix using the precedence ladder:

   | Priority | Source | Authority |
   |---|---|---|
   | P1 | `design_brief` (the user's prompt) | Optimization objective — wins, EXCEPT when brief demands violate universal hard constraints (HC-02 caps, HC-03 edge typology, HC-04 closed-vocab, or any SECURITY-class constraint). |
   | P2 | `spec_enhancement` (--context-spec) | Design intent — wins over original skill when brief is silent. |
   | P3 | `skill_executable` (--context) | Reference implementation — wins over defaults when brief and spec are both silent. |
   | P4 | GOTSCS defaults / H.1-H.9 schema | Baseline — fallback only. |

   Resolution algorithm (per delta-matrix row):
   ```
   if brief.action != silent:
       if violates_universal_HC(brief.action):
           HALT with halt-on-brief-violation, include typed rationale citing the HC violated
       resolved = brief.action; authority = "P1 brief"
   elif spec.action != silent:
       resolved = spec.action; authority = "P2 spec"
   elif original.action != absent:
       resolved = original.action; authority = "P3 original"
   else:
       resolved = "default"; authority = "P4 default"
   ```

   **External-contract guard (FC-04 / FC-05).** Before locking in any `resolved_action != preserve` for an item classified as "external contract", enforce preserve-by-default. The canonical enumeration of external-contract items is **EC-FC04-1 through EC-FC04-5** in `briefing-appendix-contract.md` §EC-FC04 (read on N-FUSION-ANALYZE entry per HC-13b read-map).

   For each item NOT matched by registry IDs EC-FC04-1..5, evolve-mode divergence is permitted by default (subject to precedence stack + risk_assessment).

   For each item IN the registry:
   - If brief includes a literal `contract_override: EC-FC04-<N> — <reason>` declaration matching this specific item by registry ID, allow the divergence and persist the rationale verbatim into `fusion_decisions[]` with `external_contract_overridden: true`.
   - Otherwise, FORCE `resolved_action = preserve` regardless of P1/P2 silence on internal details. Mark the row `external_contract_locked: true` and add a `fusion_decisions[]` entry citing which registry ID applied (EC-FC04-1..5).

7. **Emit fusion_plan + fusion_decisions (spec §3.4 steps 6–7).** Compose the canonical `stages/N-FUSION-ANALYZE.md` containing the following sections in order:

   ```markdown
   ## context_inventory_classified
   <table from step 2>

   ## precedence_stack
   P1 design_brief > P2 spec_enhancement > P3 skill_executable > P4 GOTSCS defaults

   ## delta_matrix
   <full per-item table from step 4>

   ## optimization_opportunities
   <list from step 5>

   ## unified_topology
   - nodes_proposed: [...]
   - edges_proposed: [...]
   - waves_proposed: [...]
   - inventory_proposed: [...]
   - aggregation_carriers_proposed: [...]
   - delta_summary: { preserved_count, upgraded_count, replaced_count, merged_count, added_count, removed_count, resequenced_count, recontracted_count }

   **H1 fix — arithmetic closure self-check (BLOCKING).** Before emitting the artifact, the node MUST verify three internal closures:

   1. **Headline-vs-atomicity preserve count match.** If a §0 / `## Summary` headline ever states "N preserved verbatim", that N MUST equal `delta_summary.preserved_count` AND equal the row-count of the §3.1 per-item table where `resolved_action == 'preserve'`. If the three numbers diverge, HALT with `halt-fusion-arithmetic-headline-vs-atomicity` listing all three values.

   2. **Source ↔ target closure equation.** `target_total == source_total + adds - removes - merges_consumed + merges_produced`. Compute both sides; HALT with `halt-fusion-arithmetic-closure` if the equation does not hold (within tolerance 0).

   3. **Atomicity-class addition equation.** `sum(8 categories) == |source_topology| + |new_atoms|` where `|source_topology| = nodes + edges + aggregations from P3`, and `|new_atoms| = adds`. Internal counts include both nodes and edges (atomicity is per-item, not per-node).

   **Comment-residue regex check (H5 fix — anti-WIP-leakage).** Scan the assembled artifact text for residual work-in-progress tokens before emit:
   ```
   PATTERN: (?i)\b(wait|TODO|FIXME|XXX|sic|??|--correct--)\b
   ```
   Match within numeric-fields (lines containing `_count:`, `total:`, or numeric comparators) HALTs with `halt-fusion-residual-wip-token` listing the line. Match outside numeric fields emits an advisory in `## notes`.

   **Port-additive node disambiguation rule (H1 fix — atomicity-vs-semantic).** A node with port-additive-only changes (additive port set, FC-04 invocation signature stable, no consumer breakage) MAY be classified `preserve` in §5.1 atomicity arithmetic and `upgrade` in §3.1 per-item resolved_action. These are NOT contradictory. When this dual classification applies, the row's rationale field MUST contain the literal string `"atomicity-preserve / semantic-upgrade dual classification"`.

   ## preservation_map
   <every node/edge/INVENTORY item with origin="preserved"; rows: {item_id, kind, authority="P3 original", original_signature}>

   ## divergence_map
   <every item with origin in {upgraded, replaced, merged, added, removed, resequenced, recontracted}; rows: {item_id, kind, origin, authority, divergence_rationale, original_signature_or_null, new_signature, regression_risk: low|medium|high (required when origin in {replaced, removed})}>

   ## inheritance_map
   <every item, with `inherited_from: brief | spec | original | invented`>

   ## risk_assessment
   <summary of regression risks across divergences; flag any "high" risks separately>

   ## fusion_decisions
   <complete audit trail per spec §3.3 step 6 — one entry per resolved conflict: {conflict_id, winning_source, losing_source, rationale, brief_quote_or_null, external_contract_locked: bool}>

   ## waiver_justification
   <verbatim contents of stages/waiver_justification.txt — present only when evolution_mode == 'evolve-aggressive'>
   ```

   **Overflow behavior (spec §3.4).** Always emit a boolean `fusion_overflow_flag` (true OR false — never null). On the success path with no truncation: emit `fusion_overflow_flag: false`. If the combined input corpus (brief + spec + skill artifacts as ingested) exceeds 6000 tokens after step 3, emit `fusion_overflow_flag: true` and apply low-confidence truncation:
   1. Lower-confidence sources (per `confidence` field in step 2) are truncated FIRST.
   2. Within a source, content prefixed with "(advisory)" or "(non-blocking)" is dropped before mandatory content.
   3. Every truncation MUST log a `fusion_decisions[]` entry with `winning_source: "overflow_truncation"` and the dropped content's identifying signature.

   **Boolean-not-null contract (Tier-3 audit fix).** Strict consumers of SIGNAL_STATE (the orchestrator Wave-2 barrier and N-VERIFY V26 sub-checks) test `fusion_overflow_flag is True` or `fusion_overflow_flag is False`. A null value indicates the writer never executed; surface as a degradation_notice rather than silent null.

8. **Wave 2 barrier dependency (AP-14).** This node's stage file MUST exist before Wave 3 dispatches when `evolution_mode in {evolve, evolve-aggressive}`. The orchestrator (SKILL.md STEP 2) is responsible for the barrier — if `fusion_skipped` is recorded in step 1 (mode-gate fail), Wave 3 proceeds without waiting for `stages/N-FUSION-ANALYZE.md`.

## Scale gates
- tokens: 8000
- time: 300s
- spawns: 1 (this node IS a spawn)
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit a degraded fusion_plan with `confidence: low`, `truncated: true`, AND `fusion_overflow_flag: true`. Pipeline does NOT halt — N-AGG-DESIGN must be defensive against degraded fusion_plan.
- malformed output: re-run step 7 only; preserve delta-matrix work persisted to disk in step 4.
- missing input (stages/N-NORMALIZE.md or stages/N-CONTEXT-ANALYZE.md absent): HALT with `halt-fusion-missing-prereq` listing the absent stage file. Should be unreachable if Wave 2 barrier is honored.
- precedence violation (HC-02/03/04 cap exceeded by P1 demand): HALT with `halt-on-brief-violation` per spec §3.3 universal-constraint floor.
- format-mismatch on Edge: re-read the upstream stage files directly by path.

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-FUSION-ANALYZE
  retry_count: <n>
  last_error_class: timeout | malformed | overflow | precedence_violation
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt unless the failure is `precedence_violation` (which MUST halt per §3.3). Orchestrator propagates degradation_notice to N-VERIFY (informational); N-VERIFY's residual battery includes a check that flags any `divergence_map` entry whose `regression_risk == "high"` AND the corresponding `fusion_decisions[]` entry is missing — that pair is a structural defect.
