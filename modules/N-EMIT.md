---
node_id: N-EMIT
node_type: PERSISTER
hat: persister
exec_type: inline
tier: model-small
scale_gates: {token_budget: 2000, time_budget: 120, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: verify_result
    format: markdown
    signal_field: verify_pass
    required: true
  - port: rendered_skill_md
    format: markdown
    signal_field: skill_render_result
    required: true
output_ports:
  - port: emit_complete
    format: text
    signal_field: emit_complete
raises_signals: [emit_complete]
required_output_sections: [files_written, skill_path]
---

## INPUT ports
- verify_result: markdown  (signal_field: verify_pass — must be true)
- rendered_skill_md: markdown  (signal_field: skill_render_result — pre-assembled SKILL.md content from N-SKILL-RENDER (P-002); copied verbatim in step 4 via `cp`)

## OUTPUT ports
- emit_complete: text  (signal_field: emit_complete)

## AI advantages exploited
- consistency_at_scale  # deterministic file assembly from all stage outputs

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-EMIT: briefing-core only. No appendices required. -->

1. **Confirm verify_pass=true.** Read `stages/N-VERIFY.md`. If `verify_pass=false`: do not write files. Emit `emit_complete=false`. Signal to orchestrator for back-edge repair.

2. **Read all stage outputs.** Collect:
   - `stages/N-MODULES.md` → thin module index manifest (actual module content in `stages/modules/*.md`)
   - `stages/N-JSON.md` → graph.json and hats.json content
   - `stages/N-SKILL-RENDER.md` → pre-assembled SKILL.md content (P-002; N-SYNTH-GRAPH data already embedded)
   - `stages/N-NORMALIZE.md` → skill name (from domain field)

3. **Determine output path.** Use `skill_name` from normalize_digest. Apply the canonical 4-step slugify (identical to N-SPEC-ARTIFACT step 2): (1) lowercase, (2) replace any character outside `[a-z0-9-]` with `-`, (3) collapse runs of consecutive `-` into a single `-`, (4) strip leading/trailing `-`. Output path: `<session_output_base>/<skill_name>/`. Create directory.

3a. **Output-path collision check (F-2.6 fix — Rank-5 audit finding).** Before creating the directory, detect collision with `--context` or `--context-spec` inputs:

```bash
SKILL_PATH="$session_output_base/$skill_slug"
COLLISION=""
if [[ -n "${CONTEXT_PATH:-}" ]] && [[ "$SKILL_PATH" == "$CONTEXT_PATH" ]]; then
  COLLISION="--context input"
elif [[ -n "${CONTEXT_PATH:-}" ]] && [[ "$CONTEXT_PATH" == "$SKILL_PATH"/* ]]; then
  COLLISION="strict ancestor of --context input"
elif [[ -n "${CONTEXT_SPEC_PATH:-}" ]] && [[ "$(dirname "$CONTEXT_SPEC_PATH")" == "$SKILL_PATH" ]]; then
  COLLISION="parent dir of --context-spec file"
fi

if [[ -n "$COLLISION" ]]; then
  if [[ "${ALLOW_CONTEXT_OVERWRITE:-false}" == "true" ]]; then
    echo "WARN: emit path '$SKILL_PATH' collides with $COLLISION; --allow-context-overwrite=true → proceeding (may destroy input)" >&2
  else
    echo "halt-on-output-path-collision-with-context: emit path '$SKILL_PATH' collides with $COLLISION." >&2
    echo "Suggest: use a versioned suffix like '<skill_slug>-v1.0.0-production', or set ALLOW_CONTEXT_OVERWRITE=true to deliberately overwrite the input." >&2
    # Auto-suffix recovery: if normalize_digest carries a `version` field, use it; else use ISO date
    AUTO_SUFFIX="$(grep -E '^version:' "$session_dir/stages/N-NORMALIZE.md" | awk '{print $2}' | tr -d '"' | head -1)"
    [[ -z "$AUTO_SUFFIX" ]] && AUTO_SUFFIX="$(date +%Y%m%d)"
    SKILL_PATH="${SKILL_PATH}-v${AUTO_SUFFIX}"
    echo "Auto-suffixing to: $SKILL_PATH" >&2
  fi
fi
```

This eliminates the F-2.6 destructive-overwrite class. The `--allow-context-overwrite` opt-in admits the legitimate "rebuild over previous version" workflow.

**Adversarial check:** a user could deliberately collide paths to destroy --context input. The default-HALT + opt-in flag forces an explicit choice. The auto-suffix fallback path preserves the input even when ALLOW_CONTEXT_OVERWRITE is unset.

4. **Write files using the section-to-source assembly table:**

   | Output file / section | Source stage | Operation |
   |---|---|---|
   | `<skill>/SKILL.md` (full document) | **N-SKILL-RENDER stage** (P-002) | `cp stages/N-SKILL-RENDER.md <skill>/SKILL.md` — already assembled with §0–§7 + Appendix A by the dedicated renderer |
   | `<skill>/graph.json` | N-JSON stage | extract `graph_json_content` JSON code block |
   | `<skill>/hats.json` | N-JSON stage | extract `hats_json_content` JSON code block |
   | `<skill>/modules/<node_id>.md` | **N-MODULES stages/modules/ outputs** (P-001) | `cp stages/modules/*.md <skill>/modules/` — one file per node, no parsing |
   | `<skill>/briefing-core.md` | GOTSCS own briefing (P0-5) | `cp ~/.claude/skills/gotscs/briefing-core.md <skill>/briefing-core.md` — modules reference this file in step 0; without it spawn agents cannot load schema vocabulary |
   | `<skill>/graph.schema.json` | **N-JSON stage** `generated_schema_content` (F-2.4 fix — Rank-2) | extract `generated_schema_content` JSON code block from `stages/N-JSON.md`. **DO NOT** copy `~/.claude/skills/gotscs/graph.schema.json` directly — that schema fits GOTSCS's own graph and rejects produced skills with domain-specific hats (e.g., `classifier`, `scorer`, `refiner`, `recovery`) or hyphenated edge IDs (e.g., `E-05b`). The per-skill schema generated by N-JSON step 1.5(f) is a strict superset of the GOTSCS base, derived from the actual produced graph's vocabulary. **Fallback** (compatibility path for older sessions where N-JSON did not emit `generated_schema_content`): copy GOTSCS's default with a `degradation_notice: schema-fallback` warning logged on N-EMIT's stage file, NOT silently suppressed. |
   | `<skill>/tests/run-smoke-tests.sh` | GOTSCS own test harness | adapted with target skill's node count, edge count, conditional count |
   | `<skill>/tests/behavioral/EC2-minimal-brief.txt` | generated template | minimal valid brief (no flags) for EC2 smoke path |
   | `<skill>/tests/behavioral/EC4-contradictory-brief.txt` | generated template | brief with two explicit contradictory constraints for EC4 path |
   | `<skill>/tests/behavioral/EC15-refeed-brief.txt` | generated template | prior skill output content for ec-refeed path |
   | `<skill>/tests/behavioral/run-behavioral-tests.sh` | generated scaffold | invoke skill with each EC template input; verify structural properties of output |

   **Per-file emission contract (P-001):** N-MODULES (Wave 9) writes one file per node to `stages/modules/<node_id>.md`. N-EMIT here MUST NOT parse a monolithic manifest — it copies the per-file outputs directly. This eliminates the F-001 leakage class entirely.

   **Pre-rendered SKILL.md contract (P-002):** N-SKILL-RENDER (Wave 9) assembles the full SKILL.md into `stages/N-SKILL-RENDER.md` with all 11 sections (§0 HARD GATES from N-CONSTRAINTS inventory_items verbatim; §0 ARCHITECTURE / §5 / §5.5 / §6 / §7 from N-SYNTH-GRAPH graph_spec; §1 / §1.5 from N-REGISTRY; §2 from N-EDGES; §3 / §4 from N-WAVES; Appendix A from briefing-core.md verbatim). N-EMIT here MUST NOT re-render — it copies the pre-rendered file. This eliminates the F-002/F-003/F-009 class.

   For `tests/run-smoke-tests.sh`: generate with structural checks (file existence, JSON validity, node count, edge count, ai_advantages presence, frontmatter, V16 compliance, V8 downshift_threshold, V19 context_source when --context was used). The behavioral stubs from prior versions are now replaced by the `tests/behavioral/` scaffold — `run-smoke-tests.sh` should reference them: `echo "Run tests/behavioral/run-behavioral-tests.sh for EC2/EC4/EC15 acceptance coverage."`.

   For `tests/behavioral/`: generate four files:
   - `EC2-minimal-brief.txt`: a one-sentence brief with no flags — exercises the minimal happy path.
   - `EC4-contradictory-brief.txt`: a brief containing two explicit contradictory constraints (e.g., "must be synchronous" vs. "must support async operations") — exercises `[CONTRADICTION-A/B]` handling.
   - `EC15-refeed-brief.txt`: a dummy skill SKILL.md stub (just frontmatter + name line) — exercises ec-refeed node-name preservation.
   - `run-behavioral-tests.sh`: scaffold shell script that invokes the skill with each template input and checks for structural properties in the output (e.g., for EC2: output file created; for EC4: output contains "CONTRADICTION"; for EC15: node names from stub preserved). Mark complex assertions as `# TODO: tighten after first manual run`.

   **Determinism-invariant test (F-3.3 fix — Rank-8 audit finding).** When the produced skill's INVENTORY contains any `[DETERMINISM-*]`-tagged constraint (e.g., `[DETERMINISM-WHITESPACE-INVARIANT]`), additionally generate `<skill>/tests/determinism-property-test.sh`:

   ```bash
   #!/usr/bin/env bash
   # Determinism property test for the produced skill.
   # Invokes the skill 5× on identical input + 1× on a whitespace-perturbed copy of the
   # same input, then asserts semantic equality of the outputs. Skill is non-deterministic
   # by frontmatter (determinism_class: non-deterministic) so the test is TOLERANCE-based:
   # require ≥4/5 identical-input runs to be byte-equal in their YAML frontmatter and
   # ## Effective Instructions body, and the whitespace-perturbed run to differ only in
   # whitespace-equivalent ways from a canonical run.
   #
   # Marked TODO: tighten after first manual run when the skill has a CLI runner.
   set -euo pipefail
   echo "DETERMINISM PROPERTY TEST — adaptive-context-pruner"
   echo "TODO: implement after CLI runner is available; currently a scaffold."
   echo "Expected behavior:"
   echo "  Run 1-5: identical input → ≥4/5 byte-equal in frontmatter + ## Effective Instructions"
   echo "  Run 6:   whitespace-perturbed input → differs only in whitespace-equivalent positions"
   exit 0  # advisory until CLI runner exists
   ```

   The test is **advisory** until the produced skill has a programmatic invocation harness; mark with `# TODO: tighten after first manual run`. **Do NOT generate the determinism test when no `[DETERMINISM-*]` constraint is in the produced skill's INVENTORY** — generating it for a skill that doesn't claim determinism creates noise.

4c. **Post-emit smoke test (P-004 — required gate).** After all files are written but before reporting `emit_complete=true`, run the produced skill's own smoke test against the post-emit artifacts:
   ```bash
   bash <skill_path>/tests/run-smoke-tests.sh
   POST_EMIT_RESULT=$?
   ```
   AND run GOTSCS's `validate-graph.sh --target` (P-008) against the produced graph.json — **graceful fallback if script absent**:
   ```bash
   VALIDATE_SCRIPT=~/.claude/skills/gotscs/scripts/validate-graph.sh
   if [[ -f "$VALIDATE_SCRIPT" ]]; then
     bash "$VALIDATE_SCRIPT" --target "<skill_path>" \
       --expect-nodes <node_count> --expect-edges <edge_count>
     GRAPH_VALIDATE_RESULT=$?
     # F-2.3 fix (Rank-3 audit finding): bundle schema-validate as an additional gate.
     # The smoke test does NOT include closed-vocab schema validation by default; without
     # this gate, F-2.3 / F-2.4 class failures (e.g., tier="n/a", undocumented hat) escape
     # to manual post-hoc detection. Schema-validate against the per-skill schema generated
     # by N-JSON step 1.5(f) and copied to <skill>/graph.schema.json by step 4 above.
     bash "$VALIDATE_SCRIPT" --target "<skill_path>" --schema-validate
     SCHEMA_VALIDATE_RESULT=$?
   else
     echo "ADVISORY: validate-graph.sh not found at $VALIDATE_SCRIPT; --target check skipped."
     echo "Install GOTSCS scripts to enable full graph schema validation."
     GRAPH_VALIDATE_RESULT=0       # non-blocking when script absent
     SCHEMA_VALIDATE_RESULT=0      # non-blocking when script absent
   fi
   ```
   AND verify per-file emission integrity (P-001 sanity check):
   ```bash
   for f in <skill_path>/modules/*.md; do
     # Each file must have exactly 1 ^node_id: line and no <!-- MODULE: --> markers
     test "$(grep -c '^node_id:' "$f")" -eq 1 || { echo "POST-EMIT FAIL: $f has ≠1 node_id frontmatter"; exit 7; }
     test "$(grep -c '<!-- MODULE: modules/' "$f")" -eq 0 || { echo "POST-EMIT FAIL: $f has cross-module leakage marker"; exit 7; }
   done
   ```
   - If ALL FOUR pass (POST_EMIT_RESULT, GRAPH_VALIDATE_RESULT, SCHEMA_VALIDATE_RESULT, per-file integrity loop): continue to step 5; emit_complete=true.
   - If any fail AND `retry_count_artifact < 1`: route the back-edge by failure source:
     - **module-leakage failures** (per-file integrity loop OR POST_EMIT_RESULT structural failures) → **E35 (N-EMIT→N-MODULES)**
     - **SKILL.md content failures** (V11 substring fail surfacing post-emit, or §0/§1/§7 structural drift) → **E36 (N-EMIT→N-SKILL-RENDER)**
     - **graph.json schema failures** (SCHEMA_VALIDATE_RESULT≠0 — e.g., tier `n/a`, undocumented hat, malformed edge id) → **E37 (N-EMIT→N-JSON)** (NEW — added by F-2.3/F-2.4 Rank-2/3 fix). Increment `retry_count_artifact`. N-JSON re-runs steps 1.5(c2)+(c3)+(f) which auto-correct tier-no-llm and regenerate the per-skill schema; N-EMIT re-attempts.
     - **graph.json metadata mismatch** (computed totals disagree with claimed totals after N-JSON re-run) → **E37 (N-EMIT→N-JSON)** as above; the metadata override in N-JSON step 1.5(c3) is unconditional, so re-run will produce the corrected file.
     Increment `retry_count_artifact` via sync-signal.sh. Re-run the routed upstream node. Re-attempt N-EMIT.
   - If any fail AND `retry_count_artifact >= 1`: emit_complete=false; surface partial skill with diagnostic listing every failed check. Pipeline reports HALT with `halt-on-post-emit-validation-fail`.

5.5. **Emit runtime-delivery note (G-05 — HARNESS-NOTE.md).** Write `<skill_path>/tests/HARNESS-NOTE.md` with the following content (substituting actual skill name and node count):

```markdown
# HARNESS-NOTE — <skill_name> runtime delivery model

This skill is a **Claude-Code-class skill**. Invocation: trigger via Claude Code's
Skill tool (slash command or Skill tool call). The SKILL.md is the execution contract;
no compiled binary or standalone runner exists.

## Smoke tests

`tests/run-smoke-tests.sh` uses a stub `invoke_skill()` function that returns canned
strings. It validates static structure (file existence, JSON validity, node count,
edge count) but cannot test real behavior.

To test real behavior: invoke the skill through Claude Code's Skill tool with a
representative brief and inspect the output against the V-battery criteria.

## Scripts

Scripts in `scripts/` (bash, python) are utility helpers runnable by Claude Code's
Bash tool. They are not the primary invocation harness.

## Integration path

1. Install: `cp -r <skill_path> ~/.claude/skills/<skill_name>/`
2. Invoke: `/skill-name --skill "<your brief>"`
3. Real behavior tests: use `tests/behavioral/run-behavioral-tests.sh` (requires
   Claude Code as the runner — see TODO comments in that file).
```

5. **Report to user.** Write `stages/N-EMIT.md`:
   ```
   ## files_written
   <list: path | size_lines>

   ## skill_path
   <absolute path to written skill>

   ## next_steps
   - Review the skill at <path>
   - Install with: cp -r <path> ~/.claude/skills/<skill_name>/
   - Run validation: <path>/tests/run-smoke-tests.sh
   ```
   Emit signal: `emit_complete=true`.

## Scale gates
- tokens: 2000
- time: 120s
- spawns: 0
- retries: 1   # P-004 post-emit smoke test fires E35/E36 retry back-edges with retry_count_artifact < 1

## Failure modes
- timeout: N/A (file writes are fast)
- malformed output: re-run step 5 only
- missing input: if verify_pass missing, treat as false
- format-mismatch on Edge: not applicable (reads from session files directly)
- smoke_test_fail: P-004 smoke test exits non-zero after emit; set `emit_complete=false`; append `repair_targets: ['smoke-test-fail']`; back-edge E35 or E36 fires if `retry_count_artifact < 1` (per graph.json gate conditions). On retry exhaustion: emit with `degradation_notice` and surface smoke test output to user — do NOT silently suppress.

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-EMIT
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
