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
   <!-- DD-03 read-map for N-AGG-DESIGN: briefing-core + briefing-appendix-memory + briefing-appendix-antipatterns. -->

1. **Await AND-join.** Confirm all three required stage files exist: `stages/N-TOPOLOGY.md`, `stages/N-DECOMPOSE.md`, `stages/N-CONSTRAINTS.md`. If any missing: HALT with missing signal name. Confirm `stages/N-CONTEXT-ANALYZE.md` optionally — its presence/absence is determined at runtime by orchestrator per HC-19 (do NOT block on its absence).

2. **Read all three required digests AND optional context_inventory.** Extract:
   - From topology: topology_class, wave_range, features, wave_count_warning
   - From decompose: node_types list, branching_points, aggregation_points, total_nodes_estimated
   - From constraints: inventory_items list, anti_patterns_flagged, ai_advantages_selected
   - If `stages/N-CONTEXT-ANALYZE.md` exists: read it; extract the classification table from context_inventory.

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

6. **Build design_blueprint.** Produce a structured specification:
   ```markdown
   ## design_blueprint

   ### Topology
   class: <topology_class>
   total_waves: <N>  (≤10)

   ### Node List
   <table: node_id | H.1 type | hat | exec_type | wave | description>

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

6b. **Design Decisions section (when context_inventory present).** For each preserved/upgraded/replaced node from context_inventory, list:
   - node_id | context_classification | integrated_classification | rationale (one sentence)
   - For replace-target rationales: cite the specific structural defect identified by N-TOPOLOGY or N-DECOMPOSE (AP-15).

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
