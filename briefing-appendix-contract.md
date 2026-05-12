# briefing-appendix-contract — H.4 Validation Contract Template

Loaded by: N-DESIGN-GATE.

## H.4 Validation Contract Template

**Four-check contract:**

```yaml
synthesis_id: <unique>
revision: 0   # incremented to 1 on revision; capped at 1
checks:
  logic_check: PASS | FAIL
  validity_check: PASS | FAIL
  falsifiability_check: PASS | FAIL  # MUST construct an active falsifier and record it
  coherence_check: PASS | FAIL
overall: PASS | FAIL
falsifying_edge_case_attempted: <verbatim adversarial scenario>
route: assembly | revise | discarded
revision_history:
  - revision: 1
    failed_checks_addressed: ["<check_id>"]
    diff_from_original: "<one-line summary>"
```

**Per-pipeline V-battery (verifier node ownership):** every generated skill MUST own a verifier node that runs at minimum:
1. output well-formedness
2. graph-trace edge integrity (fired edges ⊆ declared edges)
3. topology-driven execution / no-improvisation (V8-style; see contradicts edge N-1↔N-3)
4. adversarial counter-argument survival
5. byte-for-byte verbatim guard for scope-defining sections

`cites_nodes:` N-1, N-3, N-5, N-6, N-8, N-11, N-12, N-13, N-14 + role_knowledge:cognitive_engineering

---

## EC-FC04 — External-Contract Item Registry (v4.3 evolve-mode FC-04 enforcement)

When GOTSCS runs in `evolution_mode in {evolve, evolve-aggressive}` and N-FUSION-ANALYZE applies the FC-04 / FC-05 external-contract guard (per evolution-spec §3.7), the following 5 categories enumerate what counts as an external-contract item. Items in this registry default to `resolved_action: preserve` and require an explicit `contract_override:` rationale in the brief to diverge.

Items NOT in this registry are *internal* implementation details and may be freely diverged in evolve mode (subject to precedence stack + risk_assessment + regression_risk annotation).

| ID | Category | Definition | Authoritative source in original skill |
|---|---|---|---|
| EC-FC04-1 | Invocation signature | Every CLI flag + positional argument named in SKILL.md `## Invocation Contract` (or equivalent invocation-surface section). Removing or renaming a flag breaks callers. | SKILL.md frontmatter + invocation prose |
| EC-FC04-2 | Output schema | Every required top-level field in produced artifact frontmatter or JSON schema (e.g. `report_id`, `mode`, `audit_target`, `metadata.skill_name`, `metadata.version`). Type changes break consumers. | produced-artifact schema files; SKILL.md output-format prose |
| EC-FC04-3 | Universal hard constraints | Every HC-* identifier in the original skill's HARD GATES section that is also in the universal closed-vocab set: HC-02 topology caps (≤30/≤15/≤100 standard, ≤36/≤18/≤120 under --evolve-aggressive, ≤40/≤20/≤150 under --complex), HC-03 edge typology, HC-04 closed-vocab schema enums, plus any HC-* tagged `class: SECURITY` or `class: PRIVACY`. | SKILL.md §HARD GATES; H.4 contract |
| EC-FC04-4 | Stable signal names | signal_field values that appear on edges in the original graph AND are referenced by ≥2 consuming nodes' input_ports schemas. Renaming a multi-consumer signal breaks the broadcast. | graph.json edges[].signal_field × nodes[].input_ports |
| EC-FC04-5 | Sink identifiers | Every entry in `metadata.sinks[]` of the original graph.json. Removing a sink breaks downstream pipelines that consume terminal outputs. | graph.json metadata.sinks[] |

**Override format.** A brief may override any registry item by including a literal `contract_override:` declaration referencing the item by ID. Example:
```
contract_override: EC-FC04-1 — Renaming --context to --reference-skill is intended; v5 callers will migrate.
```
The override rationale is persisted verbatim into `fusion_decisions[]` and surfaces in `FUSION.md` (Phase 3) under the divergence_map's `external_contract_overridden` flag.

**Cross-references:**
- N-FUSION-ANALYZE.md §Protocol step 6 (consumes this registry)
- evolution-spec §3.7 FC-04, FC-05 (origin)
- N-CONSTRAINTS.md (Phase 2 — will read this registry to compose `fusion_constraints[]`)

