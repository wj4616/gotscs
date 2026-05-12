---
node_id: N-JSON
node_type: FORMATTER
hat: formatter
exec_type: inline
exec_type_conditional: "spawn when produced_node_count > 12 OR produced_edge_count > 20 OR estimated_combined_json_size_kb > 20; else inline (G-02 fix)"
tier: model-small
scale_gates: {token_budget: 3000, time_budget: 300, spawn_budget: 0, retry_budget: 1}
scale_gates_conditional: {when: "exec_type=spawn", token_budget: 8000, time_budget: 360, spawn_budget: 1, retry_budget: 1}
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

0.0a. **Exec-type self-evaluation (G-02 fix).** The orchestrator at SKILL.md STEP 9 evaluates the exec_type_conditional gate BEFORE dispatching N-JSON. This step documents the gate for the subagent when spawned.
   - Read `stages/N-SYNTH-GRAPH.md` frontmatter for `node_count`, `edge_count`.
   - Estimate `combined_json_size_kb` ≈ `node_count * 1.8 + edge_count * 0.5 + 5 KB base`.
   - If `node_count > 12 OR edge_count > 20 OR estimated_combined_json_size_kb > 20`: exec_type resolves to **spawn** (scale_gates_conditional applies: 8000 tokens, 360s, spawn_budget=1). Log in stage frontmatter: `exec_type_resolved: spawn`.
   - Else: exec_type stays **inline** (scale_gates: 3000 tokens, 300s). Log: `exec_type_resolved: inline`.
   - Emit in stage frontmatter: `exec_type_resolved: <inline|spawn>`, `estimated_combined_json_size_kb: <N>`.

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-JSON: briefing-core only. No appendices required. -->

1. **Read graph_spec** from `stages/N-SYNTH-GRAPH.md`. Extract Node Registry and Edge Table. Also read `stages/N-CONTEXT-ANALYZE.md` if it exists (for context_source injection in step 1.5).

1.5. **Pre-emission field checklist (mandatory before JSON assembly).**

**For graph_json_content:**

(a) **V16 enforcement.** Apply ALL of the following rules before emitting any node:

   **Inline ceiling check:** For every planned node with `exec_type=inline` and `hat≠formatter`: assert `token_budget ≤ 4000`. For `hat=formatter`: assert `token_budget ≤ 16000`. If any node violates the ceiling, choose:
   - PREFERRED: Convert to `exec_type=spawn` when the budget reflects genuine context need (the task requires large working memory).
   - FALLBACK: Reduce `token_budget` to the ceiling value.
   Log each reduction or promotion as `"v16_resolution": "inline-ceiling|spawn-promotion"` on the node entry.

   **Spawn budget enforcement (mandatory — prevents V16 failure at N-VERIFY):** For EVERY node with `exec_type=spawn`: assert `spawn_budget ≥ 1`. If `spawn_budget` is 0 or absent: set `spawn_budget: 1` immediately before emission. Log as `"v16_resolution": "spawn-budget-enforced"` on the node entry. **This correction is non-optional.** Spawn nodes with `spawn_budget=0` always fail V16 because they have `token_budget ≤ 6000` AND `spawn_budget < 1`. Do not wait for N-VERIFY to catch this — fix it here.

(b) **context_source injection.** When `CONTEXT_PATH` or `CONTEXT_SPEC_PATH` is non-empty (ec-skill / ec-spec / ec-both run): read `stages/N-CONTEXT-ANALYZE.md`. Parse its `classification_table`. For every node in the node list, inject two fields:
   - `"context_source"`: one of `preserved | upgraded | replaced | new` — from the matching classification_table row.
   - `"context_rationale"`: one-sentence rationale — from the matching row.
   If a node has no matching row in the table: inject `"context_source": "new"` and `"context_rationale": "GoT structural addition; no linear-pipeline equivalent."` ec-brief / ec-refeed runs: skip this step (leave both fields absent).

(c) **join_policy check.** For every node with `type=AGGREGATION`: `join_policy` MUST be non-null. Derive from `aggregation_policy` text (`AND-join` → `"AND"`, `OR-join` → `"OR"`). If `aggregation_policy` is null on an AGGREGATION-typed node: HALT with `"N-JSON: AGGREGATION node <id> has null join_policy — fix in N-AGG-DESIGN"`.

(c2) **tier normalization for no-llm nodes (F-2.3 fix).** For every node with `exec_type=inline` and `hat=persister` (or any node with `type` in {`PERSISTER`, `IO`}, or `tier` ∈ {null, "n/a", "N/A", absent}): force `tier="no-llm"` BEFORE emitting. This catches the F-2.3 class where author-claimed tier `"n/a"` violates the closed-vocab `tier` enum. Log each correction as `"v16_resolution": "tier-no-llm-normalized"` on the node entry. **No-llm nodes MUST emit tier="no-llm" verbatim** — the enum admits no synonyms.

(c3) **Metadata auto-compute (F-2.2 fix — Rank-1 audit finding; G-07 split).** After step 2 has built the `nodes` and `edges` arrays, compute and OVERRIDE these `metadata` fields unconditionally — DO NOT trust author-claimed values:

```python
metadata["total_nodes"]    = len(nodes)
metadata["total_edges"]    = len(edges)
metadata["back_edges"]     = sum(1 for e in edges if e["edge_type"] == "back-edge")
metadata["total_waves"]    = max((n.get("wave", 0) for n in nodes if n.get("wave") is not None), default=0)

# G-07: split into two distinct spawn metrics
metadata["spawn_node_count"] = sum(1 for n in nodes if n["exec_type"] == "spawn")
# max_concurrent_spawns_per_run: max spawn-active count across all valid mode combinations
# Valid modes: normal, deep, verbose, strict-verify, strict-verify-deep, strict-verify-verbose, to-spec, to-plan
# For each mode, count spawn nodes active (exec_type=spawn AND mode_gate either absent or evaluates true).
# Compute by iterating modes and summing active spawn nodes; take the maximum.
# Simplified heuristic when mode gates not machine-parseable: max(spawn_node_count, explicitly_documented_max)
metadata["max_concurrent_spawns_per_run"] = _compute_max_concurrent_spawns(nodes, modes=[
    "normal", "deep", "verbose", "strict-verify", "strict-verify-verbose", "to-spec", "to-plan"
])
```

Implement `_compute_max_concurrent_spawns`: for each mode, spawn-active nodes = nodes where `exec_type=spawn` AND (`mode_gate` field absent OR mode appears in mode_gate). Take max over modes. If `mode_gate` fields are not present (produced skill has no mode-conditional nodes), `max_concurrent_spawns_per_run` = `spawn_node_count`.

   **Cap metadata emission (F-002 fix).** Read `stages/cap_tier.md`. Emit the three cap fields into metadata so produced skills declare their own cap posture:
   ```python
   metadata["produced_skill_edge_cap_normal"]    = 100
   metadata["produced_skill_edge_cap_aggressive"] = 120
   metadata["produced_skill_edge_cap_complex"]  = 150
   ```
   These are unconditional constants (the cap values themselves don't change per skill; only the authorization to use them changes via `--complex` / `--evolve-aggressive`). If `stages/cap_tier.md` is unreadable: emit the fields anyway with these canonical values, and log advisory `"cap_tier_missing: using canonical defaults"`.

**HG-07 cap check uses `max_concurrent_spawns_per_run`** (not `spawn_node_count`). Brief-claimed `static_spawns` is compared advisory-only against both fields; differences are logged to `audit_log` but do not halt.

Author-claimed values for all fields are advisory inputs only; the serializer always overwrites them with computed values. If author-claimed and computed disagree, log the override as `"metadata_recomputed": {"field": ..., "claimed": X, "computed": Y}` in a top-level `audit_log` array. This eliminates the F-2.2 drift class.

**Adversarial check:** a malicious brief planting a `total_nodes` lower than `len(nodes)` to suppress audits is defeated because the override is unconditional and non-overridable.

**For hats_json_content:**

(d) **downshift_threshold injection.** For every hat entry with `downshiftable: true`: ensure `downshift_threshold` (float, 0.0–1.0) is present. Apply defaults when absent: `0.20` for all hats; `0.30` for the `verifier` hat (per DD-08). Do NOT add `downshift_threshold` to non-downshiftable hats.

(e) **Schema normalization.** Every hat entry in the generated `hats.json` MUST include these fields in order: `hat_id`, `description`, `tier`, `fallback_tier`, `downshiftable`, `downshift_threshold` (when downshiftable), `nodes`, `exec_types_allowed`, `capabilities_required`, `capabilities_excluded`. The field name is `fallback_tier` (not `fallback`). The hats array is a JSON array (not a dict keyed by hat_id) so that downstream parsers can iterate without key-mapping.

(f) **Per-skill graph.schema.json generation (F-2.4 / F-3.4 fix — Rank-2 audit finding).** The GOTSCS-shipped `graph.schema.json` enforces a hat enum and edge-id pattern fitted to GOTSCS's own graph. Produced skills with domain-specific hats (e.g., `classifier`, `scorer`, `refiner`, `recovery`) or hyphenated edge IDs (e.g., `E-05b`) silently fail validation against that default schema. **Generate a per-skill schema** that is a strict superset of the GOTSCS base, derived from the produced graph's actual vocabulary:

```python
# Compute the per-skill schema deltas from the produced graph + hats
produced_hats     = sorted({n["hat"]  for n in nodes})
produced_types    = sorted({n["type"] for n in nodes})
produced_tiers    = sorted({n["tier"] for n in nodes})
edge_id_pattern   = "^E-?[0-9]+[a-z]?$"  # admits both `E-01` (hyphenated, spec-canonical) AND `E01` (legacy)
node_id_pattern   = "^N-[A-Z][A-Z0-9-]*$"

# Base enums from GOTSCS's own graph.schema.json (closed-vocab floor)
BASE_HAT_ENUM   = ["gate","extractor","analyzer","aggregator","generator","formatter","verifier","persister","no-llm","tailor","expander","lateral","filter","validator"]
BASE_TYPE_ENUM  = ["PREFLIGHT","INGEST","ANALYZER","DECOMPOSITION","AGGREGATION","GATE","GENERATOR","PLANNER","SYNTHESIS","FORMATTER","VERIFIER","PERSISTER","TAILOR","XREF","LATERAL","DEFIXATION","SIMULATION","PRECISION","ADVERSARIAL","CONJECTURE","ROUTER","ATTACKER","EXPANSION","CLASSIFIER","META-ANALYZER","RECOVERY","FILTER","TRIAGE","ACTUATOR","IO","VALIDATOR","SCORER","REFINER"]
BASE_TIER_ENUM  = ["model-small","model-medium","model-large","no-llm"]

# Union: base enum ∪ produced values, with adversarial-check guard
final_hat_enum  = sorted(set(BASE_HAT_ENUM)  | set(produced_hats))
final_type_enum = sorted(set(BASE_TYPE_ENUM) | set(produced_types))
final_tier_enum = sorted(set(BASE_TIER_ENUM) | set(produced_tiers))

# Adversarial-check guard: every produced hat MUST appear in `briefing-core.md` H.6 hat-vocabulary
# OR be explicitly justified in a `hats.json` entry's `description` field. Reject hats with
# empty descriptions or entries marked `experimental: true` without a documented purpose.
for h in produced_hats:
    if h not in BASE_HAT_ENUM:
        # Domain-specific hat — verify it has a hats.json entry with non-empty description
        match = next((x for x in hats if x["hat_id"] == h), None)
        if not (match is not None and match.get("description","").strip()):
            print(f"HALT: halt-on-undocumented-hat: '{h}' is not in base enum and has no hats.json entry with a non-empty description", file=sys.stderr)
            sys.exit(1)
```

The generated schema MUST be a JSON Schema draft-07 document with the union enums above, the relaxed edge-id pattern (`^E-?[0-9]+[a-z]?$`), and a top-level `description` field naming the produced skill. Write the generated schema to `stages/N-JSON.md` as a third JSON code block titled `## generated_schema_content`. **N-EMIT step 4 copies THIS generated schema, not the GOTSCS default**, into the produced skill at `<skill>/graph.schema.json` (per the F-2.4 routing fix in `modules/N-EMIT.md`).

**Adversarial check:** a brief could attempt to declare arbitrary hat values not present in any catalogue. The undocumented-hat guard above HALTs on hats absent from both the base enum (`BASE_HAT_ENUM` defined above, sourced from the H.1 hat field closed-vocab in briefing-core.md) and any documented `hats.json` entry. Mitigate further by (recommended) cross-checking produced hats against BASE_HAT_ENUM union with brief-specified extensions.

1.8. **Path-conditional wave sentinel (G-14).** Before serializing, for any node where `wave` is null or absent (path-conditional nodes that have no canonical wave assignment): set `wave = "path-conditional"`. This prevents `null` values in the wave field that trip arithmetic aggregation scripts (e.g., `Wave None: 20000` in token-budget totals). The string `"path-conditional"` is excluded from `total_waves` computation in step 1.5(c3) (`max(n.get("wave") for n in nodes if isinstance(n.get("wave"), int))`).

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

4. **Serialize hats.json.** Produce hats.json as a **JSON array of hat entries** (NOT a dict keyed by hat_id, NOT a dict-with-`hats`-key wrapper, NOT a tuple of {default_models, hats}). Every reachable consumer (V23, smoke G-13/2, N-EMIT format-guard) iterates over the top-level array. Map every hat used by a node in the registry. Required output format:
   ```json
   [
     {
       "hat_id": "gate",
       "description": "Guards entry into the pipeline; halts on brief quality failures",
       "tier": "model-small",
       "model": "claude-haiku-4-5-20251001",
       "fallback_tier": "model-medium",
       "downshiftable": true,
       "downshift_threshold": 0.20,
       "nodes": ["N-PREFLIGHT"],
       "exec_types_allowed": ["inline"],
       "capabilities_required": [],
       "capabilities_excluded": []
     }
   ]
   ```
   - The field is `fallback_tier` (not `fallback`).
   - Include `downshift_threshold` only on entries where `downshiftable: true`.
   - **`model` field (H2 fix — eliminates orphan hats-meta.json sidecar).** Each hat entry MUST include a `model` field naming the concrete model_id resolved from the `tier`. This inlines what was previously a separate `default_models` dict at the top level. Resolution table (canonical for v4.3+):
     | tier | model |
     |---|---|
     | `model-small` | `claude-haiku-4-5-20251001` |
     | `model-medium` | `claude-sonnet-4-6` |
     | `model-large` | `claude-opus-4-7` |
     | `no-llm` | `null` |
   - Do NOT emit a top-level `default_models` dict, and do NOT wrap the array in a parent dict (`{"hats": [...]}`). N-EMIT format-guard at step 4 will HALT with `halt-on-hats-format-fail` and route to N-JSON via E59 if the structure is not a top-level array.
   - GOTSCS's own `hats.json` uses a legacy dict format — do NOT copy that format; the produced skill's `hats.json` MUST be the array-with-inlined-model format per this step.

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
