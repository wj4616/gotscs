---
node_id: N-DECOMPOSE
node_type: DECOMPOSITION
hat: analyzer
exec_type: spawn
tier: model-medium
scale_gates: {token_budget: 4000, time_budget: 240, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: normalize_result
    format: markdown
    signal_field: normalize_digest
    required: true
  - port: evolution_mode
    format: signal
    signal_field: evolution_mode
    required: true
  - port: fusion_plan
    format: markdown
    signal_field: fusion_plan
    required: false
output_ports:
  - port: decompose_result
    format: markdown
    signal_field: decompose_digest
  - port: decomposition_tasks
    format: markdown
    signal_field: decomposition_tasks
raises_signals: [decompose_digest]
raises_signals_conditional: [conflict_signals, decomposition_tasks]
required_output_sections: [node_types, branching_points, aggregation_points, decompose_digest]
---

## INPUT ports
- normalize_result: markdown  (signal_field: normalize_digest)

## OUTPUT ports
- decompose_result: markdown  (signal_field: decompose_digest)

## AI advantages exploited
- multi_perspective_simulation   # simultaneously apply all H.1 node type lenses
- topology_aware_reasoning       # reason over graph structure before instantiating nodes

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-DECOMPOSE: briefing-core only. No appendices required. -->

0.5. **Validation-mode check (HC-17).** Check whether `stages/validation-mode.md` exists.
   - If absent: proceed normally; emit only `decompose_digest`.
   - If present: read its single-line content. Set `validation_mode=true`. Read `stages/N-CONTEXT-ANALYZE.md` to access the context-claimed decomposition. Run as a validation branch:
     a. Compute the H.1-typed node decomposition (steps 1-4 below).
     b. Compare against the context-claimed decomposition.
     c. For every disagreement, emit a `conflict_signal` record: `{element: <decomposition-element>, context_claim: <X>, derived: <Y>, severity: <minor|major|blocker>, rationale: <why-they-differ>}`.
     d. Emit BOTH `decompose_digest` (the H.1-derived value) AND a `conflict_signals` array.

1. **Read inputs.** Read `stages/N-NORMALIZE.md`. Focus on domain, input_shape, output_shape, success_criteria, constraints.

1.5. **Spawn invocation note.** N-DECOMPOSE now executes as `exec_type: spawn` per DD-08. The orchestrator dispatches this node via the standard subagent spawn invocation (see SKILL.md STEP 3 for the Agent() prompt template); the subagent reads briefing-core.md, then proceeds with steps 2-5. retry_budget is 1; on retry the orchestrator re-spawns.

2. **Select node types from H.1 closed enum.** For each processing responsibility in the target skill, assign the appropriate H.1 type:
   `DECOMPOSITION | ANALYZE | TAILOR | XREF | LATERAL | DEFIXATION | SIMULATION | PRECISION | ADVERSARIAL | CONJECTURE | AGGREGATION | ROUTER | SYNTHESIS | VERIFIER | ATTACKER | FORMATTER | GENERATOR | EXPANSION | INGEST | CLASSIFIER | GATE | META-ANALYZER | ANALYZER | RECOVERY | FILTER | TRIAGE | PLANNER | PREFLIGHT | ACTUATOR | IO | VALIDATOR | SCORER | PERSISTER | REFINER`
   Rules:
   - EVERY skill needs at minimum: INGEST or PREFLIGHT, at least one analysis type, AGGREGATION, VERIFIER, FORMATTER or PERSISTER.
   - Any skill with "validate" in success_criteria needs VALIDATOR.
   - Any skill with back-edge repair needs RECOVERY.

3. **Identify branching points.** A branching point is where a single node fans out to ≥2 parallel nodes. List each:
   - Source node type + description
   - Fan-out count
   - Nature of parallelism (independent analysis axes, domain-specific lenses, etc.)

4. **Identify aggregation points.** An aggregation point is where ≥2 branches converge. For each:
   - Label as "mid-graph" (not final) or "final" (feeds emit)
   - List incoming branch node types
   - Suggested synthesis strategy (concatenate / weighted-merge / contradiction-resolve / vote / triz-synthesize)
   - Ensure at least one aggregation is mid-graph (NOT the final emit) — this is the V3 requirement

5. **Write decompose_digest.** Write to `stages/N-DECOMPOSE.md`:
   ```
   ## node_types
   <table: responsibility | H.1 type | rationale>

   ## branching_points
   <list: source → [targets], fan-out count, parallelism nature>

   ## aggregation_points
   <list: [sources] → target, mid/final, synthesis strategy>

   ## decompose_digest
   total_nodes_estimated: <N>
   branching_points: <N>
   aggregation_points: <N>
   mid_graph_aggregations: <N>   # must be ≥1
   ```
   Emit signal: `decompose_digest`. When `validation_mode=true`, also emit `conflict_signals` array in the output.

6. **Mode-dependent task decomposition (NEW v4.3 — spec §3.6).** Read `evolution_mode` from `stages/N-PREFLIGHT.md`. Branch:

   **`overlay` and `greenfield` modes:** terminate after step 5. Legacy decompose_digest IS the authoritative output. This branch is byte-identical to v4.2.0.

   **`evolve` and `evolve-aggressive` modes:** read `stages/N-FUSION-ANALYZE.md` (must exist; HALT with `halt-fusion-prereq-missing` if absent). Read its `unified_topology`, `preservation_map`, `divergence_map`, and `inheritance_map` sections.

   For every node / edge / aggregation carrier in the `unified_topology`, derive ONE task from the closed-vocab 8-category taxonomy:

   | Category | Source signal in fusion_plan | Description |
   |---|---|---|
   | `preserve` | `preservation_map` entry; origin="preserved" | Keep original node/edge/INVENTORY item byte-identical. No code change required; verify byte-equality at V-battery. |
   | `upgrade` | `divergence_map` entry; origin="upgraded"; node_id preserved | Modify existing node in place — preserve node_id, port contracts, hat/tier, but change Protocol or scale_gates. |
   | `replace` | `divergence_map` entry; origin="replaced"; node_id changes | Drop original node; implement new design with same external contract (FC-07). regression_risk MUST be set. |
   | `merge` | `divergence_map` entry; origin="merged"; multiple original ids → one new id | Combine multiple original nodes into a single superior node. Preserve union of external contracts. |
   | `add` | `divergence_map` entry; origin="added"; not in original | Net-new node from spec or brief. No predecessor; pure addition. |
   | `remove` | `divergence_map` entry; origin="removed"; in original but not unified_topology | Drop original node. regression_risk MUST be set. Downstream consumers of the dropped node must already be re-routed in unified_topology. |
   | `resequence` | `divergence_map` entry; origin="resequenced"; same node_id, different wave | Move node to a different wave without changing its Protocol. May require edge gate updates. |
   | `recontract` | `divergence_map` entry; origin="recontracted"; same node_id, changed aggregation_policy / join_policy / port contract | Change the aggregation contract or port shape without renaming. Most fragile category — V-battery flags any recontract that breaks adjacency. |

   For each derived task, emit one row of `decomposition_tasks[]`:
   ```json
   {
     "task_id": "DT-<NN>",
     "category": "preserve | upgrade | replace | merge | add | remove | resequence | recontract",
     "target_item_id": "<node_id | edge_id | INVENTORY-id>",
     "origin_node_ids": ["<original_id>", ...],   // [] for category=add; [<id>] for most; [<id1>,<id2>] for merge
     "authority": "P1 brief | P2 spec | P3 original | P4 default",
     "rationale_excerpt": "<≤200-char excerpt from fusion_plan divergence_rationale>",
     "regression_risk": "low | medium | high",  // required for category in {replace, remove, recontract}; null otherwise
     "external_contract_locked": <bool>,  // true if FC-04 forced preserve despite brief silence
     "wave_target": <int>  // resolved wave number from unified_topology
   }
   ```

   **Atomicity rule.** Every concrete item in `unified_topology` that maps to a graph element MUST yield exactly one task; no item may be missing, duplicated, or fall outside the 8 categories. Define the countable target precisely:
   ```
   countable_topology = unified_topology.nodes_proposed
                      ∪ unified_topology.edges_proposed
                      ∪ unified_topology.aggregation_carriers_proposed
   ```
   `waves_proposed` (numeric wave indices) and `inventory_proposed` (HC/AP/INV identifiers) are NOT individually decomposed into DT-NN tasks — they are by-products of node-level resequence and recontract decisions, and tracked in fusion_plan.preservation_map / divergence_map directly.

   Compute the count assertion against `countable_topology`:
   ```
   |preserve| + |upgrade| + |replace| + |merge| + |add| + |remove| + |resequence| + |recontract|
       == |countable_topology|
   ```
   For `merge` tasks: the task counts as 1 row but its `origin_node_ids` lists multiple originals; the originals are NOT separately tasked (they're absorbed into the merge). So the LHS counts merged-into-one as 1, and the RHS counts the new merged item as 1 (the originals don't appear in countable_topology unless retained as separate items).

   If not equal: HALT with `halt-decompose-task-arithmetic-fail` listing the discrepancy (which countable_topology items are unaccounted for OR over-counted).

   Append to `stages/N-DECOMPOSE.md` two additional sections:
   ```markdown
   ## decomposition_tasks
   <numbered table of DT-NN rows per the schema above>

   ## task_category_summary
   preserve: <N>
   upgrade: <N>
   replace: <N>
   merge: <N>
   add: <N>
   remove: <N>
   resequence: <N>
   recontract: <N>
   total: <sum, must equal |unified_topology|>
   ```

   Emit signal `decomposition_tasks=present`. The legacy `decompose_digest` is still emitted (overlay-mode parity).

## Scale gates
- tokens: 4000
- time: 240s
- spawns: 0
- retries: 1

## Failure modes
- timeout: retry once; emit decompose_digest with minimum-viable graph (5 nodes: INGEST + 2 ANALYZE + AGGREGATION + VERIFIER)
- malformed output: re-run step 5 only
- missing input: HALT "N-DECOMPOSE: normalize_result missing"
- format-mismatch on Edge: re-read stages/N-NORMALIZE.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-DECOMPOSE
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
