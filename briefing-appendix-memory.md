# briefing-appendix-memory — H.5 Memory and Retention Rules + H.6 Traceability Rules

Loaded by: N-AGG-DESIGN, N-SYNTH-GRAPH (and N-VERIFY's full-appendix load).

## H.5 Memory and Retention Rules

**MUST:**
- Hold every per-document node record in working context for the duration of the run; no node may be evicted, compressed, or summarized away during aggregation/synthesis/validation.
- Persist full per-node output to disk (stage files, on-disk SIGNAL_STATE keys, per-node module files); orchestrator may dispatch only a digest, but full content remains recoverable.
- Use append-only invariants (`SIGNAL_STATE`, `executed_nodes`, `gate_history`) wherever possible — never overwrite a key.

**MUST NOT:**
- Maximize per-node prose verbosity at the expense of cross-node retention. Per-node verbosity is capped per the prose budget; cross-node retention is unconditional.
- Store any orchestrator-derived summary that mutates an earlier node's record. Compare/contrast outputs go to **new** nodes, never overwrite source records.

`cites_nodes:` N-1, N-3, N-5, N-11, N-12, N-13 + the prompt's own constraints

## H.6 Traceability Rules

**`cites_nodes` field format (forms allowed):**
- Corpus-grounded: `cites_nodes: [N-3, N-7]`
- Role-knowledge-grounded: `cites_nodes: [role_knowledge:<topic>]` where `<topic>` ∈ closed whitelist below.
- Mixed: `cites_nodes: [N-3, role_knowledge:cognitive_engineering]`

**`role_knowledge` whitelist (CLOSED — verbatim copy):**

1. `got_topology` — published Graph-of-Thought / Tree-of-Thought / Chain-of-Thought research (Besta et al. and equivalent).
2. `prompt_engineering_techniques` — XML structuring, decomposition, role binding, output format templates, structured reasoning, priority hierarchy, edge case spec, few-shot, self-critique, anchoring, audience calibration, escape hatches.
3. `cognitive_engineering` — Self-Refine, Constitutional, Constraint Escape, Precision Forcing, Falsification, Intuition-Verification Partnership.
4. `skill_system_design` — skill manifests, modules, validators, orchestrators.
5. `agent_runtime_capabilities` — parallel dispatch, sub-agent spawning, KB MCP integration, hooks.

**Forbidden:**
- Bare `derived_from` as a citation field (use `cites_nodes`).
- `role_knowledge:<topic>` outside the whitelist (mark as `unknown` instead).
- Uncited synthesis claims.

`cites_nodes:` N-1, N-3, N-9, N-13 + role_knowledge:prompt_engineering_techniques

