# Behavioral Fusion Tests — Scaffold (v4.3 Phase 4 deferred-completion)

Per spec §6.2, GOTSCS v4.3 defines 12 FUSION-* acceptance tests that exercise the evolve-mode pipeline end-to-end (running GOTSCS on a brief + spec + skill triple and inspecting the produced FUSION.md / RATIONALE.md / SKILL.md). The structural assertions for these contracts are already in `tests/run-smoke-tests.sh` (FUSION-01..12 grep-based contract checks). This directory is the **behavioral** layer — actually running GOTSCS in evolve mode and verifying output.

## Status: SCAFFOLD ONLY

The behavioral harness is **not wired up** in v4.3.0. The pieces below are placeholders for a future Phase 5 (or external CI harness) that has access to:

1. A way to invoke `claude --skill gotscs "<brief>" --context <skill> --context-spec <spec> --evolve` programmatically
2. A staging directory for produced skills
3. Assertions that can `cd <produced-skill> && bash tests/run-smoke-tests.sh`

Until that exists, the smoke-test contracts (`tests/run-smoke-tests.sh` lines for FUSION-01..12) are the authoritative coverage. They verify that the pipeline DECLARES the correct behavior; behavioral tests verify the pipeline EXHIBITS that behavior.

## Fixture Directory Layout (planned)

```
tests/behavioral-fusion/
├── README.md                          (this file)
├── run-fusion-acceptance.sh           (TODO — invokes claude CLI on each fixture)
├── fixtures/
│   ├── F01-brief-overrides-original/  (FUSION-01)
│   │   ├── brief.txt                  (asks: "redesign N-FORMATTER as AGGREGATOR")
│   │   ├── original-skill/            (minimal skill with N-FORMATTER as FORMATTER)
│   │   └── expected.yaml              (assertions: divergence_map contains N-FORMATTER, authority=brief)
│   ├── F02-spec-overrides-original/   (FUSION-02)
│   │   ├── brief.txt                  (silent on N-VERIFIER)
│   │   ├── original-skill/            (skill with N-VERIFIER 7 checks)
│   │   ├── enhancement-spec.md        (adds 2 new checks to N-VERIFIER)
│   │   └── expected.yaml              (N-VERIFIER has 9 checks, authority=spec)
│   ├── F03-original-informs-when-silent/
│   ├── F04-fusion-md-emitted/         (verify FUSION.md exists and has 10 sections)
│   ├── F05-redesign-candidate-flagged/
│   ├── F06-preservation-map-accurate/
│   ├── F07-divergence-justified/
│   ├── F08-risk-assessment-included/
│   ├── F09-hc02-caps-respected/       (--evolve without --evolve-aggressive)
│   ├── F10-hc02-caps-relaxed/         (--evolve-aggressive with waiver)
│   ├── F11-functional-contract-preserved/
│   └── F12-regression-battery-passes/
```

## Acceptance Criteria (per spec §6.2)

Each fixture's `expected.yaml` should encode the spec §6.2 acceptance criterion verbatim. Example for F01:

```yaml
test_id: FUSION-01
description: "Brief overrides original skill"
given:
  original_skill_has_node:
    id: N-FORMATTER
    type: FORMATTER
  brief_demand: "redesign N-FORMATTER as AGGREGATOR"
then:
  fusion_plan.preservation_map:
    must_not_contain: N-FORMATTER
  fusion_plan.divergence_map:
    must_contain:
      node_id: N-FORMATTER
      authority: brief
```

## Wiring it up (Phase 5 or external)

The harness shell (`run-fusion-acceptance.sh`, TODO) would loop over fixtures:

1. Stage a temporary working dir
2. Run `claude --skill gotscs "$(cat brief.txt)" --context original-skill/ [--context-spec enhancement-spec.md] --evolve [--evolve-aggressive --waiver-justification "..."]`
3. Parse the produced `<skill>/FUSION.md` and `<skill>/SKILL.md`
4. Apply assertions from `expected.yaml`
5. Tally pass/fail; exit non-zero on any failure

Until the CLI/Claude-Code invocation surface for skills is stable enough for programmatic invocation in CI, this directory remains a documentation-only scaffold. The structural smoke tests in the parent directory provide the contract-level coverage.
