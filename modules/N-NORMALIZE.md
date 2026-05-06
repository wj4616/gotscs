---
node_id: N-NORMALIZE
node_type: INGEST
hat: extractor
exec_type: inline
tier: model-medium
scale_gates: {token_budget: 3000, time_budget: 180, spawn_budget: 0, retry_budget: 1}
input_ports:
  - port: skill_concept_brief
    format: text
    required: true
  - port: preflight_result
    format: markdown
    signal_field: preflight_status
    required: true
output_ports:
  - port: normalize_result
    format: markdown
    signal_field: normalize_digest
raises_signals: [normalize_digest]
required_output_sections: [domain, input_shape, output_shape, success_criteria, latency_tolerance, constraints, normalize_digest]
---

## INPUT ports
- skill_concept_brief: text
- preflight_result: markdown  (signal_field: preflight_status — must be 'pass')

## OUTPUT ports
- normalize_result: markdown  (signal_field: normalize_digest)

## AI advantages exploited
- full_corpus_retention   # hold all input constraints simultaneously while extracting each field
- consistency_at_scale    # apply same extraction schema every run without field omission

## Protocol

0. **Read briefing-core.md (and the appendices declared in the per-node read-map below).**
   <!-- DD-03 read-map for N-NORMALIZE: briefing-core only. No appendices required. -->

1. **Load inputs.** Read `stages/N-PREFLIGHT.md` for `input_class`. Read the original `skill_concept_brief`.

1.5. **Context brief substitution (ec-skill / ec-spec / ec-both).** When `--context` or `--context-spec` flags are present, the user's invocation string is a pipeline command, NOT the skill concept itself. The actual concept brief lives in the referenced skill or spec.
   - If `input_class='ec-skill'`: read `$CONTEXT_PATH/SKILL.md` (the orchestrator exports `CONTEXT_PATH` as an env var at STEP 0.1). If `SKILL.md` does not exist, fall back to `$CONTEXT_PATH/README.md`. Use this file's content as the **primary concept brief** for step 4 field extraction.
   - If `input_class='ec-spec'`: read `$CONTEXT_SPEC_PATH` as the primary concept brief.
   - If `input_class='ec-both'`: read both. When they conflict on the same design element, **spec content takes precedence** per IC-04.
   - For all three classes: the original invocation string (from `skill_concept_brief.txt`) is demoted to a secondary note — it supplies pipeline constraints (mode flags, behavioral-test, review-gates) but is **NOT** the source for domain, input_shape, output_shape, or success_criteria extraction.

2. **ec-refeed handling.** If `input_class='ec-refeed'`: strip YAML frontmatter (`---` block) and all `## Section N —` heading lines. Treat remaining text as the concept brief. Note original node names in the `constraints` field — they MUST be preserved verbatim in the output skill.

3. **EC4 contradiction handling.** If `input_class=ec4`: extract BOTH sides of every contradictory constraint pair. List each as a separate constraint item, labeled `[CONTRADICTION-A]` and `[CONTRADICTION-B]`. Do NOT resolve here — N-AGG-DESIGN handles resolution.

3b. **EC10 self-prescribed topology handling.** If `input_class=ec10`: record the self-prescribed topology instruction verbatim in the constraints list as `[EC10-ADVISORY: user requested <X>]`. Add a note: "H.3 decision tree takes precedence; user preference captured as advisory constraint only." Do NOT override N-TOPOLOGY's H.3 traversal.

4. **Extract fields.** For the brief (pre-processed in step 2, or **substituted in step 1.5** when `input_class` is `ec-skill`/`ec-spec`/`ec-both`), extract:
   - **domain**: the subject area of the target skill (e.g., "code review", "document summarization", "audio DSP design"). If not stated, infer from context. If ambiguous, state both and note ambiguity.
   - **input_shape**: what the skill will receive (e.g., "free-text user prompt", "structured JSON requirements doc", "code file"). If EC2, assume "free-text user prompt."
   - **output_shape**: what the skill will produce (e.g., "markdown report", "JUCE C++ source files", "numbered action list"). If EC2, assume "structured markdown output."
   - **success_criteria**: measurable definition of success (e.g., "all findings cited to source", "output parseable by downstream agent"). If none stated, derive from domain and output_shape.
   - **latency_tolerance**: MINIMAL / STANDARD / DEEP. Look for time hints ("quick", "fast" → MINIMAL; "thorough", "exhaustive" → DEEP; default STANDARD).
   - **constraints**: enumerated list of all explicit constraints, named entities, tone markers, URIs, and success criteria stated verbatim. Each becomes an INVENTORY item per EC3 rules.

5. **Derive normalize_digest.** Write a 5–10 line structured digest:
   ```
   domain: <extracted>
   input_shape: <extracted>
   output_shape: <extracted>
   success_criteria: <extracted>
   latency_tolerance: <MINIMAL|STANDARD|DEEP>
   constraint_count: <N>
   input_class: <from preflight>
   ```

6. **Write output** to `stages/N-NORMALIZE.md`. Emit signal: `normalize_digest`.

## Scale gates
- tokens: 3000
- time: 180s
- spawns: 0
- retries: 1

## Failure modes
- timeout: retry once; on second timeout emit normalize_digest with best-effort extraction and flag all fields as LOW confidence
- malformed output: re-run step 5 only
- missing input: HALT with message "N-NORMALIZE: skill_concept_brief missing"
- format-mismatch on Edge: check preflight_result format; if unreadable, re-run N-PREFLIGHT (back-edge not in graph — escalate to orchestrator)

## Graceful Degradation
After retry exhaustion, emit a degraded output with the following frontmatter prefix:
```yaml
degradation_notice:
  node_id: N-NORMALIZE
  retry_count: <n>
  last_error_class: timeout | malformed | missing_input | subagent_crash
  degraded_fields: [<field1>, <field2>]
  confidence: low | medium
```
Pipeline does NOT halt. Orchestrator propagates degradation_notice to N-VERIFY (informational).
