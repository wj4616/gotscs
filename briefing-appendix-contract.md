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

