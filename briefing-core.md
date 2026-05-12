# GOTSCS Briefing — H.1-H.9 Schema Reference (v4.3.0)

This file is read by all spawn subagents at the start of their protocol (HC-13b module-delegation).

## Node Quickref (v4.3.0 — 20 nodes, 3 conditional, 64 edges, 10 Waves)

| Node ID | Wave | Hat | Type | Brief |
|---------|------|-----|------|-------|
| N-PREFLIGHT | 1 | gate | PREFLIGHT | Validate + classify input (6 input classes); v4.3 adds evolution_mode resolution |
| N-NORMALIZE | 2 | extractor | INGEST | Extract structured skill fields |
| N-CONTEXT-ANALYZE | 2 | analyzer | ANALYZER | (conditional) Context skill/spec archaeology; v4.3 emits context_advisory + redesign_candidates in evolve mode |
| N-FUSION-ANALYZE | 2 | aggregator | AGGREGATION | **v4.3 NEW (conditional, evolve mode only):** Synthesize brief + spec + skill via P1>P2>P3>P4 precedence; emit fusion_plan + fusion_decisions + 11-section payload |
| N-TOPOLOGY | 3 | analyzer | ANALYZER | H.3 topology decision tree |
| N-DECOMPOSE | 3 | analyzer | DECOMPOSITION | Node type decomposition; v4.3 adds 8-category task taxonomy + atomicity arithmetic |
| N-CONSTRAINTS | 3 | analyzer | ANALYZER | Constraint inventory + AP catalogue; v4.3 mode-dependent emission (hard/soft/fusion_constraints FC-01..FC-09) |
| N-AGG-DESIGN | 4 | aggregator | AGGREGATION | Mid-graph synthesis (HG1); v4.3 consumes fusion_plan as authoritative seed + emits fusion_task_trace |
| N-DESIGN-GATE | 5 | gate | GATE | Pre-artifact HC-08 quality gate; v4.3 evolve-mode addendum (FC-04 + FC-07 verification) |
| N-REGISTRY | 6 | generator | GENERATOR | Node Registry table |
| N-EDGES | 6 | generator | GENERATOR | Edge Table (H.2 closed vocab) |
| N-WAVES | 6 | analyzer | PLANNER | Wave Plan + Mode Matrix |
| N-SYNTH-GRAPH | 7 | aggregator | SYNTHESIS | type=SYNTHESIS (HC-16/AP-06) |
| N-SPEC-ARTIFACT | 8 | formatter | FORMATTER | Mode-conditional spec rendering |
| N-MODULES | 9 | generator | GENERATOR | **v3.1.0 (P-001):** Per-file module emission to stages/modules/<id>.md |
| N-JSON | 9 | formatter | FORMATTER | graph.json + hats.json + graph.schema.json serialization |
| N-SKILL-RENDER | 9 | formatter | FORMATTER | **v3.1.0 (P-002):** Dedicated SKILL.md renderer; assembles §0–§8 (v4.2 inlined RUNTIME CONVENTIONS per DD-11) |
| N-VERIFY | 10 | verifier | VERIFIER | V-battery (V1-V25 + V26 a/b/c/d/e/f evolve-mode residual) + H.4 contract; **V11 + V5-ext BLOCKING (P-003)** |
| N-EMIT | 10 | persister | PERSISTER | Write skill files; **v4.2 (P-004): post-emit smoke test gate**; v4.3 step 4.4 emits FUSION.md + REGRESSION.md in evolve mode |
| N-BEHAVIORAL | 10 | verifier | VERIFIER | **v3.1.0 (P-006, conditional):** Behavioral acceptance test of produced skill (advisory) |

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

## H.7b — Spawn-count metadata fields (G-07)

graph.json `metadata` contains two distinct spawn metrics. N-JSON step 1.5(c3) computes both; N-VERIFY V8 checks both:

| field | meaning | HG-07 uses |
|---|---|---|
| `spawn_node_count` | Total nodes with `exec_type=spawn` in graph.json | No (informational) |
| `max_concurrent_spawns_per_run` | Maximum active-spawn count across all valid mode combinations | **Yes** — HG-07 cap (≤7 verbose/strict-verify) |

Brief-claimed `static_spawns` is an advisory input only; N-JSON serializer overrides unconditionally and logs the comparison. When brief claims and computed disagree: informational `audit_log` entry only, no halt.

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
| HC-02 | 20-NODE CAP | Produced skills: ≤30 nodes, ≤15 waves, ≤100 edges (≤36/≤18/≤120 under `--evolve-aggressive` waiver; ≤40/≤20/≤150 under `--complex`). GOTSCS itself uses an internal cap of ≤65 edges per v4.3 schema (added E60-E64 fusion edges). Fewer is fine if functionality preserved. |
| HC-03 | CLOSED-EDGE-VOCAB | 6 runtime edge types only: required, optional, gate-open, forward-conditional, back-edge, terminal. No inventions. |
| HC-04 | CLOSED-NODE-TYPE-VOCAB | H.1 typed enum above is canonical. No invented node types. |
| HC-06 | V-BATTERY-COMPLETENESS | Every V1-V25 check preserved or explicitly replaced with an equivalent. v4.3 adds V26 (a/b/c/d/e/f) evolve-mode residual battery: a/b/c/d/f BLOCKING in evolve mode, e ADVISORY. |
| HC-08 | NON-DETERMINISM | Pipeline is non-deterministic; do not attempt to force determinism. |
| HC-09 | INPUT-CLASS-COMPLETENESS | All 6 input classes remain (ec-brief, ec-skill, ec-spec, ec-both, ec-refeed, ec-inject). |
| HC-10 | FLAG-PRESERVATION | `--skill`, `--spec`, `--both`, `--context`, `--context-spec`, `--reuse-session`, `--behavioral-test`, `--review-gates` all preserved. v4.3 ADDITIONS (purely additive, default-off): `--strict`, `--evolve`, `--evolve-aggressive`, `--waiver-justification`, `--no-fusion-doc`, `--context-type`, `--context-spec-type`, `--no-post-audit`. |
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

---

## §EVOLVE — v4.3 Evolve-Mode Schema Extension (NEW v4.3 Phase 4)

This section documents the schema extensions introduced by v4.3.0 evolution-spec implementation. It is loaded by N-FUSION-ANALYZE, N-CONSTRAINTS, N-DECOMPOSE, and N-AGG-DESIGN when `evolution_mode in {evolve, evolve-aggressive}`. Skills produced under `evolution_mode in {overlay, greenfield}` continue to inherit the pre-v4.3 H.1-H.9 schema unchanged.

### EVOLVE-1 — evolution_mode taxonomy

A GOTSCS run is classified into exactly one of four `evolution_mode` values, resolved by N-PREFLIGHT step 4a from `contexts_provided_count` and the `--strict` / `--evolve` / `--evolve-aggressive` flag set:

| Value | Activation | Pipeline behavior |
|---|---|---|
| `greenfield` | 0 contexts (no `--context` AND no `--context-spec`) | v4.2 baseline; N-CONTEXT-ANALYZE skipped; N-FUSION-ANALYZE skipped. |
| `overlay` | 1 context, OR 2+ contexts with `--strict`, OR `ec-refeed` regardless of flags | v4.2 baseline preserved byte-for-byte; N-CONTEXT-ANALYZE emits legacy `preservation_contract`; N-FUSION-ANALYZE skipped. AP-15 (no replacement without defect) in full force. |
| `evolve` | 2+ contexts (DEFAULT) OR explicit `--evolve` | v4.3 fusion pipeline active; N-CONTEXT-ANALYZE downgrades to `context_advisory` + `redesign_candidates`; N-FUSION-ANALYZE synthesizes `fusion_plan`; mode-dependent emission in N-CONSTRAINTS / N-DECOMPOSE / N-AGG-DESIGN. Standard HC-02 caps in produced skills (≤30 nodes / ≤15 waves / ≤100 edges). |
| `evolve-aggressive` | 2+ contexts AND `--evolve-aggressive --waiver-justification "<≥50 chars>"` | Same as `evolve` plus relaxed HC-02 caps in produced skills (≤36 nodes / ≤18 waves / ≤120 edges). Waiver justification persisted to `stages/waiver_justification.txt`, FUSION.md, and produced graph.json metadata (FC-09). |
| `complex` | explicit `--complex` (no contexts required) | greenfield/overlay pipeline with relaxed HC-02 caps in produced skills (≤40 nodes / ≤20 waves / ≤150 edges). NO fusion pipeline; N-FUSION-ANALYZE skipped; N-CONTEXT-ANALYZE runs in legacy preservation_contract mode. No waiver justification required. |

### EVOLVE-2 — Precedence stack (P1 > P2 > P3 > P4)

When in `evolve` or `evolve-aggressive` mode, conflicts across context sources are resolved by N-FUSION-ANALYZE step 6 using a strict ladder:

| Priority | Source | Authority | Override rule |
|---|---|---|---|
| P1 | `design_brief` (the user's prompt text) | Optimization objective — wins | Cannot violate universal hard constraints (HC-02 caps ≤30/≤15/≤100 standard, ≤40/≤20/≤150 under `--complex`, HC-03 edge typology, HC-04 schema enums, any HC tagged `class: SECURITY` / `class: PRIVACY`); halt-on-brief-violation if attempted. |
| P2 | `spec_enhancement` (`--context-spec`) | Design intent | Wins when brief is silent on the conflict. |
| P3 | `skill_executable` (`--context`) | Reference implementation | Wins when brief AND spec are both silent. |
| P4 | GOTSCS defaults / H.1-H.9 schema | Baseline | Fallback only. |

Every override decision is recorded in `fusion_decisions[]` with `{conflict_id, winning_source, losing_source, rationale, brief_quote_or_null, external_contract_locked}`.

### EVOLVE-3 — External-contract item registry (cross-reference)

Items that constitute the skill's **external contract** default to `resolved_action: preserve` regardless of P1/P2 silence on internal details — this is the FC-04/FC-05 enforcement floor. The canonical 5-category enumeration is in `briefing-appendix-contract.md §EC-FC04` (registry IDs EC-FC04-1 through EC-FC04-5):

- EC-FC04-1: Invocation signature (CLI flags + positional args)
- EC-FC04-2: Output schema (required artifact frontmatter / JSON schema fields)
- EC-FC04-3: Universal hard constraints (HC-02/03/04 + SECURITY/PRIVACY-class HC items)
- EC-FC04-4: Stable signal names (multi-consumer signal_field broadcasts)
- EC-FC04-5: Sink identifiers (graph.json metadata.sinks[])

Override format: brief includes `contract_override: EC-FC04-<N> — <reason>` to authorize divergence; rationale persists into `fusion_decisions[]` with `external_contract_overridden: true`.

### EVOLVE-4 — Fusion constraint catalogue (FC-01 through FC-09)

When in `evolve` or `evolve-aggressive` mode, N-CONSTRAINTS step 6 emits these 9 constraints (in addition to the legacy `inventory_items` / `anti_patterns_guarded` / `ai_advantages_selected`). Cross-cutting; consumed by N-AGG-DESIGN step 1.5 + N-VERIFY V26:

| FC ID | Constraint | Enforcement node |
|---|---|---|
| FC-01 | Every divergence from original MUST be documented in `fusion_decisions[]` | N-FUSION-ANALYZE step 7 |
| FC-02 | If brief is silent on a design question, prefer spec over original skill | N-FUSION-ANALYZE step 6 (precedence default) |
| FC-03 | If brief contradicts both spec and original, brief wins — but MUST include `risk_acknowledgment` in `fusion_task_trace` row | N-AGG-DESIGN step 6e + V26(d) |
| FC-04 | INVENTORY items inherited as candidates, not mandates, EXCEPT external-contract items per `briefing-appendix-contract §EC-FC04` | N-FUSION-ANALYZE step 6 external-contract guard |
| FC-05 | Backward compatibility advisory for internal details, MANDATORY for external behavior unless `--strict` OR `contract_override` | N-FUSION-ANALYZE step 6 + N-AGG-DESIGN step 6b |
| FC-06 | Optimization for final utility is the primary objective | N-AGG-DESIGN synthesis |
| FC-07 | When replacing a node, the new node MUST satisfy all functional contracts of the old node unless brief explicitly redefines them | N-VERIFY V26(c) |
| FC-08 | Every redesign MUST have a corresponding regression test in the smoke-test battery | N-EMIT step 4.4 + N-VERIFY V26(e) (advisory) |
| FC-09 | `--evolve-aggressive` requires `waiver_justification` ≥50 chars persisted in FUSION.md + graph.json metadata | N-PREFLIGHT step 4a + N-VERIFY V26(f) |

### EVOLVE-5 — 8-category task taxonomy

When in `evolve` or `evolve-aggressive` mode, N-DECOMPOSE step 6 decomposes every concrete item in `unified_topology` (countable_topology = nodes_proposed ∪ edges_proposed ∪ aggregation_carriers_proposed) into exactly one task in this closed-vocab set:

| Category | Source (fusion_plan) | Description |
|---|---|---|
| `preserve` | preservation_map | Byte-identical retention; verify equality at V-battery |
| `upgrade` | divergence_map; node_id preserved | Modify in-place; preserve node_id + ports + hat/tier |
| `replace` | divergence_map; node_id changes | Drop + reimplement under FC-07 contract |
| `merge` | divergence_map; multiple originals → one new | Combine multiple original nodes; union of contracts |
| `add` | divergence_map; not in original | Net-new node from spec or brief |
| `remove` | divergence_map; in original but not unified | Drop original; downstream re-routed |
| `resequence` | divergence_map; same node_id, different wave | Move to different wave; protocol unchanged |
| `recontract` | divergence_map; same node_id, changed aggregation_policy / port shape | Change contract without renaming; most fragile |

Atomicity rule: `sum(8 category counts) == |countable_topology|`. Halt-decompose-task-arithmetic-fail on mismatch.

### EVOLVE-6 — Phase 4 release rollback trigger

Per spec §8 Phase 4 step 6: **if ≥1 overlay-mode skill fails regression within 48 hours of v4.3.0 release, revert to v4.2.x and freeze the v4.3 branch until the failure is root-caused.** The rollback procedure is mechanical and operates on a single set of files (the `tests/run-smoke-tests.sh` and `tests/run-regression-suite.sh` are overwritten in-place when v4.3 replaced v4.2 — there are NOT two separate suites on disk simultaneously):

1. Restore every v4.2.0 file from the SHA-256 baseline at `/tmp/gotscs-v4.2.0-baseline.sha256`. Walk the manifest (29 entries); for each entry whose current sha256 differs, restore from the v4.2.x backup directory created during the HC-26 pre-release backup step.
2. Run the now-restored `tests/run-smoke-tests.sh` (will revert to 41 tests / v4.2 expected counts 19/59/2-conditional/11-spawn) and `tests/run-regression-suite.sh` (14 mutations).
3. Re-engagement of v4.3 requires (a) root cause addressed AND (b) fresh 5-brief regression battery per HC-26 RELEASE-SAFETY-GATE — run GOTSCS end-to-end on 5 distinct briefs covering ec-brief / ec-skill / ec-spec / ec-both-strict / ec-both-evolve paths. (HC-13b is a separate constraint covering subagent module-delegation reads, NOT the regression battery.)

`cites_nodes:` N-PREFLIGHT, N-CONTEXT-ANALYZE, N-FUSION-ANALYZE, N-CONSTRAINTS, N-DECOMPOSE, N-AGG-DESIGN, N-VERIFY, N-EMIT, N-SKILL-RENDER + role_knowledge:fusion_topology, role_knowledge:precedence_resolution
