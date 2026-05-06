# briefing-appendix-topology — H.3 Topology Decision Tree

Loaded by: N-TOPOLOGY only (per per-node read-map).

## H.3 Topology Decision Tree

```
INPUT FEATURES:
  fan_out_branches: int
  refinement_loops_needed: bool
  cross_branch_convergence: bool
  scale_tier: MINIMAL | STANDARD | DEEP
  artifact_classes_supported: int

DECISION:
  IF fan_out_branches <= 1 AND NOT refinement_loops_needed AND NOT cross_branch_convergence:
      topology = "Chain-of-Thought (CoT)"
  ELIF fan_out_branches > 1 AND NOT cross_branch_convergence:
      topology = "Tree-of-Thought (ToT)"
  ELIF cross_branch_convergence AND NOT refinement_loops_needed:
      topology = "Graph-of-Thought (basic GoT)"
  ELIF cross_branch_convergence AND refinement_loops_needed:
      topology = "Graph-of-Thought with bounded back-edges (full GoT)"
  ELIF scale_tier in {STANDARD, DEEP} AND fan_out_branches >= 3:
      topology = "Wave-Modular GoT"

NOTE: when cross_branch_convergence AND refinement_loops_needed AND
  scale_tier in {STANDARD, DEEP} AND fan_out_branches >= 3 are ALL true,
  "Graph-of-Thought with bounded back-edges" takes precedence (ELIF ordering),
  but the skill SHOULD ALSO organize its Waves in a Wave-modular pattern —
  the topologies are compatible and composable. Document this decision as a
  Section 4 Wave Plan annotation: "topology: full GoT + Wave-modular."

ALWAYS:
  emit graph.json with PRC1 validator
  emit V-battery owned by an explicit verifier node
  declare exec_type per node
  use closed edge-type vocabulary from H.2
```

## Appendix: Mapping Linear Pipelines to GoT (NEW v4.1)

When `pipeline_class=linear-pipeline` (from N-CONTEXT-ANALYZE), apply these mapping rules:
1. Sequential steps → sequential nodes with `required` edges.
2. Mode dispatch points → single ROUTER node + `forward-conditional` edges per mode.
3. Internal parallel analysis → fan-out sub-nodes under an AGGREGATION node.
4. Do NOT model I/O parsing, flag detection, or sufficiency checks as separate graph nodes unless the source skill explicitly defines them as such.

Rationale: avoids inflating node counts with artificial structural nodes that don't exist in the source skill's design.

`cites_nodes:` N-6, N-14 + role_knowledge:got_topology

