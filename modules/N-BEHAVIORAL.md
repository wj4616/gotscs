---
node_id: N-BEHAVIORAL
node_type: VERIFIER
hat: verifier
exec_type: spawn
tier: model-large
conditional: true
mode_gate: "BEHAVIORAL_TEST == 'true' AND MODE in ['skill','both']"
scale_gates: {token_budget: 12000, time_budget: 600, spawn_budget: 1, retry_budget: 0}
input_ports:
  - port: emit_complete
    format: bool
    signal_field: emit_complete
    required: true
  - port: skill_path
    format: text
    signal_field: skill_path
    required: true
  - port: normalize_digest
    format: markdown
    signal_field: normalize_digest
    required: true
output_ports:
  - port: behavioral_result
    format: markdown
    signal_field: behavioral_result
  - port: behavioral_pass
    format: bool
    signal_field: behavioral_pass
raises_signals: [behavioral_result, behavioral_pass]
required_output_sections: [fixture_synthesized, run_log, structural_checks, behavioral_pass]
---

## INPUT ports
- emit_complete: bool (signal_field: emit_complete — must be true; fires only after N-EMIT confirms successful emission)
- skill_path: text (signal_field: skill_path — absolute path to the produced skill directory from N-EMIT)
- normalize_digest: markdown (signal_field: normalize_digest — used to synthesize a representative input fixture)

## OUTPUT ports
- behavioral_result: markdown (signal_field: behavioral_result — fixture, run log, structural checks, advisory verdict)
- behavioral_pass: bool (signal_field: behavioral_pass — true iff the produced skill ran without halting AND output matches expected output_shape per normalize_digest)

## AI advantages exploited
- multi_perspective_simulation  # synthesize a minimal but representative input fixture by simulating an end-user invocation
- consistency_at_scale          # apply identical structural-output checks every run

## Conditional firing (P-006)

This node fires ONLY when both conditions hold:
1. `BEHAVIORAL_TEST == 'true'` (set by orchestrator from `--behavioral-test` flag at STEP 0.1)
2. `MODE in ['skill','both']` (no skill artifact exists when MODE=spec)

When either condition is false: N-BEHAVIORAL is skipped entirely; pipeline terminates at E29 (N-EMIT → SKILL_OUTPUT) as in v3.0.0.

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-BEHAVIORAL: briefing-core only. No appendices required. -->

1. **Confirm precondition.** Read `stages/N-EMIT.md`. Confirm `emit_complete=true` and `skill_path` is set. If not: HALT with "N-BEHAVIORAL: cannot run without successful emission".

2. **Synthesize fixture from normalize_digest.** Read `stages/N-NORMALIZE.md`. Extract `input_shape` and `success_criteria`. Generate a minimal-but-representative input fixture for the produced skill:
   - **input_shape="code-review-text"** → 3-comment fixture: one bug-fix comment, one nit/style comment, one cross-reviewer duplicate
   - **input_shape="free-text-prompt"** → a single 1-sentence prompt covering the domain (e.g., "Summarize this article: [synthetic 5-sentence article]")
   - **input_shape="structured-json"** → a 5-key JSON object covering the schema described in the digest
   - **other** → emit advisory `fixture_synthesis_failed` and skip steps 3-4; report `behavioral_pass=null` (advisory-only result; not a fail).
   Write the fixture to `stages/behavioral-fixture.txt`.

3. **Run the produced skill against the fixture.** Spawn a subagent that:
   - Reads `<skill_path>/SKILL.md`
   - Loads the fixture from `stages/behavioral-fixture.txt`
   - Executes the produced skill's pipeline as a fresh invocation
   - Captures the final output to `stages/behavioral-output.txt`
   - Reports any HALT or refusal as a structural failure
   ```
   Agent(description="N-BEHAVIORAL: run produced skill against synthesized fixture",
     prompt="You are running a behavioral acceptance test for the produced skill at <skill_path>.
   Read <skill_path>/SKILL.md.
   The fixture input is at <session_dir>/stages/behavioral-fixture.txt — treat its content as the user's input.
   Execute the skill's pipeline. Capture any HALT, refusal, or error to <session_dir>/stages/behavioral-output.txt with header '## HALT/ERROR'.
   On success, write the final_output to <session_dir>/stages/behavioral-output.txt with header '## SKILL_OUTPUT'.")
   ```

4. **Run structural checks on the captured output.** Per `success_criteria` from normalize_digest:
   - **Output is non-empty** (file exists, > 0 bytes).
   - **Output matches expected output_shape format** — e.g., for `output_shape="action-item-list"`: at least one `### ` or `- ` markdown list item present.
   - **Each declared success_criterion** that can be checked syntactically (e.g., "items sortable by priority" → output contains "critical|major|minor" tier markers): record PASS/FAIL.
   - **No HALT in the run log.**

5. **Compute behavioral_pass.** Set `true` iff:
   - Step 3 produced output without HALT, AND
   - Step 4 structural checks all PASS.
   Otherwise `false`. **Note:** behavioral_pass is INFORMATIONAL — it does not block the produced skill from being shipped (the artifact at `<skill_path>/` already exists and was already verified by N-VERIFY V1-V19). N-BEHAVIORAL is a runtime sanity check, not a gate.

6. **Write output** to `stages/N-BEHAVIORAL.md`:
   ```markdown
   ## fixture_synthesized
   <verbatim fixture text or "fixture_synthesis_failed: <reason>">

   ## run_log
   <captured stages/behavioral-output.txt content>

   ## structural_checks
   | criterion | result | notes |
   |---|---|---|
   ...

   ## behavioral_pass
   <true | false | null (when fixture-synthesis failed)>

   ## advisory
   <human-readable summary; what worked, what didn't; recommendations for the produced skill author>
   ```
   Emit signals: `behavioral_result`, `behavioral_pass`.

## Adversarial test note (P-006 limitation)

Skills whose input is hard to synthesize (binary firmware, proprietary formats, domain-specific DSLs not described in normalize_digest) will hit step 2's `fixture_synthesis_failed` branch. In that case N-BEHAVIORAL emits an advisory-only result and does not falsely report PASS or FAIL. This is documented as an inherent limitation.

## Scale gates
- tokens: 12000
- time: 600s
- spawns: 1
- retries: 0 (behavioral runs are not idempotent — a retry could hide nondeterministic skill bugs; one shot only)

## Failure modes
- timeout: emit advisory "behavioral run timed out at <stage>"; behavioral_pass=null
- malformed output (skill produced output but it's not parseable): record FAIL with diagnostic; behavioral_pass=false
- missing input: HALT "N-BEHAVIORAL: emit_complete or skill_path missing"
- format-mismatch on Edge: re-read stages/N-EMIT.md directly

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-BEHAVIORAL
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
