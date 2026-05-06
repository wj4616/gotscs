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
