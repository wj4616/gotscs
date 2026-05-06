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
output_ports:
  - port: decompose_result
    format: markdown
    signal_field: decompose_digest
raises_signals: [decompose_digest, conflict_signals]
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
