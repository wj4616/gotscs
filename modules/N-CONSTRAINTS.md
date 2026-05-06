---
node_id: N-CONSTRAINTS
node_type: ANALYZER
hat: analyzer
exec_type: spawn
tier: model-medium
scale_gates: {token_budget: 3000, time_budget: 180, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: normalize_result
    format: markdown
    signal_field: normalize_digest
    required: true
output_ports:
  - port: constraints_result
    format: markdown
    signal_field: constraints_digest
raises_signals: [constraints_digest, conflict_signals]
required_output_sections: [inventory_items, anti_patterns_guarded, ai_advantages_selected, constraints_digest]
---

## INPUT ports
- normalize_result: markdown  (signal_field: normalize_digest)

## OUTPUT ports
- constraints_result: markdown  (signal_field: constraints_digest)

## AI advantages exploited
- full_corpus_retention            # hold all INVENTORY items simultaneously
- cross_document_pattern_recognition  # match constraints to H.8 anti-pattern catalogue

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-CONSTRAINTS: briefing-core + briefing-appendix-antipatterns. -->

0.5. **Validation-mode check (HC-17).** Check whether `stages/validation-mode.md` exists.
   - If absent: proceed normally; emit only `constraints_digest`.
   - If present: read its single-line content. Set `validation_mode=true`. Read `stages/N-CONTEXT-ANALYZE.md` to access the context-claimed constraints inventory. Run as a validation branch:
     a. Compute the constraints inventory + AP-catalogue mapping (steps 1-4 below).
     b. Compare against the context-claimed constraints.
     c. For every disagreement, emit a `conflict_signal` record: `{element: <constraint-element>, context_claim: <X>, derived: <Y>, severity: <minor|major|blocker>, rationale: <why-they-differ>}`.
     d. Emit BOTH `constraints_digest` (the H.1/H.8-derived value) AND a `conflict_signals` array.

1. **Read inputs.** Read `stages/N-NORMALIZE.md`. Focus on constraints list.

1.5. **Spawn invocation note.** N-CONSTRAINTS now executes as `exec_type: spawn` per DD-08. The orchestrator dispatches this node via the standard subagent spawn invocation (see SKILL.md STEP 3 for the Agent() prompt template); the subagent reads briefing-core.md + briefing-appendix-antipatterns.md, then proceeds with steps 2-5. retry_budget is 1; on retry the orchestrator re-spawns.

2. **Build INVENTORY (EC3 rule).** Every explicit constraint, named entity, URI, tone marker, success criterion, and anti-pattern reference in the input becomes an INVENTORY item. List verbatim. These MUST appear in the final skill's Hard Gates.

3. **Match H.8 anti-patterns.** For each anti-pattern in the H.8 catalogue (AP-S1 through AP-V31), determine:
   - Is this pattern a risk given the target skill's domain and structure?
   - If yes: note which Node or Edge should guard against it.
   Minimum coverage: always flag AP-T1 (documentary-only metadata), AP-V4 (diagram-edge drift), AP-V27 (source-of-truth contradiction).

4. **Select H.7 AI-advantage catalogue entries.** From the 7 entries:
   1. parallel_artifact_processing
   2. full_corpus_retention
   3. cross_document_pattern_recognition
   4. multi_perspective_simulation
   5. consistency_at_scale
   6. super_human_recall
   7. topology_aware_reasoning
   Select ≥3 that the target skill should exploit. Document per-node assignment suggestions.

5. **Write constraints_digest.** Write to `stages/N-CONSTRAINTS.md`:
   ```
   ## inventory_items
   <numbered list of verbatim items>

   ## anti_patterns_guarded
   <table: AP-ID | risk level | guarding node/edge>

   ## ai_advantages_selected
   <list: catalogue_key | assigned nodes>

   ## constraints_digest
   inventory_count: <N>
   anti_patterns_flagged: <N>
   ai_advantages_count: <N>   # must be ≥3
   ```
   Emit signal: `constraints_digest`. When `validation_mode=true`, also emit `conflict_signals` array in the output.

## Scale gates
- tokens: 3000
- time: 180s
- spawns: 0
- retries: 1

## Failure modes
- timeout: retry once; emit constraints_digest with empty anti_patterns (flag as LOW confidence)
- malformed output: re-run step 5 only
- missing input: HALT "N-CONSTRAINTS: normalize_result missing"
- format-mismatch on Edge: re-read stages/N-NORMALIZE.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-CONSTRAINTS
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
