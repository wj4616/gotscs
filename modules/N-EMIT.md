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

4. **Write files using the section-to-source assembly table:**

   | Output file / section | Source stage | Operation |
   |---|---|---|
   | `<skill>/SKILL.md` (full document) | **N-SKILL-RENDER stage** (P-002) | `cp stages/N-SKILL-RENDER.md <skill>/SKILL.md` — already assembled with §0–§7 + Appendix A by the dedicated renderer |
   | `<skill>/graph.json` | N-JSON stage | extract `graph_json_content` JSON code block |
   | `<skill>/hats.json` | N-JSON stage | extract `hats_json_content` JSON code block |
   | `<skill>/modules/<node_id>.md` | **N-MODULES stages/modules/ outputs** (P-001) | `cp stages/modules/*.md <skill>/modules/` — one file per node, no parsing |
   | `<skill>/briefing-core.md` | GOTSCS own briefing (P0-5) | `cp ~/.claude/skills/gotscs/briefing-core.md <skill>/briefing-core.md` — modules reference this file in step 0; without it spawn agents cannot load schema vocabulary |
   | `<skill>/graph.schema.json` | GOTSCS own schema (DD-09) | `cp ~/.claude/skills/gotscs/graph.schema.json <skill>/graph.schema.json` — enables PRC1 self-validation on the produced skill |
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
   else
     echo "ADVISORY: validate-graph.sh not found at $VALIDATE_SCRIPT; --target check skipped."
     echo "Install GOTSCS scripts to enable full graph schema validation."
     GRAPH_VALIDATE_RESULT=0  # non-blocking when script absent
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
   - If ALL three pass: continue to step 5; emit_complete=true.
   - If any fail AND `retry_count_artifact < 1`: fire back-edge **E35 (N-EMIT→N-MODULES)** for module-leakage failures or **E36 (N-EMIT→N-SKILL-RENDER)** for SKILL.md content failures. Increment `retry_count_artifact` via sync-signal.sh. Re-run the failing upstream node. Re-attempt N-EMIT.
   - If any fail AND `retry_count_artifact >= 1`: emit_complete=false; surface partial skill with diagnostic listing every failed check. Pipeline reports HALT with `halt-on-post-emit-validation-fail`.

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
