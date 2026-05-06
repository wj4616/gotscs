# briefing-appendix-antipatterns — H.8 Anti-Pattern List (segregated)

Loaded by: N-CONSTRAINTS, N-AGG-DESIGN (and N-VERIFY's full-appendix load).

## H.8 Anti-Pattern List (segregated)

Source: `03_aggregation.md` D.3 + `05_design_knowledge.md` G.8. Each anti-pattern names its source node_id(s).

- **AP-S1** silent-quality-drift — N-1 (cut IV1 differential test)
- **AP-T1** documentary-only-metadata (`hat`/`tier` declared but not consumed) — N-1, N-3, N-8
- **AP-D1** dead-letter-back-edge (late back-edge fires but target does not re-execute) — N-1, N-9
- **AP-D2** budget-tightness-without-slack (DEEP+expansion at 86% of budget) — N-3
- **AP-D3** uncalibrated-heuristic-constants (S1 formula, "N" thresholds) — N-3, N-8
- **AP-V1** spec-sprawl-without-test-coverage — N-2, N-13
- **AP-V2** probabilistic-determinism-claim (≥80% set-overlap as production gate) — N-2
- **AP-V3** cost-aware-safety-skip-on-small-cases (Pass B skipped on <5 findings) — N-2
- **AP-V4** diagram-vs-edge-table-drift (ASCII art, missing E12) — N-4
- **AP-V5** advisory-without-actuation (wall-clock soft target emits warning, no downscale) — N-4
- **AP-V6** cascade-without-degradation (single failure halts whole pipeline) — N-4, N-12
- **AP-V7** contradiction-deferral-without-canonicalization (T13 escape hatch) — N-5
- **AP-V8** spawn-count-headline-vs-actual (5/4/2 advertised, 9/8/2 actual) — N-5, N-12
- **AP-V9** aliased-signal-field-drift (falsification_result vs falsification_digest) — N-5
- **AP-V10** mode-flag-combinatorial-undercover — N-6
- **AP-V11** trivially-satisfiable-termination-gate (≥3/6 with overlapping dimensions) — N-6, N-9
- **AP-V12** placeholder-vs-populated-double-write — N-6
- **AP-V13** budget-without-fan-out-policy — N-7, N-9
- **AP-V14** cap-applies-only-to-explicit-mode (80k cap mentioned only in --deep) — N-7
- **AP-V15** feature-shipped-without-metric (CROSS-RUN SEED similarity undefined; --spec/--plan deferred) — N-8, N-14
- **AP-V16** vocabulary-lock-with-typos (`at leastt`, `specifcation`) — N-8
- **AP-V17** out-of-scope-coverage-leak (Phase 12 plan-coverage when plan is non-goal) — N-8
- **AP-V18** hardcoded-path-vs-actual-location (~/.claude/skills/ baked into convention) — N-9
- **AP-V19** version-marker-without-content-delta (epiphany-audit-v2 byte-identical to v1) — N-10
- **AP-V20** hard-floor-equals-typical-score (two-axis ≥7 floor coincides with calibrated minimum) — N-10
- **AP-V21** permissive-schema-misses-typo (graph.schema.json no enum on `type`) — N-10
- **AP-V22** clean-lens-not-mechanically-enforced (Pass B subagent could be same model) — N-10
- **AP-V23** digest-size-unbounded-under-scale — N-11
- **AP-V24** documentary-frontmatter-vs-canonical-graph — N-11
- **AP-V25** single-firing-cap-for-multi-class-trigger (E26 fires once for multi-class thin-spots) — N-11
- **AP-V26** post-hoc-budget-enforcement (PRA1 runs after spawn overrun) — N-12
- **AP-V27** source-of-truth-contradiction (SKILL.md says read X from graph.json which lacks X) — N-13
- **AP-V28** halt-classification-self-contradiction (inventory:terminating vs prose:downgrade) — N-13
- **AP-V29** runtime-rewrites-not-in-static-graph (D1/D2/D3 dynamic edges absent from graph.json) — N-13
- **AP-V30** documentation-surface-area-overhead (~600KB) — N-14
- **AP-V31** logical-parallel-vs-runtime-parallel (PG3 named parallel but sequential) — N-14

Counter-patterns are listed in `05_design_knowledge.md` Section G.8 alongside each anti-pattern.

