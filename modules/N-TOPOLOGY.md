---
node_id: N-TOPOLOGY
node_type: ANALYZER
hat: analyzer
exec_type: spawn
tier: model-medium
scale_gates: {token_budget: 2000, time_budget: 120, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: normalize_result
    format: markdown
    signal_field: normalize_digest
    required: true
output_ports:
  - port: topology_result
    format: markdown
    signal_field: topology_digest
raises_signals: [topology_digest, conflict_signals]
required_output_sections: [topology_class, wave_count_estimate, topology_digest]
---

## INPUT ports
- normalize_result: markdown  (signal_field: normalize_digest)

## OUTPUT ports
- topology_result: markdown  (signal_field: topology_digest)

## AI advantages exploited
- topology_aware_reasoning  # explicit traversal of H.3 decision tree without skipping branches

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-TOPOLOGY: briefing-core + briefing-appendix-topology. -->

0.5. **Validation-mode check (HC-17).** Check whether `stages/validation-mode.md` exists.
   - If absent: proceed normally; emit only `topology_digest`.
   - If present: read its single-line content. Set `validation_mode=true`. Read `stages/N-CONTEXT-ANALYZE.md` to access the context-claimed topology. Run as a validation branch:
     a. Compute the H.3 decision-tree-derived topology (steps 1-4 below).
     b. Compare against the context-claimed topology.
     c. For every disagreement, emit a `conflict_signal` record: `{element: <topology-element>, context_claim: <X>, derived: <Y>, severity: <minor|major|blocker>, rationale: <why-they-differ>}`.
     d. Emit BOTH `topology_digest` (the H.3-derived value) AND a `conflict_signals` array.

1. **Read inputs.** Read `stages/N-NORMALIZE.md`. Extract `latency_tolerance` and `constraint_count`. Also read `stages/N-CONTEXT-ANALYZE.md` if it exists; extract `pipeline_class` (optional input — may be absent for ec-brief inputs).

1.5. **Spawn invocation note.** N-TOPOLOGY now executes as `exec_type: spawn` per DD-08. The orchestrator dispatches this node via the standard subagent spawn invocation (see SKILL.md STEP 3 for the Agent() prompt template); the subagent reads briefing-core.md + briefing-appendix-topology.md declared above, then proceeds with steps 2-5. retry_budget is 1; on retry the orchestrator re-spawns.

2. **Determine H.3 topology features.** Evaluate these four boolean features from the normalize_digest:
   - `fan_out_branches`: count of independent reasoning paths identified in normalize_digest (default ≥2 for any non-trivial input)
   - `refinement_loops_needed`: true if success_criteria mentions "revision", "iteration", "self-check", or "refine"
   - `cross_branch_convergence`: true if output_shape requires synthesis of multiple perspectives (typically true for any non-trivial skill)
   - `scale_tier`: map latency_tolerance → MINIMAL|STANDARD|DEEP

   **Pipeline-class override (AMENDED v4.2).** When `pipeline_class` is present:
   - `linear-pipeline`: treat `fan_out_branches` as the count of **inter-mode** branches for the top-level topology evaluation. Set `cross_branch_convergence = false` at the inter-mode level unless the pipeline explicitly merges mode branches into a shared output.
     **Additionally evaluate intra-mode fan-out separately:** for each mode, count the maximum number of parallel processing nodes that feed into a single downstream aggregation node (`intra_mode_max_fan_out`). If `intra_mode_max_fan_out ≥ 2` AND those nodes share a single downstream aggregation node: set `cross_branch_convergence = true` and annotate `intra_mode_got = true` in the topology_digest. The H.3 classification uses the intra-mode convergence result (not the inter-mode result) for the `cross_branch_convergence` branch of the decision tree. This prevents ToT misclassification for linear-pipeline skills that contain GoT fan-out+aggregation patterns within individual modes.
   - `graph-native`: use standard H.3 traversal.
   - `state-machine` or `hybrid`: treat as `graph-native` with additional state-transition edges.

3. **Apply H.3 decision tree.** Traverse in order:
   ```
   IF fan_out_branches <= 1 AND NOT refinement_loops_needed AND NOT cross_branch_convergence:
       topology = "Chain-of-Thought (CoT)"
   ELIF fan_out_branches > 1 AND NOT cross_branch_convergence:
       topology = "Tree-of-Thought (ToT)"
   ELIF cross_branch_convergence AND NOT refinement_loops_needed:
       topology = "Graph-of-Thought (basic GoT)"
   ELIF cross_branch_convergence AND refinement_loops_needed:
       topology = "Graph-of-Thought with bounded back-edges (full GoT)"
   ELIF scale_tier in {STANDARD, DEEP} AND fan_out_branches >= 3:
       topology = "Wave-Modular GoT"
   ```
   Note: if all four conditions in the final NOTE are true, annotate "topology: full GoT + Wave-modular."

4. **Estimate Wave count.** Based on topology class:
   - CoT: 3–5 Waves
   - ToT: 4–7 Waves
   - GoT basic: 5–8 Waves
   - GoT full: 6–9 Waves (back-edges add micro-Waves)
   - Wave-Modular: 7–10 Waves
   If estimate > 10: flag `wave_count_warning=true` for N-AGG-DESIGN.

5. **Write topology_digest.** Write to `stages/N-TOPOLOGY.md`:
   ```
   ## topology_class
   <class name>

   ## wave_count_estimate
   <N–M Waves>

   ## features
   fan_out_branches: <N>
   refinement_loops_needed: <true|false>
   cross_branch_convergence: <true|false>
   scale_tier: <MINIMAL|STANDARD|DEEP>

   ## topology_digest
   topology: <class>
   wave_range: <N-M>
   wave_count_warning: <true|false>
   ```
   Emit signal: `topology_digest`. When `validation_mode=true`, also emit `conflict_signals` array in the output.

## Scale gates
- tokens: 2000
- time: 120s
- spawns: 0
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit topology_digest with topology=GoT-basic (safe default)
- malformed output: re-run step 5 only
- missing input: HALT "N-TOPOLOGY: normalize_result missing"
- format-mismatch on Edge: re-read stages/N-NORMALIZE.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-TOPOLOGY
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
