---
node_id: N-SKILL-RENDER
node_type: FORMATTER
hat: formatter
exec_type: inline
exec_type_conditional: "spawn when produced_node_count > 12 OR produced_edge_count > 20 OR estimated_skill_md_size_kb > 30; else inline (F-2.1 / F-3.5 fix — Rank-6 audit finding)"
tier: model-medium
mode_gate: "MODE in ['skill','both']"
scale_gates: {token_budget: 10000, time_budget: 480, spawn_budget: 0, retry_budget: 1}
scale_gates_conditional: {when: "exec_type=spawn", token_budget: 16000, time_budget: 600, spawn_budget: 1, retry_budget: 1}
input_ports:
  - port: graph_spec
    format: markdown
    signal_field: graph_spec
    required: true
    note: "From N-SYNTH-GRAPH — already aggregates registry/edges/waves/aggregation_policies into a unified spec; N-SKILL-RENDER reads this single source for §0 ARCHITECTURE / §1 / §1.5 / §2 / §3 / §4 / §5 / §5.5 / §6 / §7."
  - port: normalize_digest
    format: markdown
    signal_field: normalize_digest
    required: true
    note: "For skill_name (frontmatter `name:`), input_shape, output_shape, success_criteria (§0 SKILL HEADER + §0 INVOCATION)."
  - port: constraints_digest
    format: markdown
    signal_field: constraints_digest
    required: true
    note: "For inventory_items (§0 HARD GATES — verbatim per V11 P-003 blocking) and anti_patterns_guarded list."
  - port: json_result
    format: markdown
    signal_field: json_result
    required: true
    note: "Hard ordering dependency (P0-4): N-JSON must complete before N-SKILL-RENDER executes. The §1 Node Registry scale_gates column is sourced from graph.json — stale values cause V13(e) failures when N-JSON is repaired after an initial render attempt."
output_ports:
  - port: rendered_skill_md
    format: markdown
    signal_field: skill_render_result
raises_signals: [skill_render_result]
required_output_sections: [rendered_skill_md]
---

## INPUT ports
- graph_spec: markdown (signal_field: graph_spec — from N-SYNTH-GRAPH; already aggregates registry/edges/waves/aggregation_policies)
- normalize_digest: markdown (signal_field: normalize_digest — for skill_name, shapes, success_criteria)
- constraints_digest: markdown (signal_field: constraints_digest — for inventory_items VERBATIM (V11 source) + anti_patterns_guarded)

## OUTPUT ports
- rendered_skill_md: markdown (signal_field: skill_render_result — fully-assembled SKILL.md content; written to `stages/N-SKILL-RENDER.md`. N-EMIT step 4 copies this verbatim to `<skill>/SKILL.md` — no re-rendering at emit time.)

## AI advantages exploited
- consistency_at_scale  # apply identical document template to every produced skill without per-section drift
- full_corpus_retention # hold all 7 input stage files simultaneously to assemble cross-referenced sections without omission

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-SKILL-RENDER: briefing-core only. Replace any embedded briefing-content reference with "see briefing-core.md". -->

0.0a. **Exec-type self-evaluation (F-2.1 / F-3.5 fix — Rank-6 audit finding).** Before opening the input stage files, the orchestrator at SKILL.md STEP 9 evaluates this node's exec_type from the gate `produced_node_count > 12 OR produced_edge_count > 20 OR estimated_skill_md_size_kb > 30`:
   - Read `stages/N-SYNTH-GRAPH.md` frontmatter for `node_count`, `edge_count`.
   - Estimate `skill_md_size_kb` ≈ `node_count * 1.5 + edge_count * 0.4 + 12 KB base`. Empirically (audit run): 15 nodes / 26 edges → ≈45 KB estimate; actual 56 KB.
   - If gate evaluates true: orchestrator dispatches N-SKILL-RENDER as a spawn with the conditional scale_gates `{token_budget: 16000, time_budget: 600, spawn_budget: 1, retry_budget: 1}`.
   - If gate evaluates false: orchestrator runs N-SKILL-RENDER inline with the default scale_gates.
   This conditional eliminates the F-2.1 protocol-deviation class (the audit run delegated to spawn out-of-band because the inline 10K budget could not hold the 56 KB SKILL.md assembly). The remaining protocol below is identical for both exec paths.

   **Adversarial check:** a small skill (≤12 nodes, ≤20 edges, ≤30 KB) stays inline and saves the spawn cost. A large skill auto-promotes to spawn before token cliffs hit. If the size estimate is wrong, retry_budget=1 admits one re-attempt at the larger budget.

0.5. **N-JSON dependency barrier (P0-4).** Confirm `stages/N-JSON.md` exists. Check its frontmatter for a `repair_pass:` key. If `repair_pass:` is present: N-JSON was repaired after a prior emission — **re-read all `scale_gates` values from the graph_json_content block in stages/N-JSON.md** before building the §1 Node Registry table. Using stale (pre-repair) budgets produces V13(e) failures. If `stages/N-JSON.md` is absent: HALT with `"N-SKILL-RENDER: json_result missing — N-JSON must complete before N-SKILL-RENDER executes"`.

1. **Read 3 input stage files.** N-SYNTH-GRAPH already aggregates the registry/edges/waves/aggregation_policies content; the additional 2 reads provide the only sections N-SYNTH-GRAPH does not preserve (skill_name in normalize, inventory_items verbatim in constraints):
   - `stages/N-NORMALIZE.md` (skill_name, input_shape, output_shape, success_criteria, latency_tolerance)
   - `stages/N-CONSTRAINTS.md` (inventory_items VERBATIM — preserve every character; anti_patterns_guarded table, ai_advantages_selected)
   - `stages/N-SYNTH-GRAPH.md` (graph_spec — contains §pipeline_summary, §three_layer_rule, §node_registry, §aggregation_policies (with V9 verbatim), §edge_table, §wave_plan, §mode_matrix, §optimizations, §failure_modes, §got_controller, §pipeline_narrative)
   If any required file is missing: HALT with `halt-on-missing-input` listing the absent stage.

2. **Assemble the rendered SKILL.md document.** The output MUST contain ALL of the following sections in this exact order:

   **YAML frontmatter:**
   ```yaml
   ---
   name: <skill_name from normalize_digest>
   version: 1.0.0
   graph_file: graph.json
   hats_file: hats.json
   topology: <topology_class from graph_spec>
   waves: <total_waves>
   nodes: <node_count>
   edges: <edge_count>
   determinism_class: <from graph_spec metadata; default non-deterministic>
   ---
   ```

   **§0 SKILL HEADER:** `# <skill_name>` + 1-2 sentence purpose (from normalize_digest domain + success_criteria).

   **§0 INVOCATION:** Code block showing `skill_name "<input>"`.

   **§0 HARD GATES (V11-blocking source per P-003):**
   ```markdown
   ## HARD GATES

   <bulleted list — every inventory_item from N-CONSTRAINTS pasted VERBATIM, one bullet each. NO paraphrasing, NO abbreviation. The V11 verifier will substring-match each item against this section.>

   <Then: anti-patterns from N-AGG-DESIGN's "Anti-Patterns Guarded" table — one bullet per AP-ID with guarding node.>
   ```

   **§0 ARCHITECTURE:** Pipeline summary from `graph_spec § pipeline_summary` (verbatim) + ASCII diagram from `graph_spec § pipeline_summary § Pipeline ASCII diagram`.

   **§1 Node Registry:** Full table from `stages/N-SYNTH-GRAPH.md § node_registry` (originating in N-REGISTRY but already aggregated into graph_spec by Wave 7; all columns) — **with the following columns sourced authoritatively from `stages/N-JSON.md` graph_json_content rather than from N-SYNTH-GRAPH** (F-2.5 fix — Rank-4 audit finding):
   - `Tier` column → read from `graph_json_content.nodes[i].tier` (N-JSON step 1.5(c2) normalized this; for no-llm nodes the canonical value is the literal string `"no-llm"`, NOT `"n/a (no-llm)"` or `"n/a"`).
   - `scale gates` column → read from `graph_json_content.nodes[i].scale_gates` (N-JSON step 1.5(a) may have applied V16 promotions/inline-ceiling reductions; the post-repair values are authoritative).

   Read these two columns from the graph_json_content code block in `stages/N-JSON.md`. All other columns (`stage ID`, `Hat`, `Module file`, `INPUT/OUTPUT ports`, `Join semantics`, `ai_advantages_exploited`, `spawn_share`, `one-line PROTOCOL`) read from N-SYNTH-GRAPH's node_registry as before. **Reason:** when N-JSON's repair-pass mutates tier (e.g., normalizes `n/a` → `no-llm`) or scale_gates (e.g., V16 spawn-promotion bumping spawn_budget from 0 to 1), the upstream N-SYNTH-GRAPH stage file is stale. Reading those two columns from graph_json_content guarantees the rendered §1 reflects the post-repair state.

   **Adversarial check:** if N-JSON has not yet emitted (P0-4 ordering violation), the read fails immediately with the existing P0-4 barrier HALT, not silently. If `stages/N-JSON.md` exists but lacks `graph_json_content` (malformed N-JSON output), HALT with `halt-on-malformed-json-stage` rather than fall back to stale N-SYNTH-GRAPH values — silent fallback is the F-2.5 root cause.

   **§1.5 Aggregation Policies:** Full content from `stages/N-SYNTH-GRAPH.md § aggregation_policies` — MUST include V9 verbatim quote: `> "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."`

   **§2 Edge Table:** Full table from `stages/N-SYNTH-GRAPH.md § edge_table` + `conditional_edge_signals` subsections (originating in N-EDGES; aggregated into graph_spec).

   **§3 Mode Matrix:** Full table from `stages/N-SYNTH-GRAPH.md § mode_matrix_table` (originating in N-WAVES; aggregated into graph_spec).

   **§4 Wave Plan:** Full table from `stages/N-SYNTH-GRAPH.md § wave_plan_table` + total spawn budget annotation (originating in N-WAVES; aggregated into graph_spec).

   **§5 Optimizations:** From `stages/N-SYNTH-GRAPH.md § optimizations`.

   **§5.5 Failure Modes:** From `stages/N-SYNTH-GRAPH.md § failure_modes`.

   **§6 GoT Controller:** From `stages/N-SYNTH-GRAPH.md § got_controller` (orchestrator dispatch instructions: inline vs spawn, parallel dispatch points, barrier conditions).

   **§7 Pipeline Narrative:** From `stages/N-SYNTH-GRAPH.md § pipeline_narrative` (2-3 paragraph end-to-end description).

   **Appendix A — H.1-H.9 Schema Reference (see briefing-core.md):**
   ```
   ## Appendix A — H.1-H.9 Schema Reference

   See briefing-core.md (and any appendices listed in the produced skill's read-map) for the canonical schema reference. The produced SKILL.md links rather than embeds to keep token cost bounded; readers should fetch briefing-core.md for full schema content.
   ```

3. **Self-audit before emission (V11 pre-check).** Before writing, verify:
   - Every inventory_item from `stages/N-CONSTRAINTS.md` appears in §0 HARD GATES (whitespace-normalized substring match).
   - The V9 verbatim quote appears in §1.5 Aggregation Policies.
   - Every node from `stages/N-SYNTH-GRAPH.md § node_registry` appears in §1 Node Registry.
   - The Appendix A header is present.
   If any check fails: regenerate the failing section once. If still failing on retry: emit with `render_warnings:` annotation listing each gap, but still write — N-VERIFY V11 will catch it as the authoritative gate.

4. **Write output** to `stages/N-SKILL-RENDER.md`. The file content IS the SKILL.md content for the produced skill — N-EMIT step 4 copies it verbatim. Emit signal: `skill_render_result=present`.

## Scale gates
- tokens: 10000
- time: 480s
- spawns: 0 (inline)
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit a minimal SKILL.md with `## INCOMPLETE_RENDER` advisory listing missing sections — better than no SKILL.md at all
- malformed output (any of the 11 required sections missing): retry once with explicit section-by-section assembly; if still missing emit the partial render with `render_warnings:` advisory listing missing sections and let N-VERIFY V11 catch the gap
- missing input: HALT "N-SKILL-RENDER: required stage file <name> missing"
- format-mismatch on Edge: re-read source stage files directly by absolute path (no edge-protocol intermediate)

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-SKILL-RENDER
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
