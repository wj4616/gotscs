#!/usr/bin/env bash
# PRC1 — validate graph.json structure at skill startup
# Reports total + conditional node count distinctly per HC-20 / SD-05
#
# Usage:
#   validate-graph.sh [--expect-nodes N] [--expect-edges M]              (validates GOTSCS itself)
#   validate-graph.sh --target <skill_dir> [--expect-nodes N] [--expect-edges M]  (P-008: validate any produced skill)
#
# When --target <skill_dir> is given, the script validates <skill_dir>/graph.json
# instead of GOTSCS's own graph.json. This lets one validator catch graph drift
# in any GOTSCS-produced skill without duplicating the validation logic.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""
EXPECT_NODES=""
EXPECT_EDGES=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)        TARGET="$2"; shift 2 ;;
    --expect-nodes)  EXPECT_NODES="$2"; shift 2 ;;
    --expect-edges)  EXPECT_EDGES="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -n "$TARGET" ]]; then
  # Resolve target to absolute path; accept either a skill directory or a graph.json path.
  if [[ -d "$TARGET" ]]; then
    GRAPH="$TARGET/graph.json"
  elif [[ -f "$TARGET" ]]; then
    GRAPH="$TARGET"
  else
    echo "validate-graph.sh: --target path does not exist: $TARGET" >&2
    exit 2
  fi
  echo "Validating produced skill graph: $GRAPH"
else
  GRAPH="$SKILL_DIR/graph.json"
fi

if [[ ! -f "$GRAPH" ]]; then
  echo "validate-graph.sh: graph.json not found at $GRAPH" >&2
  exit 1
fi

python3 - "$GRAPH" "$EXPECT_NODES" "$EXPECT_EDGES" <<'PYEOF'
import json, sys
path, expect_nodes, expect_edges = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(path))
assert 'nodes' in d and 'edges' in d and 'metadata' in d, "missing top-level keys"
ids = [n['id'] for n in d['nodes']]
assert len(ids) == len(set(ids)), "duplicate node IDs"
eids = [e['id'] for e in d['edges']]
assert len(eids) == len(set(eids)), "duplicate edge IDs"
node_ids = set(ids)
sinks = set(d.get('metadata', {}).get('sinks', []))
# Edges may originate from system inputs (skill_concept_brief) — accept these as valid sources.
system_sources = {"skill_concept_brief"}
valid_targets = node_ids | sinks
for e in d['edges']:
    assert e['target'] in valid_targets, f"undeclared edge target: {e['target']}"
    assert e['source'] in (node_ids | system_sources), f"undeclared edge source: {e['source']}"
conditional_count = sum(1 for n in d['nodes'] if n.get('conditional') is True)
# v4.1: prune-unconnected check (advisory)
in_degree = {n: 0 for n in node_ids}
out_degree = {n: 0 for n in node_ids}
for e in d['edges']:
    if e['source'] in node_ids:
        out_degree[e['source']] += 1
    if e['target'] in node_ids:
        in_degree[e['target']] += 1
unconnected = [n for n in node_ids if in_degree[n] == 0 and out_degree[n] == 0]
if unconnected:
    print(f"WARN: {len(unconnected)} unconnected node(s): {unconnected}", file=sys.stderr)
if expect_nodes:
    assert len(ids) == int(expect_nodes), f"node count {len(ids)} != {expect_nodes}"
if expect_edges:
    assert len(eids) == int(expect_edges), f"edge count {len(eids)} != {expect_edges}"
print(f"PRC1 PASS: {len(ids)} nodes ({conditional_count} conditional), {len(eids)} edges")
PYEOF
