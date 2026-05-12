---
node_id: N-AGG-DESIGN
node_type: AGGREGATION
hat: aggregator
exec_type: spawn
tier: model-large
scale_gates: {token_budget: 8000, time_budget: 600, spawn_budget: 2, retry_budget: 1}
aggregation_policy: "triz-synthesize + contradiction-resolve; AND-join; branch_budget_cap=3 (+1 optional context)"
input_ports:
  - port: topology_result
    format: markdown
    signal_field: topology_digest
    required: true
  - port: decompose_result
    format: markdown
    signal_field: decompose_digest
    required: true
  - port: constraints_result
    format: markdown
    signal_field: constraints_digest
    required: true
  - port: context_inventory
    format: markdown
    signal_field: context_inventory
    required: false
  - port: evolution_mode
    format: signal
    signal_field: evolution_mode
    required: true
  - port: fusion_plan
    format: markdown
    signal_field: fusion_plan
    required: false
output_ports:
  - port: design_blueprint
    format: markdown
    signal_field: design_blueprint
join_semantics: AND
raises_signals: [design_blueprint, contradiction_resolutions]
required_output_sections: [design_blueprint, contradiction_resolutions, aggregation_policy_declared]
---

## INPUT ports
- topology_result: markdown  (signal_field: topology_digest, AND-join)
- decompose_result: markdown  (signal_field: decompose_digest, AND-join)
- constraints_result: markdown  (signal_field: constraints_digest, AND-join)
- context_inventory: markdown (signal_field: context_inventory, optional 4th port; consumed iff stages/N-CONTEXT-ANALYZE.md exists at AND-join time per HC-18 / AP-19)

## OUTPUT ports
- design_blueprint: markdown  (signal_field: design_blueprint)

## AI advantages exploited
- multi_perspective_simulation       # synthesize three independent analysis axes
- cross_document_pattern_recognition # detect alignment and conflicts across branches
- topology_aware_reasoning           # reason over the whole-graph design holistically

## AGGREGATION POLICY (V9 — verbatim)
> "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."

- Decomposition tree: N-TOPOLOGY → topology_digest, N-DECOMPOSE → decompose_digest, N-CONSTRAINTS → constraints_digest
- Synthesis strategy: TRIZ-style synthesize + contradiction-resolve
- Join semantics: AND (wait for all three branches)
- Activation condition: all three input signals present
- Branch-budget cap: 3 (≤5 default; this aggregation has exactly 3 branches)

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-AGG-DESIGN: briefing-core + briefing-appendix-memory + briefing-appendix-antipatterns + (in evolve mode) briefing-appendix-contract §EC-FC04 (the external_contract_locked field surfaces in fusion_task_trace step 6e). -->

1. **Await AND-join.** Confirm all three required stage files exist: `stages/N-TOPOLOGY.md`, `stages/N-DECOMPOSE.md`, `stages/N-CONSTRAINTS.md`. If any missing: HALT with missing signal name. Confirm `stages/N-CONTEXT-ANALYZE.md` optionally — its presence/absence is determined at runtime by orchestrator per HC-19 (do NOT block on its absence).

1.5. **Mode-aware design seed selection (NEW v4.3 — spec §3.1, §3.6).** Read `evolution_mode` from `stages/N-PREFLIGHT.md`. Branch:

   **`overlay` and `greenfield` modes:** continue to step 2 unchanged. Design synthesis follows v4.2.0 contract: TRIZ over (topology_digest, decompose_digest, constraints_digest) + optional context_inventory. AP-15 in full force.

   **`evolve` and `evolve-aggressive` modes:** verify `stages/N-FUSION-ANALYZE.md` exists (HALT with `halt-fusion-prereq-missing` if absent). Read its `unified_topology`, `preservation_map`, `divergence_map`, `inheritance_map`, and `risk_assessment` sections. Treat `unified_topology` as the **authoritative design seed** for steps 3-6 — i.e., do NOT re-synthesize the node list from scratch; instead apply TRIZ contradiction-resolution only to the residual gaps after the three concrete consistency checks below.

   **Concrete consistency checks (replaces the v4.3-Phase-2 abstract "consistency" wording).** Three deterministic checks compare the Wave-3 digests against unified_topology:

   1. **Node-count parity.** `decompose_digest.total_nodes_estimated == |unified_topology.nodes_proposed|`. If unequal: append a `consistency_advisory: node-count-drift` entry with both numbers; do NOT HALT — TRIZ in step 3 may legitimately resolve.
   2. **Wave-count ceiling.** `topology_digest.wave_range.max ≥ max(unified_topology.waves_proposed)`. If violated: HALT with `halt-fusion-wave-cap-exceeded` (the unified topology cannot fit within Wave plan; brief must permit relaxation or design seed is malformed).
   3. **Constraint coverage.** Every entry in `unified_topology.inventory_proposed` MUST appear in `constraints_digest.inventory_items` OR in N-CONSTRAINTS `fusion_constraints` table OR be flagged as a brief-authority addition in fusion_plan.divergence_map. If not: append `consistency_advisory: inventory-coverage-gap` listing the orphan IDs; do NOT HALT.

   When operating from a fusion seed, additionally read N-DECOMPOSE's `decomposition_tasks` section and N-CONSTRAINTS's `hard_constraints` / `soft_constraints` / `fusion_constraints` sections. The 8-category task taxonomy from N-DECOMPOSE drives blueprint composition: every node in `blueprint_nodes` (defined in step 6 below as "the rows of the Node List table") MUST trace back to exactly one DT-NN task (the trace is recorded in step 6e below).

   **Authority preservation rule (FC-03).** If the brief authority (P1) drove a divergence with `regression_risk in {medium, high}`, the corresponding row in the **`fusion_task_trace`** table (step 6e) MUST include a `risk_acknowledgment:` cell with the exact `risk_assessment` text from fusion_plan, NOT in the Node List or Design Decisions tables. This single canonical location makes V26(d) check unambiguous: V26(d) reads `fusion_task_trace` rows and confirms every row with `regression_risk in {medium, high}` AND `authority == "P1 brief"` has a non-empty `risk_acknowledgment` cell. V18-blocking when surfaced in N-VERIFY (Phase 3 — V26 fusion-contract check).

2. **Read all three required digests AND optional context_inventory.** Extract:
   - From topology: topology_class, wave_range, features, wave_count_warning
   - From decompose: node_types list, branching_points, aggregation_points, total_nodes_estimated
   - From constraints: inventory_items list, anti_patterns_flagged, ai_advantages_selected
   - If `stages/N-CONTEXT-ANALYZE.md` exists: read it; extract the classification table from context_inventory.
   - **(NEW v4.3 evolve mode):** also extract from N-FUSION-ANALYZE's `unified_topology`: nodes_proposed, edges_proposed, waves_proposed, inventory_proposed, aggregation_carriers_proposed, delta_summary. From N-DECOMPOSE's `decomposition_tasks`: every DT-NN task with its category and target_item_id. From N-CONSTRAINTS's mode-dependent sections: hard_constraints (V11-blocking), soft_constraints (advisory), fusion_constraints (FC-01..FC-09).

2b. **EC8 pre-check (wave_count_warning).** If `wave_count_warning=true` from topology_digest: apply EC8 pruning discipline NOW, before synthesis begins. In order: (1) identify lowest-leverage branch in the decompose node_types; (2) flag any non-final mid-graph verifier for collapse; (3) cap redundant decomposition layers. Document which nodes are at risk of pruning. This constraint shapes the synthesis in step 3, preventing over-specification.

3. **TRIZ-style synthesis.** Apply inventive contradiction resolution:
   - For each conflict between branches (e.g., topology says 4 Waves but decompose needs 7 nodes requiring 6 Waves): apply TRIZ principle of segmentation or dynamics to find a design that satisfies both constraints.
   - Document each contradiction and resolution in `contradiction_resolutions`.

3b. **Conflict-signal resolution (HC-17 / V18 zero-silent-drop).** If any of stages/N-TOPOLOGY.md / N-DECOMPOSE.md / N-CONSTRAINTS.md emitted `conflict_signals`: for each signal, choose one of {confirm, modify, override} with rationale. Record every resolution in `contradiction_resolutions`. **No conflict_signal may be silently dropped** — V18 enforces this in N-VERIFY.

4. **EC4 handling.** If constraints_digest contains CONTRADICTION-A/B pairs: route each pair to a dedicated contradiction-resolution aggregation Node in the produced skill. Name the node (e.g., N-CONTRADICTION-RESOLVE). Add it to the design_blueprint node list.

4.5. **Scale-gate compliance at design time (V16-left-shift + aggregation spawn rule).**

After the node list is drafted but before writing the blueprint:

**(a) V16 inline budget enforcement.** For every node assigned `exec_type=inline` and `hat≠formatter`: check `token_budget ≤ 4000`. For `hat=formatter`: check `token_budget ≤ 16000`. If a budget exceeds the ceiling:
   - PREFERRED path: Convert to `exec_type=spawn` when the budget reflects genuine context complexity (the task requires large working memory — e.g., synthesis nodes, aggregation nodes with many inputs). Update `spawn_budget` in the wave plan accordingly.
   - FALLBACK path: Reduce `token_budget` to the ceiling (4000 or 16000). Add a note in the blueprint that the task scope must fit within this budget.
   Log each decision as: `V16-resolve: <node_id> spawn-promotion|inline-ceiling <original>→<final>`.
   This prevents V16 failures at N-VERIFY without consuming the repair budget.

**(b) AGGREGATION spawn rule.** For every AGGREGATION node with `join_policy=AND` and `input_stream_count ≥ 3`: default `exec_type=spawn`. Rationale: holding ≥3 parallel analysis outputs simultaneously in an inline context forces quality-degrading budget reduction. Inline is appropriate only when `input_stream_count ≤ 2`. Override only with documented justification.

**(c) Edge density advisory.** Compute `estimated_density = planned_edge_count / planned_node_count`. Compare against topology-appropriate floor:
   - ToT: advisory if density < 3.0
   - GoT-basic: advisory if density < 5.0
   - GoT-full: advisory if density < 5.0
   If below floor: log `density_advisory: <value> < <floor> for <topology>` in the blueprint. This does NOT block synthesis but surfaces the gap before N-SYNTH-GRAPH's C7 check, allowing early edge additions.

5. **Wave count enforcement (EC8).** If synthesis requires > 10 Waves: apply EC8 pruning in order: (1) lowest-leverage branch; (2) non-final mid-graph verifier; (3) redundant decomposition layer. Document each pruning in design_blueprint.

6. **Build design_blueprint.** Produce a structured specification. The **Node List** table rows are the canonical `blueprint_nodes` set (one node per row, identified by `node_id`); coverage assertions in step 6e and downstream count it precisely as `|blueprint_nodes| = number of rows in the Node List table excluding the header`.

   ```markdown
   ## design_blueprint

   ### Topology
   class: <topology_class>
   total_waves: <N>  (≤cap_tier.max_waves from stages/cap_tier.md)
   total_nodes: <derived from |Node List rows|>
   total_edges: <derived from |Edge Table rows|>
   aggregation_count: <derived from |Aggregation Points rows|>

   ### Node List
   <table: node_id | H.1 type | hat | exec_type | wave | description>

   ### Edge Table
   <table: edge_id | source → target | edge_type | signal_field | gate_condition | wave_traverse>

   ### Branching Points
   <list: wave N → fan-out to [node_ids]>

   ### Aggregation Points
   <list: wave N → AND-join from [node_ids] → aggregation_node>
     - mid_graph: <true|false>
     - synthesis_strategy: <strategy>

   ### Constraints Preserved
   <verbatim inventory_items list>

   ### Anti-Patterns Guarded
   <condensed from constraints_digest>

   ### AI Advantages Assigned
   <table: node_id | catalogue_keys>
   ```

   **H3 fix — edge-type-distribution emission rule.** N-AGG-DESIGN MUST NOT emit a separate "edge type distribution" footnote (e.g. `required: 19 / terminal: 2 / ...`) below the Edge Table — those numbers must be COMPUTED from the table by downstream consumers (HC-01: graph.json is single source of truth; this passthrough is the data carrier, not a tally aggregator). If a footnote is emitted for human readability, it MUST be derived programmatically from the table rows (recount before emit) and HALT with `halt-design-blueprint-edge-tally-mismatch` if the footnote disagrees with the row enumeration. **Preferred behavior: emit the table only; let N-EDGES / N-SYNTH-GRAPH / N-JSON compute distributions directly.**

6b. **Design Decisions section (when context_inventory present).** For each preserved/upgraded/replaced node from context_inventory, list:
   - node_id | context_classification | integrated_classification | rationale (one sentence)
   - For replace-target rationales: cite the specific structural defect identified by N-TOPOLOGY or N-DECOMPOSE (AP-15).

6e. **Fusion-task trace section (NEW v4.3 — evolve and evolve-aggressive modes only).** Emit a `## fusion_task_trace` table mapping every blueprint node to its driving DT-NN task from N-DECOMPOSE. The `risk_acknowledgment` column is the **canonical FC-03 location** (per step 1.5 Authority preservation rule):
   ```markdown
   ## fusion_task_trace
   | blueprint_node_id | task_id | category | authority | regression_risk | external_contract_locked | risk_acknowledgment |
   ```
   Cell rules:
   - `regression_risk` ∈ {low, medium, high, null} (null when category=preserve).
   - `risk_acknowledgment` MUST be non-empty when `regression_risk in {medium, high}` AND `authority == "P1 brief"`. Cell value is the verbatim `risk_assessment` text from fusion_plan for that node. Otherwise `risk_acknowledgment` is the literal string `n/a`.
   - V26(d) reads this column directly; never look elsewhere in design_blueprint for risk_acknowledgment.
   Coverage assertion: every blueprint node MUST appear in this table; every DT-NN task with category != "remove" MUST map to a blueprint node. Tasks with category="remove" are listed in a sibling `## fusion_removed_originals` table (the original node is documented as removed but not in the blueprint).
   ```
   sum(rows in fusion_task_trace) == |blueprint_nodes|
   sum(category != 'remove' tasks in N-DECOMPOSE.decomposition_tasks) == |blueprint_nodes|
   ```
   If either assertion fails: HALT with `halt-fusion-trace-arithmetic-fail` listing the diff. This is the v4.3 evolve-mode equivalent of N-CONTEXT-ANALYZE's classification arithmetic check (F-2.7 fix from v4.x).

6c. **Metadata diff across input sources (G-12).** After the design_blueprint node list and wave plan are fully drafted, emit a `## metadata_diff` section comparing all input sources:

```markdown
## metadata_diff
| field | brief value | spec value (--context-spec) | skill value (--context) | resolved | source-of-truth (IC-04) |
|---|---|---|---|---|---|
| total_nodes | <D-NN claim or "not in brief"> | <spec frontmatter node_count or "-"> | <skill graph.json total_nodes or "-"> | <final design_blueprint value> | <which IC-04 level won> |
| total_edges | ... | ... | ... | ... | ... |
| max_wave_index | ... | ... | ... | ... | ... |
| spawn_node_count | ... | ... | ... | ... | ... |
| max_concurrent_spawns_per_run | ... | ... | ... | ... | ... |
| topology | ... | ... | ... | ... | ... |
| HC-02_compliance | ... | ... | ... | ... | ... |
```

Rules:
- Cells where `resolved` differs from `spec value` or `skill value` are flagged with ⚠️.
- The flagged rows are the candidate REVIEW-GATE-W5 prompt (surfaced at STEP 5b when `--review-gates` is set).
- When `--review-gates` is NOT set: write the diff to `stages/metadata-diff.md` for audit trail; pipeline continues per IC-04 precedence.
- When all resolved values match all source values: no flags; emit "✓ no metadata conflicts detected".

**This diff is always emitted when at least one of {--context, --context-spec} was given.** When only a brief is supplied (ec-brief/ec-refeed/ec-inject): emit the `metadata_diff` table with spec/skill columns as "-" and resolved as the design_blueprint values.

7. **Write output** to `stages/N-AGG-DESIGN.md`. Emit signals: `design_blueprint`, `contradiction_resolutions`.

## Scale gates
- tokens: 8000
- time: 600s
- spawns: 2
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit minimal design_blueprint (EC2 minimum: 5 nodes, 4 waves)
- malformed output: re-emit step 6 structure only
- missing input: HALT with name of missing signal
- format-mismatch on Edge: re-read stage files directly by path

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-AGG-DESIGN
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
