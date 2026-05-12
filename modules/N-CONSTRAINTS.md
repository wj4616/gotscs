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
  - port: evolution_mode
    format: signal
    signal_field: evolution_mode
    required: true
  - port: fusion_plan
    format: markdown
    signal_field: fusion_plan
    required: false
output_ports:
  - port: constraints_result
    format: markdown
    signal_field: constraints_digest
  - port: hard_constraints
    format: markdown
    signal_field: hard_constraints
  - port: soft_constraints
    format: markdown
    signal_field: soft_constraints
  - port: fusion_constraints
    format: markdown
    signal_field: fusion_constraints
raises_signals: [constraints_digest]
raises_signals_conditional: [conflict_signals, hard_constraints, soft_constraints, fusion_constraints]
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
   <!-- DD-03 read-map for N-CONSTRAINTS: briefing-core + briefing-appendix-antipatterns + briefing-appendix-contract (§EC-FC04 — read in evolve mode for FC-04 enforcement). -->

0.5. **Validation-mode check (HC-17).** Check whether `stages/validation-mode.md` exists.
   - If absent: proceed normally; emit only `constraints_digest`.
   - If present: read its single-line content. Set `validation_mode=true`. Read `stages/N-CONTEXT-ANALYZE.md` to access the context-claimed constraints inventory. Run as a validation branch:
     a. Compute the constraints inventory + AP-catalogue mapping (steps 1-4 below).
     b. Compare against the context-claimed constraints.
     c. For every disagreement, emit a `conflict_signal` record: `{element: <constraint-element>, context_claim: <X>, derived: <Y>, severity: <minor|major|blocker>, rationale: <why-they-differ>}`.
     d. Emit BOTH `constraints_digest` (the H.1/H.8-derived value) AND a `conflict_signals` array.

1. **Read inputs.** Read `stages/N-NORMALIZE.md`. Focus on constraints list.

1.5. **Spawn invocation note.** N-CONSTRAINTS now executes as `exec_type: spawn` per DD-08. The orchestrator dispatches this node via the standard subagent spawn invocation (see SKILL.md STEP 3 for the Agent() prompt template); the subagent reads briefing-core.md + briefing-appendix-antipatterns.md (always), AND briefing-appendix-contract.md §EC-FC04 (only when `evolution_mode in {evolve, evolve-aggressive}` — required for FC-04 enforcement at step 6), then proceeds with steps 2-6. retry_budget is 1; on retry the orchestrator re-spawns.

2. **Build INVENTORY (EC3 rule).** Every explicit constraint, named entity, URI, tone marker, success criterion, and anti-pattern reference in the input becomes an INVENTORY item. List verbatim. These MUST appear in the final skill's Hard Gates.

3. **Match H.8 anti-patterns.** For each anti-pattern in the H.8 catalogue (AP-S1 through AP-V31), determine:
   - Is this pattern a risk given the target skill's domain and structure?
   - If yes: note which Node or Edge should guard against it.
   Minimum coverage: always flag AP-T1 (documentary-only metadata), AP-V4 (diagram-edge drift), AP-V27 (source-of-truth contradiction).

3.5. **IC-04 override blacklist guard (G-06).** Scan all D-NN brief directives for any that target the following blacklisted elements: HC-01 through HC-26, HG-01, HG-05, AP-V19, AP-V27. A D-NN directive "targets" a blacklisted element if it contains the HC/HG/AP identifier AND any of {override, unconditionally, replace, remove, disable, bypass, skip}. For each match: HALT with `halt-on-protected-override` listing: (a) the D-NN directive text, (b) the blacklisted element it targets, (c) why that element is protected. Do NOT proceed to step 4 if any override-blacklist violation is found.

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

0.5. **Read cap tier (I-01).** Read `stages/cap_tier.md`. Extract `max_nodes`, `max_waves`, `max_edges`. If the file is missing: fall back to standard caps (30/15/100) and log advisory `cap_tier_fallback: standard`. Use these values in place of any hard-coded cap numbers in the protocol below.

6. **Mode-dependent emission (NEW v4.3 — spec §3.7).** Read `evolution_mode` from `stages/N-PREFLIGHT.md`. Branch:

   **`overlay` and `greenfield` modes:** terminate after step 5. The legacy `inventory_items` block IS the hard-preservation contract; AP-15 applies in full force; no further sections are emitted. This branch is byte-identical to v4.2.0.

   **`evolve` and `evolve-aggressive` modes:** read `stages/N-FUSION-ANALYZE.md` (must exist; HALT with `halt-fusion-prereq-missing` if absent). Then emit THREE additional sections beyond the legacy output:

   ```markdown
   ## hard_constraints
   <closed-vocab universal invariants ONLY — these remain V11-blocking even in evolve mode:
     - HC-02 topology caps (≤{cap_tier.max_nodes} nodes / ≤{cap_tier.max_waves} waves / ≤{cap_tier.max_edges} edges)
     - HC-03 edge typology closed-vocab
     - HC-04 H.1 closed-vocab schema enums
     - Every HC-* tagged class: SECURITY or class: PRIVACY
   Format: numbered list, one per line, with the original HC-NN identifier.>

   ## soft_constraints
   <recommended-but-not-mandatory items derived from the original skill's HC- / AP- / INV- corpus that did NOT match the universal-invariant filter above. Schema:
     | soft_id (SC-NN) | source (HC-/AP-/INV-) | recommendation | rationale | overrideable_by |
   The `overrideable_by` field MUST be `brief` for default items, `none` for items whose registry ID appears in EC-FC04-1..5 (per briefing-appendix-contract §EC-FC04). MULTIPLE soft constraints may map to the same original HC- if the original had implicit subsections.>

   ## fusion_constraints
   <evolve-mode-specific constraints from spec §3.7 (FC-01 through FC-09). Always emitted in evolve mode. Schema:
     | fc_id | constraint | enforcement_phase |
   Required entries:
     | FC-01 | Every divergence from original MUST be documented in fusion_decisions[] | N-FUSION-ANALYZE step 7 |
     | FC-02 | If brief is silent on a design question, prefer spec over original skill | N-FUSION-ANALYZE step 6 (precedence-stack default fallback) |
     | FC-03 | If brief contradicts both spec and original, brief wins — but MUST include risk_acknowledgment | N-AGG-DESIGN consumption + V-battery |
     | FC-04 | INVENTORY items inherited as candidates, not mandates, EXCEPT external-contract items per briefing-appendix-contract §EC-FC04 | N-FUSION-ANALYZE step 6 external-contract guard |
     | FC-05 | Backward compatibility advisory for internal details, MANDATORY for external behavior unless --strict OR contract_override | N-FUSION-ANALYZE step 6 + N-AGG-DESIGN step 6b |
     | FC-06 | Optimization for final utility is the primary objective | N-AGG-DESIGN synthesis |
     | FC-07 | When replacing a node, the new node MUST satisfy all functional contracts of the old node unless brief explicitly redefines them | N-VERIFY residual battery (Phase 3 — V26 fusion-contract check) |
     | FC-08 | Every redesign MUST have a corresponding regression test in the smoke-test battery | N-EMIT smoke-test bootstrap (Phase 3) |
     | FC-09 | --evolve-aggressive requires waiver_justification ≥50 chars persisted in FUSION.md and graph.json metadata | N-PREFLIGHT step 4a (already enforced) + N-EMIT FUSION.md emission (Phase 3) |
   When evolution_mode == 'evolve-aggressive' AND the waiver_justification was < 50 chars: this is unreachable (N-PREFLIGHT step 4a refuses earlier). If reached, emit `halt-fusion-constraint-FC-09-violated`.>
   ```

   Emit signals: `hard_constraints=present`, `soft_constraints=present`, `fusion_constraints=present`. The legacy `constraints_digest` signal is also still emitted (overlay-mode parity).

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
