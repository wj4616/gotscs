#!/usr/bin/env bash
# GOTSCS v4.1.0 — regression test suite (NEW per Goal-6 / DD-10)
# Purpose: structural mutation-kill tests on graph.json modifications.
# Target: ≥80% kill rate on injected mutations.

set -uo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE="$SKILL_DIR/tests/run-smoke-tests.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

KILL_TARGET=$(python3 -c "import json; print(int(json.load(open('$SKILL_DIR/graph.json'))['metadata'].get('mutation_kill_target', 0.80) * 100))" 2>/dev/null || echo 80)

echo "GOTSCS v4 regression suite — $(date)"
echo "Target: ≥${KILL_TARGET}% mutation-kill rate on graph.json"
echo ""

# --- Backup original graph.json ---
cp "$SKILL_DIR/graph.json" "$TMP_DIR/graph.json.original"

KILLED=0
TOTAL=0

run_mutation() {
  local NAME="$1"
  local MUTATION="$2"
  TOTAL=$((TOTAL + 1))
  GRAPH_SOURCE="$TMP_DIR/graph.json.original" python3 -c "$MUTATION" > "$SKILL_DIR/graph.json"
  if bash "$SMOKE" >/dev/null 2>&1; then
    echo "MUTATION SURVIVED (NOT KILLED): $NAME"
  else
    echo "MUTATION KILLED:               $NAME"
    KILLED=$((KILLED + 1))
  fi
  cp "$TMP_DIR/graph.json.original" "$SKILL_DIR/graph.json"
}

# --- Mutation 1: drop a node (should fail node count check) ---
run_mutation "drop-node-N-EMIT" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
g['nodes'] = [n for n in g['nodes'] if n['id'] != 'N-EMIT']
print(json.dumps(g, indent=2))
"

# --- Mutation 2: drop an edge (should fail edge count check) ---
run_mutation "drop-edge-E29" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
g['edges'] = [e for e in g['edges'] if e['id'] != 'E29']
print(json.dumps(g, indent=2))
"

# --- Mutation 3: add a node beyond cap (should fail HC-02) ---
run_mutation "add-node-21st" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
g['nodes'].append({'id': 'N-EXTRA', 'type': 'GATE', 'exec_type': 'inline', 'hat': 'gate', 'tier': 'model-small', 'wave': 1, 'scale_gates': {'token_budget': 100, 'time_budget': 10, 'spawn_budget': 0, 'retry_budget': 0}, 'input_dependencies': [], 'raises_signals': []})
print(json.dumps(g, indent=2))
"

# --- Mutation 4: corrupt edge_type with non-closed-vocab value (HC-03) ---
run_mutation "edge-type-drift-E1" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
for e in g['edges']:
    if e['id'] == 'E1':
        e['edge_type'] = 'bogus-type'
print(json.dumps(g, indent=2))
"

# --- Mutation 5: corrupt hat with non-closed-vocab value (HC-04) ---
run_mutation "hat-drift-N-EMIT" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
for n in g['nodes']:
    if n['id'] == 'N-EMIT':
        n['hat'] = 'bogus-hat'
print(json.dumps(g, indent=2))
"

# --- Mutation 6: drop one of the v4 new back-edges ---
run_mutation "drop-v4-backedge-E50" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
g['edges'] = [e for e in g['edges'] if e['id'] != 'E50']
print(json.dumps(g, indent=2))
"

# --- Mutation 7: change exec_type to invalid value ---
run_mutation "exec-type-drift-N-PREFLIGHT" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
for n in g['nodes']:
    if n['id'] == 'N-PREFLIGHT':
        n['exec_type'] = 'remote'
print(json.dumps(g, indent=2))
"

# --- Mutation 8: malformed JSON ---
run_mutation "malformed-json" "
import json
print('not valid json{')
"

# --- Mutation 9: drop conditional flag from N-CONTEXT-ANALYZE (changes conditional count) ---
run_mutation "drop-conditional-flag" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
for n in g['nodes']:
    if n['id'] == 'N-CONTEXT-ANALYZE':
        n.pop('conditional', None)
print(json.dumps(g, indent=2))
"

# --- Mutation 10: change spawn count by promoting an inline node ---
run_mutation "spawn-count-drift" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
for n in g['nodes']:
    if n['id'] == 'N-EMIT':
        n['exec_type'] = 'spawn'
print(json.dumps(g, indent=2))
"

# --- Mutation 11: drop N-CONTEXT-ANALYZE topology-fix edge E53 (should fail E53 presence check) ---
run_mutation "drop-topology-fix-edge-E53" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
g['edges'] = [e for e in g['edges'] if e['id'] != 'E53']
print(json.dumps(g, indent=2))
"

# --- Mutation 12: drop N-JSON→N-SKILL-RENDER required edge E57 (should fail E57 presence check) ---
run_mutation "drop-required-edge-E57" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
g['edges'] = [e for e in g['edges'] if e['id'] != 'E57']
print(json.dumps(g, indent=2))
"

# --- Mutation 13: inject duplicate back-edge to N-AGG-DESIGN (F004 de-dup invariant) ---
# Adds E51-CLONE with same gate as E50 — edge count jumps to 60; smoke test expects 59.
# Guards: if E50/E51 de-dup is removed, a duplicate concurrent back-edge could be introduced.
run_mutation "e50-e51-concurrent-duplicate-backedge" "
import json
g = json.load(open(__import__('os').environ['GRAPH_SOURCE']))
clone = {'id': 'E51-CLONE', 'source': 'N-VERIFY', 'target': 'N-AGG-DESIGN',
         'edge_type': 'back-edge', 'signal_field': 'verify_pass',
         'gate_condition': \"verify_pass == false AND retry_count_artifact < 1 AND 'registry_v13d_fail' in repair_targets\"}
g['edges'].append(clone)
g['metadata']['total_edges'] = len(g['edges'])
print(json.dumps(g, indent=2))
"

cp "$TMP_DIR/graph.json.original" "$SKILL_DIR/graph.json"

KILL_RATE=$(echo "scale=2; $KILLED * 100 / $TOTAL" | bc)
echo ""
echo "REGRESSION SUITE RESULT: $KILLED / $TOTAL killed ($KILL_RATE%)"

THRESHOLD_PASS=$(echo "$KILL_RATE >= $KILL_TARGET" | bc)
if [ "$THRESHOLD_PASS" = "1" ]; then
  echo "PASS: kill rate ≥${KILL_TARGET}% (mutation_kill_target from graph.json met)"
  exit 0
else
  echo "FAIL: kill rate <${KILL_TARGET}% (mutation_kill_target from graph.json missed)"
  exit 1
fi
