---
node_id: N-SYNTH-GRAPH
node_type: SYNTHESIS
hat: aggregator
exec_type: spawn
tier: model-large
scale_gates: {token_budget: 8000, time_budget: 480, spawn_budget: 2, retry_budget: 1}
aggregation_policy: "weighted-merge + cross-table ID consistency check; AND-join; branch_budget_cap=3"
join_policy: AND
input_ports:
  - port: registry_result
    format: markdown
    signal_field: registry_result
    required: true
  - port: edges_result
    format: markdown
    signal_field: edges_result
    required: true
  - port: waves_result
    format: markdown
    signal_field: waves_result
    required: true
output_ports:
  - port: graph_spec
    format: markdown
    signal_field: graph_spec
join_semantics: AND
raises_signals: [graph_spec]
required_output_sections: [graph_spec, consistency_checks_passed, pruned_nodes]
---

## INPUT ports
- registry_result: markdown  (signal_field: registry_result, AND-join)
- edges_result: markdown  (signal_field: edges_result, AND-join)
- waves_result: markdown  (signal_field: waves_result, AND-join)

## OUTPUT ports
- graph_spec: markdown  (signal_field: graph_spec)

## AI advantages exploited
- full_corpus_retention            # hold all three tables in context simultaneously
- cross_document_pattern_recognition  # detect cross-table ID mismatches, missing edges
- consistency_at_scale             # apply consistency checks to every row in every table

## AGGREGATION POLICY (V9 — verbatim) — type=SYNTHESIS (artifact-synthesis); see HC-16/SD-03 for type discriminator vs N-AGG-DESIGN
> "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."

- Decomposition tree: N-REGISTRY → registry_result, N-EDGES → edges_result, N-WAVES → waves_result
- Synthesis strategy: weighted-merge + cross-table ID consistency check
- Join semantics: AND (wait for all three)
- Activation condition: all three signals present
- Branch-budget cap: 3

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-SYNTH-GRAPH: briefing-core + briefing-appendix-memory. -->

1. **Await AND-join.** Confirm all three stage files exist: `stages/N-REGISTRY.md`, `stages/N-EDGES.md`, `stages/N-WAVES.md`.

2. **Cross-table consistency checks.**
   - **Check C1 (ID consistency):** every node_id in the Edge Table must match a stage ID in the Node Registry.
   - **Check C2 (module file consistency):** every Module file referenced in Node Registry must follow pattern `modules/<stage_id>.md`.
   - **Check C3 (Join semantics agreement):** every edge targeting an aggregation node must declare the same Join semantics as the aggregation node's registry row.
   - **Check C4 (Wave assignment consistency):** aggregation nodes must be in a Wave strictly downstream of all their source nodes' Waves.
   - **Check C5 (spawn budget arithmetic):** per-Wave spawn budgets in Wave Plan must equal sum of node spawn_budgets for that Wave.
   - **Check C6 (conditional edge signal fields):** every forward-conditional edge must reference a signal that a source node declares in raises_signals.
   - **Check C7 (edge density advisory) (NEW v4.1):** compute `density = edge_count / node_count`. Warn if:
     - ToT topology: density < 3.0
     - GoT topology: density < 5.0
     Flag as advisory in `consistency_checks_passed` section. Does NOT block synthesis.

3. **Contradiction resolve.** For any failed check: resolve by treating the Node Registry as authoritative (per source-of-truth rule). Document each resolution in `contradiction_resolutions`.

4. **Build graph_spec.** Assemble unified specification combining corrected versions of all three tables plus:
   - Pipeline ASCII diagram (per <output_format> item 1 format spec: nodes as `[NodeName]`, aggregation nodes as `((AggregatorName))`, unconditional edges as `-->`, conditional edges as `--[signal_class:condition]-->`)
   - Section 5 — Optimizations list
   - Section 5.5 — Failure Modes table
   - Section 6 — GoT Controller pseudocode
   - Section 7 — Pipeline Narrative: a prose walkthrough of the pipeline (3–6 paragraphs, one per major Wave group). Describe what each Wave computes, why that ordering is necessary, and how the mid-graph aggregation differs from the final aggregation. This narrative is written for a developer reading the skill for the first time.

5. **Prune unconnected nodes (NEW v4.1).** After consistency checks, scan the Node Registry for any node with zero incoming edges AND zero outgoing edges in the corrected Edge Table. Remove such nodes from the registry. Emit a `pruned_nodes` list (node IDs + removal rationale) in the output frontmatter. If no nodes are pruned, emit `pruned_nodes: []`.

6. **Write output** to `stages/N-SYNTH-GRAPH.md`. Emit signal: `graph_spec`.

## Scale gates
- tokens: 8000
- time: 480s
- spawns: 2
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit graph_spec with all checks flagged ADVISORY
- malformed output: re-run consistency checks only (step 2–3); re-use existing tables
- missing input: HALT with name of missing signal
- format-mismatch on Edge: re-read stage files directly by path

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-SYNTH-GRAPH
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
