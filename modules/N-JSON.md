---
node_id: N-JSON
node_type: FORMATTER
hat: formatter
exec_type: inline
tier: model-small
scale_gates: {token_budget: 3000, time_budget: 300, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: graph_spec
    format: markdown
    signal_field: graph_spec
    required: true
output_ports:
  - port: json_result
    format: markdown
    signal_field: json_result
raises_signals: [json_result]
required_output_sections: [graph_json_content, hats_json_content]
---

## INPUT ports
- graph_spec: markdown  (signal_field: graph_spec)

## OUTPUT ports
- json_result: markdown  (signal_field: json_result)

## AI advantages exploited
- consistency_at_scale  # serialize full topology to JSON without structural errors

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-JSON: briefing-core only. No appendices required. -->

1. **Read graph_spec** from `stages/N-SYNTH-GRAPH.md`. Extract Node Registry and Edge Table. Also read `stages/N-CONTEXT-ANALYZE.md` if it exists (for context_source injection in step 1.5).

1.5. **Pre-emission field checklist (mandatory before JSON assembly).**

**For graph_json_content:**

(a) **V16 enforcement.** For every planned node with `exec_type=inline` and `hat≠formatter`: assert `token_budget ≤ 4000`. For `hat=formatter`: assert `token_budget ≤ 16000`. If any node violates the ceiling, choose:
   - PREFERRED: Convert to `exec_type=spawn` when the budget reflects genuine context need (the task requires large working memory).
   - FALLBACK: Reduce `token_budget` to the ceiling value.
   Log each reduction or promotion as `"v16_resolution": "inline-ceiling|spawn-promotion"` on the node entry. This prevents V16 failures at N-VERIFY without consuming the repair budget.

(b) **context_source injection.** When `CONTEXT_PATH` or `CONTEXT_SPEC_PATH` is non-empty (ec-skill / ec-spec / ec-both run): read `stages/N-CONTEXT-ANALYZE.md`. Parse its `classification_table`. For every node in the node list, inject two fields:
   - `"context_source"`: one of `preserved | upgraded | replaced | new` — from the matching classification_table row.
   - `"context_rationale"`: one-sentence rationale — from the matching row.
   If a node has no matching row in the table: inject `"context_source": "new"` and `"context_rationale": "GoT structural addition; no linear-pipeline equivalent."` ec-brief / ec-refeed runs: skip this step (leave both fields absent).

(c) **join_policy check.** For every node with `type=AGGREGATION`: `join_policy` MUST be non-null. Derive from `aggregation_policy` text (`AND-join` → `"AND"`, `OR-join` → `"OR"`). If `aggregation_policy` is null on an AGGREGATION-typed node: HALT with `"N-JSON: AGGREGATION node <id> has null join_policy — fix in N-AGG-DESIGN"`.

**For hats_json_content:**

(d) **downshift_threshold injection.** For every hat entry with `downshiftable: true`: ensure `downshift_threshold` (float, 0.0–1.0) is present. Apply defaults when absent: `0.20` for all hats; `0.30` for the `verifier` hat (per DD-08). Do NOT add `downshift_threshold` to non-downshiftable hats.

(e) **Schema normalization.** Every hat entry in the generated `hats.json` MUST include these fields in order: `hat_id`, `description`, `tier`, `fallback_tier`, `downshiftable`, `downshift_threshold` (when downshiftable), `nodes`, `exec_types_allowed`, `capabilities_required`, `capabilities_excluded`. The field name is `fallback_tier` (not `fallback`). The hats array is a JSON array (not a dict keyed by hat_id) so that downstream parsers can iterate without key-mapping.

2. **Serialize graph.json.** Produce a JSON document with required top-level keys `nodes`, `edges`, `metadata`:
   ```json
   {
     "metadata": {
       "skill_name": "<name from normalize_digest>",
       "version": "1.0.0",
       "determinism_class": "non-deterministic",
       "total_waves": <N>,
       "topology": "<topology class>",
       "sinks": ["REFUSE_OUTPUT", "... + any mode-conditional terminal sinks like SPEC_OUTPUT, SKILL_OUTPUT"]
     },
     "nodes": [
       {
         "id": "<stage_id>",
         "type": "<H.1 type>",
         "exec_type": "<inline|spawn>",
         "hat": "<hat>",
         "tier": "<model-large|medium|small>",
         "context_budget_lines": <N>,
         "scale_gates": {"token_budget": N, "time_budget": N, "spawn_budget": N, "retry_budget": N},
         "input_dependencies": ["<edge_id_or_node_id>"],
         "required_output_sections": ["<section>"],
         "raises_signals": ["<signal>"],
         "ai_advantages_exploited": ["<catalogue_key>"],
         "super_human_unlocks": ["<description>"],
         "halt_conditions": ["<halt-timing-condition>"],
         "aggregation_policy": "<policy or null>",
         "sub_artifacts": []
       }
     ],
     "edges": [
       {
         "id": "<edge_id>",
         "source": "<node_id>",
         "target": "<node_id>",
         "edge_type": "<H.2 type>",
         "signal_field": "<field>",
         "scale_gates": [0,0,0,0],
         "gate_condition": "<expression or null>"
       }
     ]
   }
   ```

3. **Validate JSON.** The produced JSON must parse without error. Check:
   - Every node `id` matches a stage ID in the Node Registry
   - Every edge `id` is unique
   - Every edge `source` and `target` references a valid node_id (or `skill_concept_brief` for E1)
   - `metadata.determinism_class` is one of `deterministic|seeded|non-deterministic`

4. **Serialize hats.json.** Produce hats.json using the hats.json schema from hats.json template. Map every hat used by a node in the registry.

5. **Write output** to `stages/N-JSON.md` containing both JSON blocks (as triple-backtick json code blocks). Emit signal: `json_result`.

## Scale gates
- tokens: 3000
- time: 300s
- spawns: 0
- retries: 1

## Failure modes
- timeout: retry; emit partial JSON with a comment "// INCOMPLETE" at truncation point
- malformed output: re-run step 5 only
- missing input: HALT "N-JSON: graph_spec missing"
- format-mismatch on Edge: re-read stages/N-SYNTH-GRAPH.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-JSON
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
