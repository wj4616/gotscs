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
SCHEMA_VALIDATE=""
PRINT_REGISTRY=""
PRINT_EDGES=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)          TARGET="$2"; shift 2 ;;
    --expect-nodes)    EXPECT_NODES="$2"; shift 2 ;;
    --expect-edges)    EXPECT_EDGES="$2"; shift 2 ;;
    --schema-validate) SCHEMA_VALIDATE="1"; shift ;;
    --print-registry)  PRINT_REGISTRY="1"; shift ;;
    --print-edges)     PRINT_EDGES="1"; shift ;;
    -h|--help)
      cat <<EOF
Usage: validate-graph.sh [options]
  --target <skill_dir>      Validate a produced skill's graph.json (default: GOTSCS itself)
  --expect-nodes N          Assert node count == N
  --expect-edges N          Assert edge count == N
  --schema-validate         Run jsonschema validation against graph.schema.json
  --print-registry          Print Node Registry table to stdout (then exit)
  --print-edges             Print Edge Table to stdout (then exit)
  -h, --help                Show this help
EOF
      exit 0 ;;
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

# M5 fix: --print-registry / --print-edges (HC-01 source-of-truth inspection).
if [[ -n "$PRINT_REGISTRY" ]]; then
  python3 - "$GRAPH" <<'PYEOF'
import json, sys
g = json.load(open(sys.argv[1]))
print("# Node Registry (from graph.json — HC-01 source of truth)")
print()
print("| node_id | type | hat | exec_type | tier | wave | conditional |")
print("|---|---|---|---|---|---|---|")
for n in g["nodes"]:
    cond = "yes" if n.get("conditional") else "no"
    print(f"| {n['id']} | {n['type']} | {n['hat']} | {n['exec_type']} | {n.get('tier','-')} | {n.get('wave','-')} | {cond} |")
print()
print(f"Total: {len(g['nodes'])} nodes ({sum(1 for n in g['nodes'] if n.get('conditional')) } conditional)")
PYEOF
  exit 0
fi

if [[ -n "$PRINT_EDGES" ]]; then
  python3 - "$GRAPH" <<'PYEOF'
import json, sys
g = json.load(open(sys.argv[1]))
print("# Edge Table (from graph.json — HC-01 source of truth)")
print()
print("| edge_id | source | target | edge_type | signal_field | gate_condition |")
print("|---|---|---|---|---|---|")
for e in g["edges"]:
    print(f"| {e['id']} | {e['source']} | {e['target']} | {e['edge_type']} | {e.get('signal_field','-')} | {e.get('gate_condition','-')} |")
print()
from collections import Counter
dist = Counter(e["edge_type"] for e in g["edges"])
print(f"Total: {len(g['edges'])} edges  •  distribution: " + ", ".join(f"{k}={v}" for k,v in sorted(dist.items())))
PYEOF
  exit 0
fi

python3 - "$GRAPH" "$EXPECT_NODES" "$EXPECT_EDGES" "$SCHEMA_VALIDATE" <<'PYEOF'
import json, sys, os
path, expect_nodes, expect_edges, schema_validate = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
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
# input_dependencies↔edge-table cross-check (I-02): every node listed in another node's
# input_dependencies must appear as source in at least one edge targeting the dependent node.
dep_gap = []
edge_sources_for_target = {}
for e in d['edges']:
    edge_sources_for_target.setdefault(e['target'], set()).add(e['source'])
for n in d['nodes']:
    for dep in n.get('input_dependencies', []):
        if dep in node_ids:  # only check graph nodes (not system sources like skill_concept_brief)
            sources_to_n = edge_sources_for_target.get(n['id'], set())
            if dep not in sources_to_n:
                dep_gap.append(f"{dep}→{n['id']} (in input_dependencies but no edge)")
if dep_gap:
    print(f"WARN: {len(dep_gap)} input_dependency claim(s) have no corresponding edge:", file=sys.stderr)
    for gap in dep_gap: print(f"  {gap}", file=sys.stderr)
if expect_nodes:
    assert len(ids) == int(expect_nodes), f"node count {len(ids)} != {expect_nodes}"
if expect_edges:
    assert len(eids) == int(expect_edges), f"edge count {len(eids)} != {expect_edges}"
print(f"PRC1 PASS: {len(ids)} nodes ({conditional_count} conditional), {len(eids)} edges")
# --schema-validate: validate graph.json against graph.schema.json using jsonschema
if schema_validate:
    schema_path = os.path.join(os.path.dirname(path), 'graph.schema.json')
    if not os.path.isfile(schema_path):
        print(f"WARN: --schema-validate: graph.schema.json not found at {schema_path}; skipping", file=sys.stderr)
    else:
        try:
            import jsonschema
            schema = json.load(open(schema_path))
            jsonschema.validate(instance=d, schema=schema)
            print("SCHEMA PASS: graph.json validates against graph.schema.json")
        except ImportError:
            print("WARN: jsonschema package not available; falling back to manual enum checks", file=sys.stderr)
            # Manual enum checks for closed-vocab fields
            valid_types = {"PREFLIGHT","INGEST","ANALYZER","DECOMPOSITION","AGGREGATION","GATE","GENERATOR","PLANNER","SYNTHESIS","FORMATTER","VERIFIER","PERSISTER","TAILOR","XREF","LATERAL","DEFIXATION","SIMULATION","PRECISION","ADVERSARIAL","CONJECTURE","ROUTER","ATTACKER","EXPANSION","CLASSIFIER","META-ANALYZER","RECOVERY","FILTER","TRIAGE","ACTUATOR","IO","VALIDATOR","SCORER","REFINER"}
            valid_exec = {"inline","spawn"}
            valid_tiers = {"model-small","model-medium","model-large","no-llm"}
            valid_hats = {"gate","extractor","analyzer","aggregator","generator","formatter","verifier","persister","no-llm","tailor","expander","lateral","filter","validator"}
            valid_edges = {"required","optional","gate-open","forward-conditional","back-edge","terminal"}
            errs = []
            for n in d['nodes']:
                if n['type'] not in valid_types: errs.append(f"node {n['id']}: invalid type={n['type']!r}")
                if n['exec_type'] not in valid_exec: errs.append(f"node {n['id']}: invalid exec_type={n['exec_type']!r}")
                if n['tier'] not in valid_tiers: errs.append(f"node {n['id']}: invalid tier={n['tier']!r}")
                if n['hat'] not in valid_hats: errs.append(f"node {n['id']}: invalid hat={n['hat']!r}")
            for e in d['edges']:
                if e['edge_type'] not in valid_edges: errs.append(f"edge {e['id']}: invalid edge_type={e['edge_type']!r}")
            if errs:
                print(f"SCHEMA FAIL: {len(errs)} enum violation(s):", file=sys.stderr)
                for err in errs: print(f"  {err}", file=sys.stderr)
                sys.exit(1)
            print("SCHEMA PASS: manual enum checks passed")
        except jsonschema.ValidationError as e:
            print(f"SCHEMA FAIL: {e.message}", file=sys.stderr)
            sys.exit(1)
PYEOF
