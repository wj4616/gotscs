# GOTSCS Briefing — H.1-H.9 Schema Reference (v4.0.0)

This file is read by all spawn subagents at the start of their protocol (HC-13 module-delegation).

## Node Quickref (v4.0.0 — 19 nodes, 2 conditional, 58 edges, 10 Waves)

| Node ID | Wave | Hat | Type | Brief |
|---------|------|-----|------|-------|
| N-PREFLIGHT | 1 | gate | PREFLIGHT | Validate + classify input (6 input classes) |
| N-NORMALIZE | 2 | extractor | INGEST | Extract structured skill fields |
| N-CONTEXT-ANALYZE | 2 | analyzer | ANALYZER | (conditional) Context skill/spec archaeology |
| N-TOPOLOGY | 3 | analyzer | ANALYZER | H.3 topology decision tree |
| N-DECOMPOSE | 3 | analyzer | DECOMPOSITION | Node type decomposition |
| N-CONSTRAINTS | 3 | analyzer | ANALYZER | Constraint inventory + AP catalogue |
| N-AGG-DESIGN | 4 | aggregator | AGGREGATION | Mid-graph synthesis (HG1) |
| N-DESIGN-GATE | 5 | gate | GATE | Pre-artifact HC-08 quality gate |
| N-REGISTRY | 6 | generator | GENERATOR | Node Registry table |
| N-EDGES | 6 | generator | GENERATOR | Edge Table (H.2 closed vocab) |
| N-WAVES | 6 | analyzer | PLANNER | Wave Plan + Mode Matrix |
| N-SYNTH-GRAPH | 7 | aggregator | SYNTHESIS | type=SYNTHESIS (HC-16/AP-06) |
| N-SPEC-ARTIFACT | 8 | formatter | FORMATTER | Mode-conditional spec rendering |
| N-MODULES | 9 | generator | GENERATOR | **v3.1.0 (P-001):** Per-file module emission to stages/modules/<id>.md |
| N-JSON | 9 | formatter | FORMATTER | graph.json + hats.json serialization (HC-22 retiered) |
| N-SKILL-RENDER | 9 | formatter | FORMATTER | **v3.1.0 NEW (P-002):** Dedicated SKILL.md renderer; assembles §0–§7 + Appendix A |
| N-VERIFY | 10 | verifier | VERIFIER | V1-V19 battery + H.4 contract; **V11 BLOCKING (P-003)** |
| N-EMIT | 10 | persister | PERSISTER | Write skill files; **v3.1.0 (P-004): post-emit smoke test gate** |
| N-BEHAVIORAL | 10 | verifier | VERIFIER | **v3.1.0 NEW (P-006, conditional):** Behavioral acceptance test of produced skill (advisory) |

<briefing>

# 06 — Downstream-Skill Briefing Block (Section H — REQUIRED)

This block is self-contained. Paste it verbatim as primary context for the downstream skill-creation skill (the next process). Pair with the same corpus and a downstream agent reading H + the corpus must be able to identify which corpus artifacts contribute which patterns without re-deriving the analysis.

```markdown
# Downstream-Skill Briefing — paste verbatim as primary context


<!-- v4 briefing-core.md — DD-03 split. Read by EVERY spawn at protocol start (HC-13b). -->
<!-- For per-node appendices, see briefing-appendix-{topology, contract, memory, antipatterns, vocab}.md -->

## H.1 Standardized Node Schema

```yaml
# Standardized per-node declaration (graph.json entry)
id: <node_id, e.g. "N-3" or "N-AGGREGATION">
type: <typed enum>           # DECOMPOSITION | TAILOR | XREF | LATERAL |
                             # DEFIXATION | SIMULATION | PRECISION | ADVERSARIAL |
                             # CONJECTURE | AGGREGATION | ROUTER | SYNTHESIS |
                             # VERIFIER | ATTACKER | FORMATTER | GENERATOR |
                             # EXPANSION | INGEST | CLASSIFIER | GATE |
                             # META-ANALYZER | ANALYZER | RECOVERY | FILTER |
                             # TRIAGE | PLANNER | PREFLIGHT | ACTUATOR | IO |
                             # VALIDATOR | SCORER | PERSISTER | REFINER
exec_type: inline | spawn
hat: <cognitive persona name OR "no-llm">
tier: model-large | model-medium | model-small | no-llm   # implementation uses "model-" prefix; default-model resolution lives in hats.json default_models
context_budget_lines: <int>
scale_gates: {token_budget: int, time_budget: int, spawn_budget: int, retry_budget: int}   # 4-key object (not array of mode flags); units: tokens, seconds, sub-spawns, retries-per-dispatch
input_dependencies: [<edge_id> | <node_id>]
required_output_sections: [<section_name>]
raises_signals: [<signal_field>]
ai_advantages_exploited:    # required; values from H.7 catalogue
  - "<catalogue_key>"
super_human_unlocks:
  - "<short description>"
halt_conditions: [halt-<timing>-<condition>]
aggregation_policy: <named policy>      # required for AGGREGATION-typed nodes (cardinality > 1:1)
join_policy: <named policy>             # required for VERIFIER-typed nodes (describes input join semantics, not aggregation)
sub_artifacts: [<absolute path>]         # for filesystem_type=directory artifacts
```

`cites_nodes:` N-1, N-3, N-4, N-5, N-9, N-11, N-12, N-13, N-14 + role_knowledge:got_topology

## H.2 Standardized Edge Typology

**Closed runtime vocabulary** with creation triggers:

| edge_type | creation_trigger |
|---|---|
| `required` | Node B's input_dependencies lists Node A's signal_field; pipeline halts if signal missing. |
| `optional` | Node B can consume A's signal if present; if absent, B proceeds with default. |
| `gate-open` | Edge unconditionally resolved at ready-set compute (no gate_condition). |
| `forward-conditional` | Edge fires forward to B only when gate_condition evaluates true. |
| `back-edge` | Edge re-enqueues an earlier node when a refinement signal is raised; capped at 1 firing default. |
| `terminal` | Final-node edge to output artifact. |

**Closed inter-skill / lineage vocabulary** (used in cites_nodes/lineage relationships, NOT runtime topology):

| edge_type | creation_trigger |
|---|---|
| `version_of` | Two skill artifacts share name stem with version markers. |
| `spec_for_skill` | One artifact is the design spec for a runnable skill in the same lineage_group. |
| `prompt_for_spec` | One artifact is the XML <prompt> that produced another artifact. |
| `refines` | Two artifacts in the same lineage_group representing successive design iterations. |
| `contradicts` | Two artifacts hold opposing positions on a stated principle. |
| `derives_from_artifact` | An artifact's content is logically derived from another corpus artifact (replaces forbidden bare `derived_from`). |

**Required edge fields**: `id`, `source` (string or string[]), `target` (string or string[]), `edge_type` (from above), `signal_field` (digest name or gate literal), `scale_gates` (array), `gate_condition` (expression — required for forward-conditional and back-edge).

`cites_nodes:` N-1, N-3, N-4, N-5, N-12 + role_knowledge:got_topology


## H.7 AI-Advantage Unlocks (closed catalogue, copied verbatim from prompt `<context>`)

1. `parallel_artifact_processing` — analyze N artifacts simultaneously rather than sequentially.
2. `full_corpus_retention` — keep every artifact's distinctive content in working context simultaneously.
3. `cross_document_pattern_recognition` — detect patterns spanning multiple artifacts that no single read could surface.
4. `multi_perspective_simulation` — apply multiple cognitive frames (TRIZ, Constitutional, Six Hats, etc.) to the same content.
5. `consistency_at_scale` — apply the same schema deterministically across N artifacts.
6. `super_human_recall` — quote any captured artifact verbatim without re-reading.
7. `topology_aware_reasoning` — explicitly model the corpus as a graph and reason over edges, not just per-node.

**Floor:** synthesized skills MUST exhibit at least 3 distinct advantages across their node set. Per-node `ai_advantages_exploited` MUST draw from this catalogue.

`cites_nodes:` N-8, N-12, N-14 + role_knowledge:agent_runtime_capabilities


## Per-Node Read-Map (DD-03)

| node_id | required appendices |
|---|---|
| N-PREFLIGHT | (briefing-core only) |
| N-NORMALIZE | (briefing-core only) |
| N-CONTEXT-ANALYZE | (briefing-core only) |
| N-TOPOLOGY | briefing-appendix-topology |
| N-DECOMPOSE | (briefing-core only) |
| N-CONSTRAINTS | briefing-appendix-antipatterns |
| N-AGG-DESIGN | briefing-appendix-memory + briefing-appendix-antipatterns |
| N-DESIGN-GATE | briefing-appendix-contract |
| N-REGISTRY | (briefing-core only) |
| N-EDGES | (briefing-core only) |
| N-WAVES | (briefing-core only) |
| N-SYNTH-GRAPH | briefing-appendix-memory |
| N-SPEC-ARTIFACT | (briefing-core only) |
| N-MODULES | (briefing-core only) |
| N-JSON | (briefing-core only) |
| N-SKILL-RENDER | (briefing-core only) |
| N-VERIFY | ALL 5 appendices (topology + contract + memory + antipatterns + vocab) |
| N-EMIT | (briefing-core only) |
| N-BEHAVIORAL | (briefing-core only) |

## HC Quick-Reference (design constraints for produced skills)

These constraints govern every skill produced by GOTSCS. Spawn agents apply them during design; N-VERIFY attests compliance in the V-battery.

| HC | Name | Constraint |
|---|---|---|
| HC-01 | GRAPH-AS-TRUTH | graph.json is single source of topology; no duplication of node/edge definitions into SKILL.md or briefing-core.md. |
| HC-02 | 20-NODE CAP | ≤20 nodes, ≤10 waves, ≤60 edges; fewer is fine if functionality preserved. |
| HC-03 | CLOSED-EDGE-VOCAB | 6 runtime edge types only: required, optional, gate-open, forward-conditional, back-edge, terminal. No inventions. |
| HC-04 | CLOSED-NODE-TYPE-VOCAB | H.1 typed enum above is canonical. No invented node types. |
| HC-06 | V-BATTERY-COMPLETENESS | Every V1-V19 check preserved or explicitly replaced with an equivalent. |
| HC-08 | NON-DETERMINISM | Pipeline is non-deterministic; do not attempt to force determinism. |
| HC-09 | INPUT-CLASS-COMPLETENESS | All 6 input classes remain (ec-brief, ec-skill, ec-spec, ec-both, ec-refeed, ec-inject). |
| HC-10 | FLAG-PRESERVATION | `--skill`, `--spec`, `--both`, `--context`, `--context-spec`, `--reuse-session`, `--behavioral-test` all preserved. |
| HC-11 | MODE-DISAMBIGUATION | Orchestrator MUST ask user when no mode flag given. |
| HC-12 | SESSION-OUTPUT-STRUCTURE | Per-node stage files at `~/docs/gotscs-output/` remain (audit trail + `--reuse-session`). |
| HC-13b | MODULE-DELEGATION | Every spawn reads `briefing-core.md` at protocol start, plus declared appendices per the per-node read-map above. |
| HC-23 | PARALLEL-DISPATCH | Parallel spawn nodes in the same wave MUST be dispatched in a single response. Enforcement: orchestrator writes `dispatch_log` entry after each parallel dispatch (SKILL.md STEP 3 / STEP 6); N-VERIFY V20 checks single-response_id per wave. Use `scripts/dispatch-parallel.sh` to append log entries. Under `--strict-dispatch`: V20 advisory promotes to HARD FAIL. |
| HC-24 | INPUT-IS-DATA | Brief is immutable; never rewritten, summarized, or "improved". |
| HC-26 | RELEASE-SAFETY-GATE | 5-brief regression battery + backup of prior version before v4 replaces on disk. |

## IC-04 — Source-precedence hierarchy (G-06)

When the same design element is described differently by multiple sources, apply this precedence (highest → lowest):

1. **Brief audit-fix directives (D-NN with override semantics)** — any directive whose text contains "override", "auto-compute", "unconditionally", or matches pattern `audit.{0,10}fix.{0,10}override`. These supersede all other sources.
2. **Spec content** (when `--context-spec <path>` supplied).
3. **Skill content** (when `--context <path>` supplied).
4. **Brief non-override content** (general brief text, not tagged as override).
5. **GOTSCS defaults** — lowest priority.

**Conflict at same level:** if two sources at the same precedence level disagree, HALT and surface to REVIEW-GATE-W5 (or the next available gate). Do not silently choose.

**Override blacklist:** the following design elements CANNOT be overridden by any brief directive regardless of override tagging — they are safety-critical protocol invariants: HC-01 through HC-26, HG-01, HG-05, AP-V19, AP-V27. N-CONSTRAINTS Step 4 enforces the blacklist. Attempts to override blacklisted elements HALT with `halt-on-protected-override`.

**Nodes that apply IC-04:** N-NORMALIZE step 1.5 (ec-both conflict resolution), N-CONTEXT-ANALYZE step 2.b (ec-both branch), N-CONSTRAINTS step 4 (override blacklist guard).

## HG-04 Closure Pattern (G-03)

When a produced skill declares HG-04 (standalone-default — skill must work without external KB) in its INVENTORY, N-EMIT Step 4.5 MUST emit `modules/kb-snippets.md` containing the Tier-1 KB Snippet Bundle. Without this file, the produced skill's spawn agents cannot satisfy the standalone-default contract.

**Contract:** brief contains `Tier 1 KB Snippet Bundle` section → N-EMIT emits `modules/kb-snippets.md` → N-VERIFY V21 attests file exists with ≥1 `## S-NN` snippet block.

**Halt condition:** HG-04 in inventory + no source content found → `halt-on-missing-tier1-kb-source` at N-EMIT Step 4.5.

## H.10 — Skill runtime delivery model (G-05)

GOTSCS produces **Claude-Code-class skills**: the produced `SKILL.md` is the invocation contract; a Claude Code agent reads `SKILL.md` and executes the protocol at skill-trigger time. There is no compiled binary or standalone runner. "Running the skill" means:

```
# In Claude Code — invoke via Skill tool or slash command
/skill-name <arguments>
```

Scripts included in the produced `scripts/` directory (bash, python) are runnable by Claude Code's `Bash` tool and serve as utility helpers (e.g., `validate-graph.sh`, `sync-signal.sh`). They are **not** the primary invocation harness.

**Smoke tests:** `tests/run-smoke-tests.sh` uses a stub `invoke_skill()` function that returns canned strings (offline structural checks only). It cannot test real skill behavior. A `tests/HARNESS-NOTE.md` file (emitted by N-EMIT Step 6.5) explains this limitation and the path to real invocation.

**For integrators:** to test produced-skill behavior end-to-end, invoke it through Claude Code's Skill tool with a representative user prompt, then inspect the output against the V-battery criteria. Stub-based smoke tests validate structure; real invocation validates behavior.

## Detection-pattern Operationalization Examples (F-1.2 fix — Rank-7 audit finding)

When a brief contains constraints of the form **"detect <X>"** — contradictions, topic shifts, mind-changes, supersession, etc. — the brief author SHOULD include 3-5 example pairs covering true-positive, true-negative, and ambiguous cases. Without examples, downstream node protocols (e.g., `N-ANALYZER-CORRECTIONS`) inherit the brief's vagueness and ship with shallow detection algorithms.

**Pattern template:**
```yaml
detection_constraint:
  name: <constraint id, e.g., EDGE-MIND-CHANGE>
  signal_class: <imperative-contradiction | vocabulary-shift | semantic-overlap | other>
  examples:
    - kind: true-positive
      pair: ["<earlier turn>", "<later turn>"]
      verdict: detect
      rationale: <one-sentence>
    - kind: true-negative
      pair: ["<earlier turn>", "<later turn>"]
      verdict: ignore
      rationale: <one-sentence>
    - kind: ambiguous
      pair: ["<earlier turn>", "<later turn>"]
      verdict: emit_conflict_signal_with_advisory
      rationale: <one-sentence>
```

**Reference examples for common detection constraints:**

| Constraint family | true-positive | true-negative | ambiguous |
|---|---|---|---|
| `[EDGE-MIND-CHANGE]` (imperative-phrase contradiction) | (T0: "Always build in Release") + (T7: "Never mind, build Debug") → **detect** (explicit revocation + new imperative) | (T0: "Use TypeScript") + (T7: "I prefer Python for this script") → **ignore** (preference, not directive) | (T0: "Always check inputs") + (T7: "You don't always need to check") → **conflict_signal** (no temporal-resolution evidence; retain both with advisory) |
| `[EDGE-CORRECTIONS]` (correction-language opener) | (T0: "Use GCC") + (T2: "Actually, use Clang") → **detect** (explicit correction opener) | (T0: "Use GCC") + (T2: "Actually GCC has known bugs") → **ignore** (correction opener but reinforces, not overrides) | (T0: "Use GCC") + (T2: "Hmm, what about Clang?") → **conflict_signal** (suggestion, not directive) |
| `[EDGE-TOPIC-SWITCH]` (vocabulary shift) | turns 1-10 about "segfault, gdb, malloc" then T11 "let's design the new auth UI" → **detect** (low overlap + explicit reorientation) | turns 1-10 about "segfault, malloc, valgrind" then T11 "and the heap allocator" → **ignore** (continuation; high overlap) | turns 1-10 about "API design" then T11 "I'm tired, can we resume tomorrow?" → **emit_advisory** (meta-turn; not a real switch but should not be lumped into prior thread) |

**Brief authors:** when adding a new detection constraint, include the table above (or its equivalent) inside the brief's "Edge-Case Handling" section. Producers (the GOTSCS pipeline + downstream node protocols) treat the examples as **acceptance criteria for the implementation, not as exhaustive specification**.

**Adversarial check:** an attacker could plant biased examples that bias detection toward false negatives (e.g., misclassify a true contradiction as "ignore"). Mitigation: require AT LEAST 3 examples per constraint, AT LEAST one of each kind {true-positive, true-negative, ambiguous}; the GOTSCS pipeline's N-CONSTRAINTS step 4.5 (when added) will flag any detection constraint with fewer than 3 categorized examples as `[FRAGMENT: detection-spec incomplete]` and downgrade `brief_quality_advisory` to `fragment_detected`.
