---
node_id: N-DESIGN-GATE
node_type: GATE
hat: gate
exec_type: inline
tier: model-medium
scale_gates: {token_budget: 2000, time_budget: 120, spawn_budget: 0, retry_budget: 0}
input_ports:
  - port: design_blueprint
    format: markdown
    signal_field: design_blueprint
    required: true
output_ports:
  - port: gate_pass
    format: bool
    signal_field: gate_pass
  - port: gate_diagnostic
    format: markdown
    signal_field: gate_diagnostic
  - port: design_blueprint
    format: markdown
    signal_field: design_blueprint
    note: "passthrough — copies design_blueprint forward to Wave 6 to satisfy HC-21 inter-node edge-coverage; the gate evaluates the blueprint but does not transform it"
raises_signals: [gate_pass, gate_diagnostic, design_blueprint]
required_output_sections: [hc08_evaluation, hc09_evaluation, gate_pass, gate_diagnostic, design_blueprint_passthrough]
---

## INPUT ports
- design_blueprint: markdown (signal_field: design_blueprint)

## OUTPUT ports
- gate_pass: bool (signal_field: gate_pass)
- gate_diagnostic: markdown (signal_field: gate_diagnostic)
- design_blueprint: markdown (signal_field: design_blueprint, **passthrough** — N-DESIGN-GATE forwards the blueprint unchanged so Wave 6 nodes can declare `input_dependencies: ["N-DESIGN-GATE"]` and read everything they need from a single stage file. Required to satisfy HC-21 inter-node edge-coverage smoke test #10.)

## AI advantages exploited
- topology_aware_reasoning   # cycle / dependency analysis on the produced graph
- consistency_at_scale       # apply HC-08 criteria to every blueprint without omission

## Review-gate hop note
When `--review-gates` is set, after gate_pass=true, the orchestrator pauses and surfaces the design_blueprint for user approval before Wave 6 begins.

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-DESIGN-GATE: briefing-core + briefing-appendix-contract. -->

1. **Read design_blueprint** from `stages/N-AGG-DESIGN.md`. Extract: Topology class, total Waves, Node List, Branching Points, Aggregation Points, Constraints Preserved, AI Advantages Assigned.

2. **Evaluate HC-08 criteria (always required).** For each:
   - **HC-08-a:** >=1 mid-graph aggregation present? Count Aggregation Points where `mid_graph: true`. PASS if count >=1.
   - **HC-08-b:** Wave count <=10? PASS if total_waves <= 10.
   - **HC-08-c:** No irresolvable contradictions? Read `contradiction_resolutions` from design_blueprint. PASS if every contradiction has a confirm/modify/override resolution; FAIL if any are unresolved.
   - **HC-08-d (structural self-consistency):** PASS if ALL of:
     - No cycles among non-repair edges (use directed-graph cycle detection on the Node List + Edge Table from design_blueprint, excluding edges typed `back-edge`).
     - All declared `input_dependencies` reference valid node IDs present in the Node Registry.
     - Wave ordering consistent: no node assigned a wave number <= any node it depends on (check via topological sort).

3. **Evaluate HC-09 criteria (when context present).** Read `stages/N-CONTEXT-ANALYZE.md` if it exists.
   - **HC-09-a:** Every replace-target has a documented structural defect citing a specific node-field or Hard-Gate violation? PASS if all replace-target rows in design_blueprint Design Decisions cite a defect.
   - **HC-09-b:** No preservation-candidate from context_inventory is silently discarded? PASS if every preservation-candidate node from context appears in the integrated graph_spec OR is explicitly marked replace-target with rationale.

4. **Compute gate_pass.** `gate_pass = HC-08-a AND HC-08-b AND HC-08-c AND HC-08-d AND (no context OR (HC-09-a AND HC-09-b))`.

5. **Build gate_diagnostic.** Always emit, regardless of pass/fail:
   ```markdown
   ## hc08_evaluation
   <table: criterion | result (PASS/FAIL) | observed value | required value>

   ## hc09_evaluation (only when --context)
   <table: criterion | result | observed | required>

   ## gate_pass
   <true | false>

   ## failing_criteria (only when gate_pass=false)
   <bulleted list of failing criteria with specific remediation advice>

   ## remediation_payload (only when gate_pass=false)
   <markdown payload to feed back to N-AGG-DESIGN via E11 RP-01 back-edge>
   ```

5b. **Forward design_blueprint as passthrough (HC-21 / F001 fix).** Append a `## design_blueprint (passthrough)` section to the output. The content is the verbatim Node List + Branching/Aggregation Points + Constraints Preserved + Anti-Patterns Guarded + AI Advantages Assigned tables from `stages/N-AGG-DESIGN.md` design_blueprint section. **Do not mutate the blueprint** — N-DESIGN-GATE only evaluates it; downstream Wave 6 nodes need it intact:
   ```markdown
   ## design_blueprint (passthrough)
   <verbatim copy of the design_blueprint section from stages/N-AGG-DESIGN.md>
   ```
   This passthrough is what allows Wave 6 nodes (N-REGISTRY, N-EDGES, N-WAVES) to declare `input_dependencies: ["N-DESIGN-GATE"]` in graph.json AND read everything they need from `stages/N-DESIGN-GATE.md` alone — satisfying HC-21 inter-node edge-coverage. Without this passthrough, Wave 6 modules would read `stages/N-AGG-DESIGN.md` (a node not declared in their input_dependencies), and the smoke test would fail.

6. **Write output** to `stages/N-DESIGN-GATE.md`. Emit signals `gate_pass`, `gate_diagnostic`, AND `design_blueprint` (the passthrough).

7. **On failure** (`gate_pass=false`): the orchestrator fires E11 RP-01 back-edge to N-AGG-DESIGN with `remediation_payload`. `retry_count_design` is incremented (capped at 1 per HC-12). On second failure: HALT with `halt-on-design-gate-fail` listing the specific failing HC-08/HC-09 criterion.

8. **Review-gate pause hook (when `--review-gates` set).** After step 6 emits `gate_pass=true`: the orchestrator suspends pipeline execution, surfaces the design_blueprint passthrough section to the user, and awaits explicit approval before Wave 6 begins. On user-rejection: the orchestrator re-routes to N-AGG-DESIGN via the E11 back-edge with the user's rejection note as remediation_payload (subject to retry_count_design cap).

## Scale gates
- tokens: 2000
- time: 120s
- spawns: 0 (inline)
- retries: 0 (RP-01 back-edge is the retry mechanism, capped at 1)

## Failure modes
- timeout: emit gate_pass=false with diagnostic "N-DESIGN-GATE timed out; treat as fail" — fires RP-01
- malformed output: re-run step 5 only
- missing input: HALT "N-DESIGN-GATE: design_blueprint missing"
- format-mismatch on Edge: re-read stages/N-AGG-DESIGN.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-DESIGN-GATE
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
