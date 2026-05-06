---
node_id: N-REGISTRY
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
  - port: registry_result
    format: markdown
    signal_field: registry_result
raises_signals: [registry_result]
required_output_sections: [node_registry_table, aggregation_policies]
---

## INPUT ports
- design_blueprint: markdown (signal_field: design_blueprint, source: stages/N-DESIGN-GATE.md passthrough — see N-DESIGN-GATE step 5b)

## OUTPUT ports
- registry_result: markdown  (signal_field: registry_result)

## AI advantages exploited
- consistency_at_scale   # apply H.1 schema to every node without field omission
- full_corpus_retention  # hold all node descriptions simultaneously

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-REGISTRY: briefing-core only. No appendices required. -->

0.5. **v13d_early_check (V13(d) pre-shifted from N-VERIFY per DD-04).** As the registry table is generated, simultaneously verify that the node IDs to be emitted will match the IDs in `stages/N-EDGES.md` and `graph.json` (Section 1/2 cross-table identity). Because N-EDGES has not yet emitted at this point in Wave 6, this check is a forward-promise: record each node_id in a `registry_id_set` array within the output frontmatter. The consumer (N-SYNTH-GRAPH cross-table check C1) compares this array to the edges' source/target IDs and N-VERIFY's residual V13(a,b,c,e) check trusts this early-shift. Any duplicate or empty node_id detected here MUST HALT immediately with `halt-on-registry-id-collision`.

1. **Read design_blueprint** from `stages/N-DESIGN-GATE.md` (the passthrough section appended by N-DESIGN-GATE step 5b — the blueprint is forwarded unchanged after gate evaluation; the gate_pass field at the top of N-DESIGN-GATE.md is the gate verdict, the design_blueprint passthrough section below is the data payload). Extract the Node List table.

2. **Generate Section 1 — Node Registry table.** For every node in the Node List, produce a row with ALL required columns:
   `stage ID | Hat | Tier (from hats.json[Hat]) | Module file (modules/<ID>.md) | INPUT ports (<port_name>:<format>) | OUTPUT ports (<port_name>:<format>) | Join semantics (AND/XOR/N/A) | scale gates (token/time/spawn/retry) | ai_advantages_exploited | spawn_share | one-line PROTOCOL`

   Rules:
   - Hat must come from the closed hat vocabulary in graph.schema.json (gate, extractor, analyzer, aggregator, generator, formatter, verifier, persister, no-llm, tailor, expander, lateral, filter, validator).
   - Module file: `modules/<node_id>.md`
   - Join semantics: AND for all aggregation nodes; N/A for all others.
   - ai_advantages_exploited: at least 1 entry from H.7 catalogue per node; ≥3 distinct entries across all nodes.
   - spawn_share: blank = equal-split default. Override only if node needs 2× the share.

3. **Generate Section 1.5 — Aggregation Policies.** For each aggregation node:
   Include verbatim: "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."
   Then: decomposition tree, synthesis strategy, Join semantics, activation condition, branch-budget cap.

4. **Write output** to `stages/N-REGISTRY.md`. Emit signal: `registry_result`.

## Scale gates
- tokens: 5000
- time: 480s
- spawns: 2
- retries: 1

## Failure modes
- timeout: retry once; emit registry with available nodes, flag remaining as TODO (AP-V1 risk — document)
- malformed output: re-emit the table only
- missing input: HALT "N-REGISTRY: design_blueprint missing"
- format-mismatch on Edge: re-read stages/N-DESIGN-GATE.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-REGISTRY
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
