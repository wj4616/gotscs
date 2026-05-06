---
node_id: N-MODULES
node_type: GENERATOR
hat: generator
exec_type: spawn
tier: model-large
scale_gates: {token_budget: 9000, time_budget: 900, spawn_budget: 2, retry_budget: 1}
input_ports:
  - port: graph_spec
    format: markdown
    signal_field: graph_spec
    required: true
output_ports:
  - port: modules_manifest
    format: markdown
    signal_field: modules_result
raises_signals: [modules_result]
required_output_sections: [modules_manifest, emission_format]
---

## INPUT ports
- graph_spec: markdown  (signal_field: graph_spec)

## OUTPUT ports
- modules_manifest: markdown  (signal_field: modules_result)

## AI advantages exploited
- consistency_at_scale   # apply identical module template to every node without per-field fatigue
- full_corpus_retention  # hold all node descriptions and aggregation policies simultaneously

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-MODULES: briefing-core only. No appendices required. -->

0.5. **v6_file_bijection_early_check (V6 pre-shifted from N-VERIFY per DD-04).** Immediately after step 5 emits the per-file modules, verify the bijection in-place before signalling modules_result:
   - Compute `set(node_ids)` from `stages/N-SYNTH-GRAPH.md § node_registry`.
   - Compute `set(filenames-without-extension)` from `ls stages/modules/*.md`.
   - The two sets MUST be equal. Any extra file or missing node MUST HALT with `halt-on-module-bijection-mismatch` listing the offending entries.
   - Each emitted file MUST have exactly one `^node_id:` line at column 0 (counted via `grep -c "^node_id:"`) and zero `<!-- MODULE: modules/` cross-module leakage markers.
   This shift means N-VERIFY's V10 (file-bijection check residual) only does final attestation rather than primary discovery.

1. **Read graph_spec** from `stages/N-SYNTH-GRAPH.md`. Extract Node Registry table (all nodes) and Aggregation Policies. Also Read briefing-core.md to load the H.1-H.9 schema vocabulary before generating any module content.

2. **Capacity guard.** Count the number of nodes in the registry. If node_count > 12: split generation into two batches (Waves 1-6 nodes, then Waves 7+ nodes), writing each batch to `stages/N-MODULES-batch1.md` and `stages/N-MODULES-batch2.md`. Merge into `stages/N-MODULES.md` after both complete. This prevents token-budget overflow for large skills.

3. **For each node in the registry**, generate module file content using the Module file template:
   ```markdown
   ---
   node_id: <stage_id>
   node_type: <H.1 type>
   hat: <hat>
   exec_type: <inline|spawn>
   tier: <model-large|model-medium|model-small>
   scale_gates: {token_budget: N, time_budget: N, spawn_budget: N, retry_budget: N}
   [aggregation_policy: "..." if AGGREGATION node]
   [join_policy: "..." if VERIFIER node]
   input_ports:
     - port: <name>
       format: <json|yaml|markdown|text|binary>
       signal_field: <field>
       required: <true|false>
   output_ports:
     - port: <name>
       format: <format>
       signal_field: <field>
   raises_signals: [...]
   required_output_sections: [...]
   ---

   ## INPUT ports
   - <port_name>: <format>  (<signal_field>[, join semantics if applicable])

   ## OUTPUT ports
   - <port_name>: <format>  (signal_field: <field>)

   ## AI advantages exploited
   - <catalogue_key>  # from H.7

   [## AGGREGATION POLICY (V9 verbatim)
   > "Aggregation is the defining unlock..."
   - Decomposition tree: ...
   - Synthesis strategy: ...
   - Join semantics: ...
   - Activation condition: ...
   - Branch-budget cap: ...]

   ## Protocol

   0. **Load schema vocabulary.** Read briefing-core.md. This makes H.1–H.9 node type taxonomy, hat definitions, and signal field conventions available for all subsequent steps in this module.

   <numbered steps specific to this node's cognitive role>

   ## Scale gates
   - tokens: <N>
   - time: <N>s
   - spawns: <N>
   - retries: <N>

   ## Failure modes
   - timeout: <repair route>
   - malformed output: <repair route>
   - missing input: <repair route>
   - format-mismatch on Edge: <repair route>
   ```

3b. **Aggregation nodes MUST include** the V9 verbatim quote in their AGGREGATION POLICY section: "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."

4. **Protocol steps** for each node must be specific to that node's role (not generic). Minimum 4 steps per node. Each step must specify what to read, what to produce, and what signal to emit.

5. **Per-file emission (P-001 — replaces v3.0.0 monolithic manifest).** For every node:
   - Write the module body to `stages/modules/<node_id>.md` (one file per node — directory must exist; create with `mkdir -p` if absent).
   - The file MUST contain exactly one YAML frontmatter block (between two `---` lines) at the top, immediately followed by the body sections (no stray code-fence markers like ` ``` ` between the closing `---` and the body).
   - The file MUST NOT contain comment markers like `<!-- MODULE: modules/... -->` or trailing manifest fragments — those are extraction artifacts and must not be embedded.

6. **Write `stages/N-MODULES.md` as a thin index** (no embedded module bodies — bodies live in `stages/modules/<node_id>.md` per step 5):
   ```
   ## modules_manifest

   | module_file | node_id | line_count |
   |---|---|---|
   | stages/modules/N-PREFLIGHT.md | N-PREFLIGHT | <N> |
   | stages/modules/N-NORMALIZE.md | N-NORMALIZE | <N> |
   ...

   ## emission_format
   per_file_v4   # P-001: each module written as standalone file in stages/modules/
   ```
   Emit signal: `modules_result`. Downstream N-EMIT consumes the per-file outputs directly via `cp stages/modules/*.md <skill_path>/modules/` — no parsing of the manifest required.

## Scale gates
- tokens: 9000
- time: 900s
- spawns: 2
- retries: 1

## Failure modes
- timeout: retry once; emit modules_manifest with completed modules, flag remaining
- malformed output: re-emit the manifest structure
- missing input: HALT "N-MODULES: graph_spec missing"
- format-mismatch on Edge: re-read stages/N-SYNTH-GRAPH.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-MODULES
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
