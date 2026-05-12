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
   | `<skill>/RATIONALE.md` | **N-AGG-DESIGN + N-CONSTRAINTS + N-SPEC-ARTIFACT (when present) + N-FUSION-ANALYZE (in evolve mode, NEW v4.3 Phase 3 per spec §5.1.1)** | **NEW v4.2 (DD-12 — rationale carry-through).** Assemble a companion artifact preserving design intent so future maintainers can recover the *why* without re-reading the original spec. Contents: (1) `## Design Decisions` table from `stages/N-AGG-DESIGN.md` § Design Decisions; (2) `## Contradiction Resolutions` table from `stages/N-AGG-DESIGN.md § contradiction_resolutions`; (3) `## Anti-Patterns Guarded` from `stages/N-CONSTRAINTS.md`; (4) `## Calibration Points` (when --context-spec was supplied — pull verbatim from the spec's Calibration Points section); (5) `## Worked Example` (when present in --context-spec); **(6) `## Fusion Redesign Justifications` (NEW v4.3 Phase 3 — only when `evolution_mode in {evolve, evolve-aggressive}`)** — for every entry in N-FUSION-ANALYZE divergence_map, render one block in spec §5.1.1 format: `{node_id, authority, rationale, risk}`. The block is a JSON-style record per spec §5.1.1; one record per divergence_map row. SKILL.md links to RATIONALE.md via a single line in §0: "Design rationale: see RATIONALE.md". This artifact is documentation-only — never executed; never affects validation. **Skip this row** if no rationale-bearing source content exists (pure ec-brief runs with no spec/context AND overlay mode). When evolution_mode is evolve(+aggressive), the Fusion Redesign Justifications section makes RATIONALE.md unconditionally non-empty. |
   |  ~~`<skill>/briefing-core.md` and 5 `briefing-appendix-*.md` files~~ | ~~GOTSCS own briefing (P0-5)~~ | **REMOVED v4.2 (DD-11).** Briefing files were build-time scaffolding for skill creation, not runtime requirements for produced skills. Their references in produced module preambles were copy-paste leakage. v4.2 module-rendering rule (see N-MODULES.md template) omits the "Read briefing-core.md" preamble entirely. The handful of runtime conventions referenced in produced skill prose (named anti-patterns, halt-condition naming, signal-field conventions) are now inlined into the produced SKILL.md as §8 RUNTIME CONVENTIONS by N-SKILL-RENDER. Net effect: produced skill drops ~36 KB; runs anywhere without GOTSCS installed. |
   | `<skill>/graph.schema.json` | **N-JSON stage** `generated_schema_content` (F-2.4 fix — Rank-2) | extract `generated_schema_content` JSON code block from `stages/N-JSON.md`. **DO NOT** copy `~/.claude/skills/gotscs/graph.schema.json` directly — that schema fits GOTSCS's own graph and rejects produced skills with domain-specific hats (e.g., `classifier`, `scorer`, `refiner`, `recovery`) or hyphenated edge IDs (e.g., `E-05b`). The per-skill schema generated by N-JSON step 1.5(f) is a strict superset of the GOTSCS base, derived from the actual produced graph's vocabulary. **Fallback** (compatibility path for older sessions where N-JSON did not emit `generated_schema_content`): copy GOTSCS's default with a `degradation_notice: schema-fallback` warning logged on N-EMIT's stage file, NOT silently suppressed. |
   | `<skill>/tests/run-smoke-tests.sh` | GOTSCS own test harness | adapted with target skill's node count, edge count, conditional count |
   | `<skill>/tests/behavioral/EC2-minimal-brief.txt` | generated template | minimal valid brief (no flags) for EC2 smoke path |
   | `<skill>/tests/behavioral/EC4-contradictory-brief.txt` | generated template | brief with two explicit contradictory constraints for EC4 path |
   | `<skill>/tests/behavioral/EC15-refeed-brief.txt` | generated template | prior skill output content for ec-refeed path |
   | `<skill>/tests/behavioral/run-behavioral-tests.sh` | generated scaffold | invoke skill with each EC template input; verify structural properties of output |

   **hats.json format guard (H2 fix — strict, no auto-coercion).** When extracting `hats_json_content` from `stages/N-JSON.md`, verify the top-level JSON value is an array (`[...]`) AND every element has a top-level `model` field (per N-JSON step 4 spec).
   - If the top-level value is NOT a `[...]` array (e.g., `{"default_models":...,"hats":[...]}`, `{"hats":{...}}`, or a dict keyed by hat_id): set `emit_complete=false`; append `'hats-format-fail'` to repair_targets; route via **E59 (N-EMIT→N-JSON)** back-edge so N-JSON re-emits with the correct format. Do NOT auto-coerce, and do NOT invent a sidecar file (`hats-meta.json` or similar) — those are orphan artifacts not in the closed file set.
   - If the top-level value is an array but ≥1 entry lacks a `model` field: same handling — route to N-JSON for re-emit.
   - If `retry_count_artifact >= 1` on entry: HALT with `halt-on-hats-format-fail` listing the malformed structure; do not loop.
   - If the top-level value is a well-formed array with `model` populated on every entry: write `<skill>/hats.json` directly via JSON pretty-print. Closed file set: `hats.json` only — no `hats-meta.json` companion.

   **Per-file emission contract (P-001):** N-MODULES (Wave 9) writes one file per node to `stages/modules/<node_id>.md`. N-EMIT here MUST NOT parse a monolithic manifest — it copies the per-file outputs directly. This eliminates the F-001 leakage class entirely.

   **Pre-rendered SKILL.md contract (P-002):** N-SKILL-RENDER (Wave 9) assembles the full SKILL.md into `stages/N-SKILL-RENDER.md` with all 11 sections (§0 HARD GATES from N-CONSTRAINTS inventory_items verbatim; §0 ARCHITECTURE / §5 / §5.5 / §6 / §7 from N-SYNTH-GRAPH graph_spec; §1 / §1.5 from N-REGISTRY; §2 from N-EDGES; §3 / §4 from N-WAVES; Appendix A from briefing-core.md verbatim). N-EMIT here MUST NOT re-render — it copies the pre-rendered file. This eliminates the F-002/F-003/F-009 class.

   For `tests/run-smoke-tests.sh`: generate with structural checks (file existence, JSON validity, node count, edge count, ai_advantages presence, frontmatter, V16 compliance, V8 downshift_threshold, V19 context_source when --context was used, **schema self-heal**). **v4.2 (DD-11) deletes the prior DD-03 appendix-completeness check** — produced skills no longer ship briefing files, so there is nothing to verify at the skill root. **NEW v4.2 (DD-13) schema self-heal check:** if `graph.schema.json` exists AND `jsonschema.validate(graph.json, graph.schema.json)` raises `ValidationError`, derive a permissive per-skill schema from observed graph values (collect `set(n["hat"] for n in graph.nodes)`, `set(n["exec_type"] ...)`, `set(n["tier"] ...)`, `set(e["edge_type"] for e in graph.edges)`; emit a copy of the base schema with these enums replacing the GOTSCS-default closed-vocab) and overwrite `graph.schema.json`. Re-validate. If still failing, emit `SMOKE WARN: schema-self-heal-failed` (non-blocking). This eliminates the schema-fallback embarrassment where produced skills shipped graph.schema.json files that rejected their own graph.json. The behavioral stubs from prior versions live at the `tests/behavioral/` scaffold — `run-smoke-tests.sh` should reference them: `echo "Run tests/behavioral/run-behavioral-tests.sh for EC2/EC4/EC15 acceptance coverage."`. **G-11: The smoke test MUST NOT reference `scripts/run-skill.sh` in its `invoke_skill()` function** (that file is not emitted). Instead, the stub comment reads: `"# Stub invoker for offline structural testing. For real behavior testing, see tests/HARNESS-NOTE.md."`.

   **Counter and heredoc implementation rules (A01 — bash arithmetic trap).** When writing the `pass()` and `fail()` shell functions, use `PASS=$((PASS+1))` and `FAIL=$((FAIL+1))` — NOT `((PASS++))` / `((FAIL++))`. The arithmetic-expression form `((expr))` exits with code 1 when the expression evaluates to zero (bash treats 0 as falsy); under `set -e` this terminates the script on the very first `pass` call when PASS=0. For python3 heredoc blocks that need shell variable expansion (e.g., `$SKILL_DIR`): use an unquoted delimiter (`<< PYEOF`) so bash expands variables inline. Do NOT use a single-quoted delimiter (`<< 'PYEOF'`) combined with `sys.argv[1]` path injection — the heredoc's PYEOF marker does not consume the trailing argument and bash executes it as a bare shell command ("Is a directory" error). Safe pattern for per-check wrappers: `python3 - << PYEOF … PYEOF; RESULT=$?; if [[ "$RESULT" -eq 0 ]]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi`.

   **Regression suite (`tests/run-regression-suite.sh`) (A02 — counter-routing contract).** Generate a companion regression suite targeting INVENTORY constraint mutation-kill coverage (Goal-6: ≥80% kill rate). Structure the script with named counter functions:
   ```bash
   pass() { echo "PASS [R$1]: $2"; PASS=$((PASS+1)); }
   fail() { echo "FAIL [R$1]: $2"; FAIL=$((FAIL+1)); }
   ```
   For each regression test: run the check as a python3 heredoc (or bash block); capture its exit code with `RESULT=$?`; route to `pass "RNN" "description"` or `fail "RNN" "description"` based on that code. **Critical: python3 sub-tests that print `PASS:` / `FAIL:` strings directly without calling `pass()`/`fail()` leave the final counter permanently at `PASS: 0  FAIL: 0`.** Always route through the shell counter functions. Apply the same arithmetic rule as above: `PASS=$((PASS+1))` not `((PASS++))`. Standard regression battery (augment with skill-domain-specific tests as appropriate):
   - R01: graph.json metadata integrity (`total_nodes`/`total_edges`/`spawn_node_count`/`back_edges` match actual computed values)
   - R02: every INGEST-type node has ≥1 outgoing edge (V5-ext structural guarantee)
   - R03: all nodes have 4-dimension scale gates (`token_budget`, `time_budget`, `spawn_budget`, `retry_budget`)
   - R04: `determinism_class` consistent between `graph.json` metadata and `SKILL.md` frontmatter (V13b)
   - R05: `hats.json` tier mappings consistent with `graph.json` node tiers (V8d)
   - R06: module bijection — `set(node_ids) == set(modules/*.md filenames)` (V10)
   - R07: AGGREGATION node (if present) is mid-graph (`wave < min PERSISTER wave`) (V3)
   - R08: all INVENTORY tags present verbatim in `graph.json metadata.inventory` (AP-V24)
   - R09: no back-edges when `determinism_class=deterministic`

   **Claude Code runner variant (G-11 — conditional).** If the target install path is under `~/.claude/skills/` (detected from `skill_path` in normalize_digest or orchestrator env): additionally emit `tests/run-smoke-tests-claude-code.sh` with a real `invoke_skill()` that calls `claude --skill <skill_name> "<test prompt>"` (if `claude` CLI is available). Gate the emission with a bash check: `command -v claude >/dev/null 2>&1 || { echo "SKIP: claude CLI not found; real invocation tests unavailable"; exit 0; }`. This script is advisory (exit 0 even on Claude CLI errors) until the user validates the invocation interface.

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

4.4. **Fusion-mode artifact emission (NEW v4.3 Phase 3 — spec §5.1).** Read `evolution_mode` from `stages/N-PREFLIGHT.md`. If `evolution_mode in {evolve, evolve-aggressive}`: emit FUSION.md and REGRESSION.md into the produced skill directory unless the runtime flag suppresses one (see below). Otherwise (overlay/greenfield): skip this step entirely.

   **FUSION.md — emit unless `NO_FUSION_DOC=true` (literal string match).** Compose `<skill_path>/FUSION.md` from `stages/N-FUSION-ANALYZE.md` plus supporting Phase-2 stage files. The file is documentation-only — never executed; never affects validation. Suppression: ONLY when env var `NO_FUSION_DOC` equals the literal string `true` (set by `--no-fusion-doc` per SKILL.md STEP 0.1). Unset, empty string, `false`, `0`, or any other value all mean "emit". Normalize via shell test: `[[ "${NO_FUSION_DOC:-}" == "true" ]]`. The audit trail is still computed by N-FUSION-ANALYZE; it just doesn't get persisted to the produced skill directory.

   FUSION.md template (sections in order — derived verbatim from N-FUSION-ANALYZE stage when present, augmented with cross-source references):

   ```markdown
   # FUSION.md — Fusion audit trail

   This file documents how this skill was synthesized from multiple context sources via GOTSCS evolve mode. It is documentation-only; the runtime skill behavior is fully determined by SKILL.md, graph.json, and modules/. To re-derive the skill from scratch, see RATIONALE.md.

   evolution_mode: <evolve | evolve-aggressive>
   gotscs_version: <version from graph.json metadata>
   timestamp: <ISO 8601>
   waiver_justification: |
     <verbatim from stages/waiver_justification.txt; only present when evolution_mode == 'evolve-aggressive'>

   ## fusion_sources
   <copy from N-FUSION-ANALYZE step 2 context_inventory_classified table>

   ## precedence_stack
   P1 design_brief > P2 spec_enhancement > P3 skill_executable > P4 GOTSCS defaults

   ## delta_matrix
   <copy from N-FUSION-ANALYZE step 4 — full per-item table>

   ## preservation_map
   <copy from N-FUSION-ANALYZE step 7 — every item with origin="preserved">

   ## divergence_map
   <copy from N-FUSION-ANALYZE step 7 — every item with origin in {upgraded, replaced, merged, added, removed, resequenced, recontracted}, with regression_risk for replaced/removed>

   ## inheritance_map
   <copy from N-FUSION-ANALYZE step 7 — every item with inherited_from: brief | spec | original | invented>

   ## risk_assessment
   <copy from N-FUSION-ANALYZE step 7 — high-risk divergences flagged separately>

   ## fusion_decisions
   <copy from N-FUSION-ANALYZE step 7 — full audit trail of every override>

   ## decomposition_tasks
   <copy from N-DECOMPOSE step 6 — DT-NN task table with category and authority>

   ## fusion_constraints_applied
   <copy from N-CONSTRAINTS step 6 fusion_constraints — FC-01..FC-09 with their enforcement_phase>
   ```

   **REGRESSION.md — emit unconditionally in evolve mode (no suppression flag).** Compose `<skill_path>/REGRESSION.md` as a test plan derived from preservation_map and divergence_map. Format:

   ```markdown
   # REGRESSION.md — Regression test plan

   This file enumerates the regression risks introduced by evolve-mode synthesis and the corresponding tests that should be exercised before this skill is considered production-ready. The test plan is derived from FUSION.md preservation_map (functionality preserved → regression coverage) and divergence_map (functionality changed → spec acceptance coverage).

   evolution_mode: <evolve | evolve-aggressive>
   gotscs_version: <version from graph.json metadata>
   timestamp: <ISO 8601>

   ## Preserved-functionality regression tests
   For every entry in FUSION.md preservation_map (origin=preserved): exercise the functionality and verify byte-equivalence (or behavioral equivalence for non-deterministic skills) against the original skill if the preservation_map row has `authority: P3 original`.

   <generate one row per preservation_map entry:>
   | item_id | kind | original_signature | regression_test_target | test_status |

   `regression_test_target` is the file/test that exercises the preserved item; `test_status` is `auto-generated | manual-required | covered-by-existing-tests`.

   ## Diverged-functionality acceptance tests
   For every entry in FUSION.md divergence_map: emit a row capturing the spec acceptance criterion that justified the divergence. For replaced/removed entries with `regression_risk: high`, surface as priority-1 manual review.

   <generate one row per divergence_map entry:>
   | item_id | origin | authority | regression_risk | acceptance_criterion | risk_acknowledgment |

   ## High-risk divergence summary
   <list the priority-1 items: rows from divergence_map where origin in {replaced, removed} AND regression_risk in {medium, high}. These MUST be reviewed by the user before production deployment.>

   ## FC-08 compliance gate
   FC-08 mandates that every redesign has a corresponding regression test in the smoke-test battery. Verify <skill_path>/tests/run-smoke-tests.sh contains assertions for every divergence_map row with origin in {upgraded, replaced, merged, recontracted}. Mismatches are listed below as TODO items.
   ```

   **Failure modes during fusion emission:**
   - `stages/N-FUSION-ANALYZE.md` missing → HALT with `halt-emit-fusion-prereq-missing`. (Should be unreachable: orchestrator's Wave-2 barrier requires the file when evolution_mode is evolve+.)
   - `stages/N-DECOMPOSE.md` lacks `decomposition_tasks` section → emit FUSION.md without that section + log degradation_notice. Pipeline does not halt.
   - `stages/N-CONSTRAINTS.md` lacks `fusion_constraints` section → emit FUSION.md without that section + log degradation_notice. Pipeline does not halt.
   - When `NO_FUSION_DOC=true`: FUSION.md is not written. REGRESSION.md is still written (regression risks must always be surfaced).

   Append the emitted file paths to `files_written` in stages/N-EMIT.md. Files: `<skill_path>/FUSION.md` (when not suppressed), `<skill_path>/REGRESSION.md`.

4.5. **Tier-1 KB Snippet Bundle embed (G-03 — HG-04 closure).** If `stages/N-CONSTRAINTS.md` lists HG-04 (or any standalone-default contract) in its inventory_items, OR if the brief contains a directive matching pattern `Tier.{0,5}1.{0,30}KB.{0,30}Bundle` or `kb-?snippet`:
   1. Locate the source content: look for a spec section heading matching `## Tier 1 KB Snippet Bundle` or a brief appendix section with a similar heading (heading-pattern-match: `(?i)tier.{0,5}1.{0,30}kb.{0,30}bundle|kb.{0,5}snippet`).
   2. If source content found: copy verbatim to `<skill_path>/modules/kb-snippets.md`.
   3. Verify the produced file contains at least 1 snippet block matching pattern `^## S-\d+` (one or more snippet sections). If 0 matches: emit warning `warn-kb-snippets-no-snippet-sections` (non-blocking; source copied but empty).
   4. If no source content found AND HG-04 is in inventory_items: HALT with `halt-on-missing-tier1-kb-source` — list which inventory_item demanded it and what headings were searched. Do NOT silently omit the file.
   5. If HG-04 is NOT in inventory_items AND no kb-snippet pattern in brief: skip this step silently.

4b. **Post-emit schema validation (G-13 — before smoke test).**
```bash
# 1. Validate graph.json against produced graph.schema.json
python3 - << 'PYEOF'
import json, sys
try:
    import jsonschema
    schema = json.load(open("<skill_path>/graph.schema.json"))
    graph  = json.load(open("<skill_path>/graph.json"))
    jsonschema.validate(graph, schema)
    print("G-13/1: graph.json schema validation PASS")
except jsonschema.ValidationError as e:
    print(f"HALT: halt-on-post-emit-schema-fail: {e.json_path} — {e.message}", file=sys.stderr)
    sys.exit(10)
except Exception as e:
    print(f"HALT: halt-on-post-emit-schema-fail: {e}", file=sys.stderr)
    sys.exit(10)
PYEOF
SCHEMA_RESULT=$?

# 2. hats.json parseable + required fields
python3 - << 'PYEOF'
import json, sys
hats = json.load(open("<skill_path>/hats.json"))
required = ["hat_id", "tier", "downshiftable", "nodes"]
for h in hats:
    missing = [f for f in required if f not in h]
    if missing:
        print(f"HALT: halt-on-hats-missing-fields: hat {h.get('hat_id','?')} missing {missing}", file=sys.stderr)
        sys.exit(11)
print(f"G-13/2: hats.json {len(hats)} hats validated PASS")
PYEOF
HATS_RESULT=$?

# 3. Every node_id in graph.json has a corresponding modules/<node_id>.md
python3 - << 'PYEOF'
import json, os, sys
graph = json.load(open("<skill_path>/graph.json"))
missing = [n["id"] for n in graph["nodes"] if not os.path.exists(f"<skill_path>/modules/{n['id']}.md")]
if missing:
    print(f"HALT: halt-on-post-emit-missing-modules: {missing}", file=sys.stderr)
    sys.exit(12)
print(f"G-13/3: all {len(graph['nodes'])} module files present PASS")
PYEOF
MODULES_RESULT=$?

# 4. SKILL.md frontmatter nodes:/edges: match graph.json metadata
python3 - << 'PYEOF'
import json, re, sys
meta = json.load(open("<skill_path>/graph.json"))["metadata"]
skill_md = open("<skill_path>/SKILL.md").read()
m_nodes = re.search(r"^nodes:\s*(\d+)", skill_md, re.MULTILINE)
m_edges = re.search(r"^edges:\s*(\d+)", skill_md, re.MULTILINE)
errs = []
if m_nodes and int(m_nodes.group(1)) != meta["total_nodes"]:
    errs.append(f"nodes: SKILL.md={m_nodes.group(1)} vs graph.json={meta['total_nodes']}")
if m_edges and int(m_edges.group(1)) != meta["total_edges"]:
    errs.append(f"edges: SKILL.md={m_edges.group(1)} vs graph.json={meta['total_edges']}")
if errs:
    print(f"HALT: halt-on-post-emit-metadata-mismatch: {errs}", file=sys.stderr)
    sys.exit(13)
print("G-13/4: SKILL.md frontmatter nodes/edges match graph.json PASS")
PYEOF
META_RESULT=$?
```
If any of the 4 sub-checks fail: HALT with `halt-on-post-emit-validation-fail` listing every failed check; preserve `stages/` for debug; set `emit_complete=false`. Do NOT proceed to the P-004 smoke test.

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
     - **graph.json schema failures** (SCHEMA_VALIDATE_RESULT≠0 — e.g., tier `n/a`, undocumented hat, malformed edge id) → **E59 (N-EMIT→N-JSON)** (NEW — added by F-2.3/F-2.4 Rank-2/3 fix). Increment `retry_count_artifact`. N-JSON re-runs steps 1.5(c2)+(c3)+(f) which auto-correct tier-no-llm and regenerate the per-skill schema; N-EMIT re-attempts.
     - **graph.json metadata mismatch** (computed totals disagree with claimed totals after N-JSON re-run) → **E59 (N-EMIT→N-JSON)** as above; the metadata override in N-JSON step 1.5(c3) is unconditional, so re-run will produce the corrected file.
     Increment `retry_count_artifact` via sync-signal.sh. Re-run the routed upstream node. Re-attempt N-EMIT.
   - If any fail AND `retry_count_artifact >= 1`: emit_complete=false; surface partial skill with diagnostic listing every failed check. Pipeline reports HALT with `halt-on-post-emit-validation-fail`.

4d. **Opportunistic post-emit audit (NEW v4.2 — DD-13 / G-15 second-opinion lens).** After 4b/4c pass and BEFORE step 5 emits the success block, run a non-blocking second-opinion audit using `epiphany-audit-v2` if installed. This step is advisory-only — the skill artifact has already passed N-VERIFY's V-battery; the audit is a quality-improvement signal, not a gate.

   ```bash
   AUDIT_SKILL=~/.claude/skills/epiphany-audit-v2
   POST_EMIT_AUDIT_STATUS=""

   # User opt-out check
   if [[ "${NO_POST_AUDIT:-false}" == "true" ]]; then
     POST_EMIT_AUDIT_STATUS="skipped (--no-post-audit)"
   # Presence check (filesystem only — no subprocess probe)
   elif [[ ! -f "$AUDIT_SKILL/SKILL.md" ]]; then
     POST_EMIT_AUDIT_STATUS="skipped (epiphany-audit-v2 not installed; optional)"
   else
     # Invoke read-only audit on the produced SKILL.md.
     # Audit is hard-coded to --audit mode; never --fix or --improve against the freshly
     # emitted skill — too easy to corrupt the just-produced state.
     # Capture output to a temp log; surface summary only.
     AUDIT_LOG=$(mktemp)
     if timeout 180s python3 -c "
   # Probe: does the audit skill have a runnable entrypoint we can invoke programmatically?
   import os, subprocess, sys
   entry = os.path.expanduser('~/.claude/skills/epiphany-audit-v2/scripts/run-audit.sh')
   if os.path.exists(entry):
       r = subprocess.run(['bash', entry, '--audit', '<skill_path>/SKILL.md'],
                          capture_output=True, text=True, timeout=170)
       sys.stdout.write(r.stdout); sys.stderr.write(r.stderr)
       sys.exit(r.returncode)
   else:
       # No programmatic entrypoint — surface install advisory.
       print('NO_PROGRAMMATIC_ENTRYPOINT', file=sys.stderr)
       sys.exit(2)
   " > "$AUDIT_LOG" 2>&1; then
       # Audit completed; parse summary line if present
       FINDINGS_HIGH=$(grep -cE "severity: HIGH|severity: CRITICAL" "$AUDIT_LOG" 2>/dev/null || echo 0)
       FINDINGS_TOTAL=$(grep -cE "^### Finding F" "$AUDIT_LOG" 2>/dev/null || echo 0)
       if [[ "$FINDINGS_HIGH" -gt 0 ]]; then
         POST_EMIT_AUDIT_STATUS="ADVISORY — $FINDINGS_TOTAL findings (${FINDINGS_HIGH} HIGH/CRITICAL); review before installing"
       else
         POST_EMIT_AUDIT_STATUS="COMPLETED ($FINDINGS_TOTAL findings, none HIGH)"
       fi
     else
       AUDIT_RC=$?
       if [[ "$AUDIT_RC" -eq 2 ]]; then
         POST_EMIT_AUDIT_STATUS="skipped (epiphany-audit-v2 has no programmatic entrypoint at scripts/run-audit.sh)"
       else
         POST_EMIT_AUDIT_STATUS="ERROR rc=$AUDIT_RC (skill produced; audit unavailable for this run)"
       fi
     fi
     rm -f "$AUDIT_LOG"
   fi

   echo "Post-emit audit: $POST_EMIT_AUDIT_STATUS"
   ```

   **Behavior matrix (all non-blocking — never fails the build):**

   | State | POST_EMIT_AUDIT_STATUS | Effect |
   |---|---|---|
   | Audit installed; passes; no HIGH findings | `PASS (N findings, none HIGH)` | Continue to step 5 |
   | Audit installed; passes; ≥1 HIGH/CRITICAL | `PASS — N findings (M HIGH/CRITICAL); review before installing` | Continue to step 5 (advisory only — does not halt) |
   | Audit installed; errors out | `ERROR rc=N (skill produced; audit unavailable for this run)` | Continue to step 5 |
   | Audit not installed | `skipped (epiphany-audit-v2 not installed; optional)` | Continue to step 5 |
   | User passed `--no-post-audit` | `skipped (--no-post-audit)` | Continue to step 5 |

   **Three guarantees** (all enforced by the script structure above):
   1. **Never fails the build.** All branches `continue to step 5`. Audit is a second-opinion lens, not a gate. The pipeline's authoritative quality gate is N-VERIFY.
   2. **Never silently passes when it didn't actually run.** The four "skipped/error" branches all surface explicit status messages; a user cannot mistake "no audit output" for "audit said all good".
   3. **Read-only.** Hard-coded `--audit` flag. Never `--fix` or `--improve` against a freshly emitted skill — too easy to corrupt the just-produced state.

   The `POST_EMIT_AUDIT_STATUS` is appended to the emit-stage file's `## audit_advisory` section and surfaced in the user-facing emit block at step 5 between the file list and the install instructions.

   **Tier-3 audit fix — degradation_notices visibility.** Append the audit status to `SIGNAL_STATE["degradation_notices"]` whenever `POST_EMIT_AUDIT_STATUS` starts with `skipped`, `ERROR`, or `ADVISORY`. Use sync-signal.sh:
   ```bash
   case "$POST_EMIT_AUDIT_STATUS" in
     skipped*|ERROR*|ADVISORY*)
       ~/.claude/skills/gotscs/scripts/sync-signal.sh "$SESSION_DIR" \
         degradation_notices_append="post_emit_audit:$POST_EMIT_AUDIT_STATUS"
       ;;
   esac
   ```
   This makes "audit ran but had findings" / "audit not installed" / "audit error" all visible in the final SIGNAL_STATE invariant scan (STEP 10d) — silent skipping defeats the opportunistic-audit intent.

5. **Emit runtime-delivery note (G-05 — HARNESS-NOTE.md).** Write `<skill_path>/tests/HARNESS-NOTE.md` with the following content (substituting actual skill name and node count):

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

6. **Report to user.** Write `stages/N-EMIT.md`:
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
