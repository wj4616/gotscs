---
node_id: N-WAVES
node_type: PLANNER
hat: analyzer
exec_type: inline
tier: model-medium
scale_gates: {token_budget: 3000, time_budget: 300, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: design_blueprint
    format: markdown
    signal_field: design_blueprint
    required: true
    source: N-DESIGN-GATE.md  # passthrough from N-AGG-DESIGN via Wave-5 gate
output_ports:
  - port: waves_result
    format: markdown
    signal_field: waves_result
raises_signals: [waves_result]
required_output_sections: [wave_plan_table, mode_matrix_table]
---

## INPUT ports
- design_blueprint: markdown (signal_field: design_blueprint, source: stages/N-DESIGN-GATE.md passthrough — see N-DESIGN-GATE step 5b)

## OUTPUT ports
- waves_result: markdown  (signal_field: waves_result)

## AI advantages exploited
- consistency_at_scale  # correct budget arithmetic across all waves simultaneously

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-WAVES: briefing-core only. No appendices required. -->

1. **Read design_blueprint** from `stages/N-DESIGN-GATE.md` (the passthrough section appended by N-DESIGN-GATE step 5b — the blueprint is forwarded unchanged after gate evaluation; the gate_pass field at the top of N-DESIGN-GATE.md is the gate verdict, the design_blueprint passthrough section below is the data payload). Extract node list with wave assignments.

2. **Generate Section 4 — Wave Plan table.** Cap at ≤10 Waves. Columns:
   `Wave # | Nodes | type (fan-out/aggregation/sequential) | spawn budget | cumulative spawn budget | wall-clock target | failure_grace | attention-reset Read inserted? | depends-on Wave`

   Rules:
   - Per-Wave spawn budget: equal split across nodes in wave. `floor(wave_spawn / nodes_in_wave)`. Leftover → Wave reserve.
   - failure_grace: default 0 (fail fast). Override only for aggregation Waves where partial results are acceptable.
   - attention-reset Read: insert before any Wave containing an aggregation node, and before Wave 1.
   - depends-on Wave: blank for standard sequential; list for non-sequential dependencies.
   - Total spawn budget: sum all per-Wave budgets. Document if > 30 (soft cap).

   **Token budget derivation (P-6 / cross-artifact alignment).** When computing per-wave token budget totals, derive node token_budget values from `stages/N-REGISTRY.md` (the authoritative source, which will match graph.json) rather than re-deriving from the design_blueprint independently. If N-REGISTRY is not yet available at N-WAVES execution time, mark per-wave token budgets as `ESTIMATED` and add a reconciliation note: `"token_budget_source: estimated — reconcile with N-REGISTRY/graph.json after N-JSON completes"`. This prevents cross-artifact drift where N-WAVES claims different token budgets than graph.json scale_gates values.

3. **Generate Section 3 — Mode Matrix table.** Columns:
   `mode | active Waves | spawn budget | Tier downshifts | latency target | inactive edge IDs`

   Modes: MINIMAL, STANDARD, DEEP.
   - MINIMAL: All Waves (pipeline topology is non-skippable — every wave's output is a required input for the next). All `downshiftable: true` Hats downshifted to fallback tier. Spawn budgets halved (floor). Inactive edge IDs: none.
   - STANDARD: All Waves; no downshifts.
   - DEEP: All Waves; static spawn budget = same as STANDARD (from graph.json). **Do NOT label the DEEP spawn budget as `N × 1.5` of the STANDARD value.** The 1.5× figure is a maximum theoretical ceiling only: BE-1 back-edge re-fires (at cap=2) may trigger up to `floor(spawn_nodes × 0.5)` additional sub-spawns at runtime, but these are not part of the static graph spawn budget. The Mode Matrix MUST show the static graph spawn budget (matches graph.json metadata) with a footnote: `"+ up to N BE-1 re-fires possible at runtime (cap ×2 in --deep mode)"`. Conflating static and dynamic spawn counts creates §3/§4 coherence failures.

4. **Wave count guard (EC8).** If total Waves > 10: apply EC8 pruning per design_blueprint pruning list. Document each pruning step.

5. **Write output** to `stages/N-WAVES.md`. Emit signal: `waves_result`.

## Scale gates
- tokens: 3000
- time: 300s
- spawns: 0
- retries: 1

## Failure modes
- timeout: retry once; emit minimal wave plan (MINIMAL mode only)
- malformed output: re-run step 5 only
- missing input: HALT "N-WAVES: design_blueprint missing"
- format-mismatch on Edge: re-read stages/N-DESIGN-GATE.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-WAVES
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
