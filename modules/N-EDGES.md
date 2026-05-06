---
node_id: N-EDGES
node_type: GENERATOR
hat: generator
exec_type: spawn
tier: model-large
scale_gates: {token_budget: 5000, time_budget: 480, spawn_budget: 2, retry_budget: 1}
input_ports:
  - port: design_blueprint
    format: markdown
    signal_field: design_blueprint
    required: true
    source: N-DESIGN-GATE.md  # passthrough from N-AGG-DESIGN via Wave-5 gate
output_ports:
  - port: edges_result
    format: markdown
    signal_field: edges_result
raises_signals: [edges_result]
required_output_sections: [edge_table, conditional_edge_signals]
---

## INPUT ports
- design_blueprint: markdown (signal_field: design_blueprint, source: stages/N-DESIGN-GATE.md passthrough — see N-DESIGN-GATE step 5b)

## OUTPUT ports
- edges_result: markdown  (signal_field: edges_result)

## AI advantages exploited
- consistency_at_scale      # apply H.2 closed vocabulary to every edge without exception
- topology_aware_reasoning  # trace entire graph topology when assigning edge types

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-EDGES: briefing-core only. No appendices required. -->

0.5. **v12_v5_early_check (V5+V12 pre-shifted from N-VERIFY per DD-04).** As the edge table is generated, simultaneously perform two early checks before emitting:
   - **V5 early check:** at least one edge declared with `edge_type=forward-conditional` AND a non-empty `gate_condition` expression. If absent: HALT with `halt-on-no-conditional-edge` and re-route to N-AGG-DESIGN via remediation payload — the design lacks any branching point that warrants a conditional edge.
   - **V12 early check:** the produced edge table MUST be syntactically valid markdown — every row has the same column count as the header. If any row's column count differs: HALT with `halt-on-edge-table-malformed` and re-emit step 2 only.
   These checks shift V5/V12 partial responsibility upstream so N-VERIFY's residual battery only does final gate confirmation rather than primary discovery.

1. **Read design_blueprint** from `stages/N-DESIGN-GATE.md` (the passthrough section appended by N-DESIGN-GATE step 5b — the blueprint is forwarded unchanged after gate evaluation; the gate_pass field at the top of N-DESIGN-GATE.md is the gate verdict, the design_blueprint passthrough section below is the data payload). Extract Branching Points and Aggregation Points.

2. **Generate Section 2 — PIPELINE GRAPH (Edge Table).** For every directed connection between nodes, produce a row:
   `edge ID | edge_type | source Node.OUTPUT port | destination Node.INPUT port | signal_field | scale_gates [token,time,spawn,retry] | conditional? (signal class + condition) | Join semantics at destination`

   H.2 closed edge_type vocabulary (MUST use verbatim):
   - `required`: Node B's input_dependencies lists A's signal_field; pipeline halts if missing
   - `optional`: B can consume A's signal if present; if absent, B proceeds with default
   - `gate-open`: unconditionally resolved at ready-set compute (no gate_condition)
   - `forward-conditional`: fires forward only when gate_condition evaluates true
   - `back-edge`: re-enqueues an earlier node; capped at 1 firing default
   - `terminal`: final-node edge to output artifact

   Rules:
   - Fan-out edges (one source → multiple targets): all are `gate-open` unless the fan-out is conditional.
   - Aggregation input edges (multiple sources → one target): all are `required`.
   - Repair edges: `back-edge` with explicit gate_condition `verify_pass == false AND retry_count < 1`.
   - At least one `forward-conditional` edge must exist (V5 requirement).

2.5. **Post-generation structural integrity checks (mandatory before emitting edges_result).**

   Run ALL four checks after step 2 edge generation is complete:

   **(A) INGEST outgoing edge enforcement (P-2 / FD-1 fix).** For every node in the registry with `type=INGEST`: verify it has at least one outgoing edge in the generated edge table. If any INGEST node has zero outgoing edges:
   - Identify the immediately downstream processor (typically the ROUTER or first CLASSIFIER node, whichever directly receives the structured input record).
   - Generate a `gate-open` edge: `{source: <INGEST_node_id>, target: <downstream_node_id>, edge_type: "gate-open", signal_field: "ingest_record"}`.
   - Add it to the edge table before emitting.
   - Log: `"ingest_edge_auto_generated": "<INGEST_node_id> → <downstream_node_id>"`.
   This check is non-optional. An INGEST node with no outgoing edges disconnects the graph topology at its entry point.

   **(B) ingest_record forwarding to spawn nodes (P-3 / FD-3 fix / AP-V29 guard).** For every spawn node (`exec_type=spawn`) whose declared input_ports include `ingest_record`:
   - Verify the edge table contains an incoming edge with `signal_field: "ingest_record"` targeting that spawn node.
   - If absent: generate a `required` edge from the INGEST node: `{source: <INGEST_node_id>, target: <spawn_node_id>, edge_type: "required", signal_field: "ingest_record"}`.
   - Add it to the edge table and log: `"ingest_record_edge_auto_generated": "<spawn_node_id>"`.
   This ensures that spawned agents executing in isolated contexts receive the raw user input via a declared graph edge, eliminating the AP-V29 hidden runtime dependency.

   **(C) Mode-conditional XOR join annotation (P-4 / FD-2 fix).** When a FILTER or FORMATTER node has two incoming edges where only one is ever live per execution mode (i.e., one is `forward-conditional` on a mode flag and the other is `gate-open` from a non-deep path):
   - Add a `join_hint` field to each of the two edges: `"join_hint": "mode-XOR: exactly one path active per execution"`.
   - Add a `join_hint` field to the target node entry in the edge table commentary: `"join_semantics at target: XOR-conditional (mode-gated; not AND-join)"`.
   This prevents AND-join misinterpretation by any executor reading input_dependencies as a strict AND-join requirement.

   **(D) --minimal flag representation (P-7 / FD-4 fix / AP-V29 guard).** If the design_blueprint specifies a `--minimal` flag mode that reduces spawn budgets or triggers tier downshifts:
   - Generate a `forward-conditional` edge from the ROUTER node to each node affected by --minimal, carrying a `flag_minimal` signal with `gate_condition: "flags.minimal == true"`.
   - Alternatively, if the design uses a dedicated MINIMAL_GATE node: generate `gate-open` edges from that node to downstream affected nodes.
   - If --minimal affects only internal node behavior (no topology change): add a `mode_gate_annotation` comment in the edge table: `"# --minimal: internal tier-downshift only; no structural edges changed. See §3 Mode Matrix for downshift policy."` This makes the mode's handling visible in the edge table rather than silently relying on implicit node-internal behavior.

3. **Document conditional edge signals.** List each forward-conditional and back-edge with:
   - signal class (node-emitted / controller-state / invocation-flag / failure-class)
   - exact condition expression
   Also document any XOR join hints added in step 2.5(C) and any --minimal annotations added in step 2.5(D).

4. **Write output** to `stages/N-EDGES.md`. Emit signal: `edges_result`.

## Scale gates
- tokens: 5000
- time: 480s
- spawns: 2
- retries: 1

## Failure modes
- timeout: retry once; emit partial edge table with available edges flagged
- malformed output: re-emit the table only
- missing input: HALT "N-EDGES: design_blueprint missing"
- format-mismatch on Edge: re-read stages/N-DESIGN-GATE.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-EDGES
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
