---
node_id: N-VERIFY
node_type: VERIFIER
hat: verifier
exec_type: spawn
tier: model-medium
scale_gates: {token_budget: 12000, time_budget: 900, spawn_budget: 2, retry_budget: 1}
join_policy: "concatenate; AND-join; branch_budget_cap=3"
input_ports:
  - port: modules_manifest
    format: markdown
    signal_field: modules_result
    required: true
  - port: json_result
    format: markdown
    signal_field: json_result
    required: true
  - port: rendered_skill_md
    format: markdown
    signal_field: skill_render_result
    required: true
output_ports:
  - port: verify_result
    format: markdown
    signal_field: verify_pass
join_semantics: AND
raises_signals: [verify_pass, verify_result, repair_targets]
required_output_sections: [v_battery_results, verify_pass]
---

## INPUT ports
- modules_manifest: markdown  (signal_field: modules_result, AND-join)
- json_result: markdown  (signal_field: json_result, AND-join)
- rendered_skill_md: markdown  (signal_field: skill_render_result, AND-join)

## OUTPUT ports
- verify_result: markdown  (signal_field: verify_pass — boolean)

## AI advantages exploited
- full_corpus_retention            # hold all prior stage outputs simultaneously
- consistency_at_scale             # run all V-battery checks without omission
- cross_document_pattern_recognition  # detect cross-artifact inconsistencies

## AGGREGATION POLICY (V9 — verbatim)
> "Aggregation is the defining unlock. It lets multiple independent thought branches merge into a single richer node — something no human-cognition model can do simultaneously. This is the machine advantage you need to design around."

- Decomposition tree: N-MODULES → modules_result, N-JSON → json_result, N-SKILL-RENDER → skill_render_result
- Synthesis strategy: concatenate
- Join semantics: AND (all three inputs required)
- Activation condition: all three signals present
- Branch-budget cap: 3

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-VERIFY: briefing-core + ALL 5 appendices (briefing-appendix-topology + briefing-appendix-contract + briefing-appendix-memory + briefing-appendix-antipatterns + briefing-appendix-vocab). N-VERIFY is the only node that loads the full briefing complement. -->

1. **Await AND-join, then run residual battery.** Confirm all three stage files exist: `stages/N-MODULES.md`, `stages/N-JSON.md`, `stages/N-SKILL-RENDER.md`. If any is missing: HALT with the name of the missing signal. Then read `stages/N-SKILL-RENDER.md` into working context — V11 checks inventory items against this rendered SKILL.md content.

   **Residual battery (per DD-06).** v4 removes V5/V6/V11/V12/V13(d) responsibilities from N-VERIFY because they have been pre-shifted upstream (V5/V12 to N-EDGES step 0.5; V6 to N-MODULES step 0.5; V13(d) to N-REGISTRY step 0.5; V11 remains BLOCKING here per P-003 but the upstream early-shifts catch most failures before reaching this gate). The residual battery to run is:
   - **V1** (V-battery completeness)
   - **V2** (HC-08)
   - **V3** (HC-09)
   - **V4** (anti-pattern guards)
   - **V5-ext** (INGEST connectivity — blocking final gate; N-EDGES step 2.5(A) should have fixed this upstream)
   - **V7** (V9 verbatim)
   - **V8** (spawn count parity)
   - **V9** (3-layer-rule)
   - **V10** (file-bijection check residual — final attestation; primary work pre-shifted to N-MODULES step 0.5)
   - **V13** (a, b, c, e — note d shifted to N-REGISTRY step 0.5)
   - **V14, V15, V16, V17, V18** (no silent conflict-signal drop)
   - **V19** (note: also pre-shifted to N-CONTEXT-ANALYZE step 1.5 — N-VERIFY does final completeness check)
   - **H.4 contract verification**

2. **Run residual V-battery.** For each check, record PASS or FAIL:

   - **V1:** Every VOCABULARY term (Node, Module file, Edge, Port, Wave, Hat, Tier, Conditional edge, Join semantics) appears verbatim in the produced skill. No synonym substitutions.
   - **V2:** Domain-neutral substitution test — would this graph topology remain valid if node names were replaced with names from an arbitrary domain? (reasoning check)
   - **V3:** At least one aggregation Node is NOT the final emit.
   - **V4:** All aggregation Nodes have decomposition trees, synthesis strategy, Join semantics, activation conditions, and branch-budget cap declared.
   - **V7:** Wave count ≤10; every Wave has declared spawn budget AND failure_grace; total spawn budget declared; at least one Wave has attention-reset.
   - **V8 (spawn-count parity — G-07 split):**
     - **V8a:** `graph_json.metadata.spawn_node_count` == `sum(1 for n in nodes if n.exec_type=="spawn")`. FAIL if mismatch (HARD).
     - **V8b:** `graph_json.metadata.max_concurrent_spawns_per_run` ≤ HG-07 cap for the strictest applicable mode (≤7 under verbose strict-verify). FAIL if exceeded (HARD).
     - **V8c (advisory):** If brief claimed `static_spawns`, compare against both `spawn_node_count` and `max_concurrent_spawns_per_run`; log informational diff in audit_log when either differs. Non-blocking.
     - **V8d:** hats.json maps every Hat to exactly one tier; every downshiftable Hat has fallback_tier + downshift_threshold. FAIL if missing (HARD).
   - **V9:** Verbatim quote "Aggregation is the defining unlock..." appears in Section 1.5 (Aggregation Policies).
   - **V10 (residual):** Final attestation — set(node_ids) == set(filenames-without-extension). Primary check already executed by N-MODULES step 0.5; this is a confirm-only re-check on the post-emit stage outputs.
   - **V13 (residual a, b, c, e):** (a) All Nodes have 4-dimension scale gates. (b) Determinism class consistency. (c) H.7 AI-advantages floor ≥3 distinct entries. (e) Any other Section-1/2 cross-table residual sanity (note: V13(d) — graph.json node/edge ID matching — was pre-shifted to N-REGISTRY step 0.5).
   - **V11 (BLOCKING per P-003):** All INVENTORY items from constraints_digest appear verbatim in Hard Gates or module Preserved INVENTORY sections of the rendered SKILL.md (the `stages/N-SKILL-RENDER.md` content loaded in step 1). Comparison uses **whitespace-normalized substring match** (collapse runs of `\s+` to single space, trim leading/trailing whitespace). For each missing item, append `repair_target: V11; missing_inventory_item: "<verbatim text>"` to the repair_targets list. When V11 fails, also add the string `'V11'` to repair_targets — this tag triggers the back-edge E41 routing to N-SKILL-RENDER for re-render.
   - **V14 (Determinism-class match):** graph.json `metadata.determinism_class` ↔ SKILL.md `Determinism:` line match. Always required.
   - **V15 (AGG-vs-SYNTHESIS type discrimination):** All artifact-synthesis nodes have type=SYNTHESIS; all understanding-synthesis nodes have type=AGGREGATION (HC-16/AP-06 guard). Always required.
   - **V5-ext (INGEST connectivity — BLOCKING):** For every node with `type=INGEST` in graph.json: verify it appears as the `source` field in at least one edge. If any INGEST node has zero outgoing edges, the graph topology is disconnected at its entry point. Record FAIL with `halt-on-disconnected-ingest: <node_id>`. This check is always required regardless of mode. N-EDGES step 2.5(A) should have generated the missing edge upstream; if V5-ext fails, the repair target is N-EDGES.
   - **V16 (Tier-proportionality compliance):** Inline nodes ≤4000 token-budget UNLESS `hat=formatter` (then ≤16000); spawn nodes >6000 token-budget OR `spawn_budget` ≥1; HC-22 boundaries enforced. Always required.
   - **V17 (Validation-mode propagation):** When `ec-spec`/`ec-both`: stages/validation-mode.md exists before Wave 3 reads it (AP-14 guard). Required-when-precondition-holds.
   - **V18 (Zero-silent-drop on conflict_signals):** Every `conflict_signal` from Wave-3 validation branches has an explicit confirm/modify/override resolution in Design Decisions section. **No conflict_signal may be silently dropped.** Required-when-precondition-holds.
   - **V19 (residual):** When `--context` given: every node in graph.json has `context_source` in {preserved, upgraded, replaced, new} and `context_rationale`. Note: primary generation occurs in N-CONTEXT-ANALYZE step 1.5; this check is the final completeness attestation only.

2.4. **V21 (HG-04 closure — G-03).** If HG-04 (standalone-default) appears in `stages/N-CONSTRAINTS.md` inventory_items: verify that `<skill_path>/modules/kb-snippets.md` exists AND has size ≥ 1KB. If missing or empty: add `'V21'` to repair_targets with `halt-on-hg04-not-closed`; set verify_pass=false. If HG-04 is not in inventory: skip (V21 not applicable).

2.5. **V20 (dispatch-granularity — G-01).** Read `SIGNAL_STATE["dispatch_log"]` from `$SESSION_DIR/SIGNAL_STATE.json`. For each wave with `parallel_dispatch_required: true` (Wave 3: spawns N-TOPOLOGY/N-DECOMPOSE/N-CONSTRAINTS; Wave 6: spawns N-REGISTRY/N-EDGES), check that all spawn_ids for that wave appear under a single `response_id` entry in dispatch_log.
   - If dispatch_log is empty or missing the wave entry: emit advisory `"V20-advisory: dispatch_log not populated for wave <W> — HC-23 compliance unverifiable"`. Non-blocking.
   - If a wave's spawns are spread across multiple response_id entries: emit advisory `"V20-advisory: HC-23 violation at Wave <W> — spawns dispatched across <N> responses instead of 1"`. Under `--strict-dispatch` flag: promote to HARD FAIL and add `'V20'` to repair_targets with `halt-on-hc23-dispatch-violation`.
   - If a wave's spawns are all under one response_id: emit `"V20: Wave <W> dispatch-granularity PASS"`.

3. **Run H.4 four-check contract:**
   ```yaml
   checks:
     logic_check: PASS | FAIL
     validity_check: PASS | FAIL
     falsifiability_check: PASS | FAIL
     coherence_check: PASS | FAIL
   overall: PASS | FAIL
   falsifying_edge_case_attempted: <verbatim adversarial scenario>
   route: assembly | revise | discarded
   ```

4. **Determine verify_pass.** Set `verify_pass=true` if: V1, V3, V4, V5-ext, V7, V8, V9, V10, V11, V13(a,b,c,e) all PASS AND H.4 overall = PASS AND V14, V15, V16 all PASS. V2 remains advisory (non-blocking). V11 is BLOCKING per P-003. V5-ext is BLOCKING (disconnected INGEST topology). V17/V18 required when validation_mode was true. V19 required when --context was given. When `verify_pass=false` AND `'V11' in repair_targets` AND `retry_count_artifact < 1`: back-edge E41 (N-VERIFY→N-SKILL-RENDER) fires in addition to E27 — N-SKILL-RENDER re-renders SKILL.md before N-MODULES re-runs.

**E50/E51 routing (v4 DD-06):** These back-edges route to N-AGG-DESIGN for design-level failures caught during N-VERIFY's attestation of upstream stage files:
- If V13(d) anomalies are detected in `stages/N-REGISTRY.md` (node/edge ID mismatch that N-REGISTRY step 0.5 should have caught): add `'registry_v13d_fail'` to repair_targets → triggers E50 (N-VERIFY→N-AGG-DESIGN).
- If early-V edge failures are detected in `stages/N-EDGES.md` (V5/V12 issues that N-EDGES step 2.5 should have caught): add `'edges_early_v_fail'` to repair_targets → triggers E51 (N-VERIFY→N-AGG-DESIGN).
- **De-dup rule:** if BOTH `'registry_v13d_fail'` AND `'edges_early_v_fail'` are in repair_targets simultaneously, fire **only E50** — include both repair notes in the E50 payload, skip E51 to prevent double N-AGG-DESIGN dispatch in the same retry cycle.

5. **Write output** to `stages/N-VERIFY.md`:
   ```
   ## v_battery_results
   <table: check | result | notes>

   ## h4_contract
   <yaml block>

   ## verify_pass
   <true|false>

   ## repair_targets
   <list of failing checks with specific fix instructions — used by back-edge repair>
   ```

6. **Append machine-readable verdict block** at the end of `stages/N-VERIFY.md`:
   ```json
   {
     "verdict": "PASS",
     "failed_checks": [],
     "retry_count": 0
   }
   ```
   Set `verdict` to `"PASS"` or `"FAIL"` matching `verify_pass`. List all failing check IDs (e.g. `["V13", "V3"]`) in `failed_checks`. This block enables reliable E21/E21b routing without regex over prose.

   Emit signals: `verify_pass` (boolean), `verify_result`.

## Scale gates
- tokens: 12000
- time: 900s
- spawns: 2
- retries: 1

## Failure modes
- timeout: retry once; on second timeout set verify_pass=false with advisory
- malformed output: re-run step 5 only; preserve battery results
- missing input: HALT with name of missing signal
- format-mismatch on Edge: re-read stage files directly by path

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-VERIFY
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational — note: when N-VERIFY itself emits a degradation_notice, the orchestrator surfaces it directly to the user since there is no downstream verifier).
