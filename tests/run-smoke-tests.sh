#!/usr/bin/env bash
# GOTSCS v4.0.0 — smoke tests
# Purpose: structural validity check. Run after every install / change.
# Exits 0 if all checks pass; 1 otherwise.

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
pass()  { echo "PASS: $1"; }
fail()  { echo "FAIL: $1"; FAIL=1; }
check() { [ "$1" = "$2" ] && pass "$3 ($1)" || fail "$3 (got '$1', expected '$2')"; }

echo "GOTSCS v4 smoke tests — $(date)"

# --- File existence ---
for f in SKILL.md graph.json hats.json graph.schema.json briefing-core.md \
         briefing-appendix-topology.md briefing-appendix-contract.md \
         briefing-appendix-memory.md briefing-appendix-antipatterns.md \
         briefing-appendix-vocab.md; do
  test -f "$SKILL_DIR/$f" && pass "file exists: $f" || fail "missing: $f"
done

# --- 19 module files (one per node, per P-001) ---
MOD_COUNT=$(ls "$SKILL_DIR/modules/" | wc -l)
check "$MOD_COUNT" "19" "module file count"

# --- 5 scripts ---
for s in init-session.sh validate-graph.sh validate-context-path.sh sync-signal.sh assemble-skill.sh; do
  test -x "$SKILL_DIR/scripts/$s" && pass "script: $s" || fail "missing/non-exec script: $s"
done

# --- JSON parsing ---
python3 -c "import json; json.load(open('$SKILL_DIR/graph.json'))" 2>/dev/null && pass "graph.json parses" || fail "graph.json parse error"
python3 -c "import json; json.load(open('$SKILL_DIR/hats.json'))" 2>/dev/null && pass "hats.json parses" || fail "hats.json parse error"
python3 -c "import json; json.load(open('$SKILL_DIR/graph.schema.json'))" 2>/dev/null && pass "graph.schema.json parses" || fail "graph.schema.json parse error"

# --- Topology cardinality (HC-02) ---
NODES=$(python3 -c "import json; print(len(json.load(open('$SKILL_DIR/graph.json'))['nodes']))")
EDGES=$(python3 -c "import json; print(len(json.load(open('$SKILL_DIR/graph.json'))['edges']))")
check "$NODES" "19" "node count"
check "$EDGES" "57" "edge count"

# --- Conditional nodes (2: N-CONTEXT-ANALYZE, N-BEHAVIORAL) ---
COND=$(python3 -c "import json; g=json.load(open('$SKILL_DIR/graph.json')); print(sum(1 for n in g['nodes'] if n.get('conditional')))")
check "$COND" "2" "conditional node count"

# --- Spawn count parity (V8) ---
SPAWNS=$(python3 -c "import json; g=json.load(open('$SKILL_DIR/graph.json')); print(sum(1 for n in g['nodes'] if n['exec_type']=='spawn'))")
check "$SPAWNS" "11" "spawn node count (9 unconditional + 2 conditional)"

# --- All edges have closed-vocab edge_type (HC-03) ---
BAD_EDGE_TYPES=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
allowed = {'required','optional','gate-open','forward-conditional','back-edge','terminal'}
bad = [e['id'] for e in g['edges'] if e['edge_type'] not in allowed]
print(','.join(bad) if bad else 'NONE')
")
[ "$BAD_EDGE_TYPES" = "NONE" ] && pass "edge_type closed-vocab (HC-03)" || fail "edge_type drift: $BAD_EDGE_TYPES"

# --- 3 new v4 back-edges present ---
for E in E50 E51 E52; do
  python3 -c "import json,sys; g=json.load(open('$SKILL_DIR/graph.json')); sys.exit(0 if any(e['id']=='$E' for e in g['edges']) else 1)" \
    && pass "v4 new back-edge: $E" || fail "missing v4 back-edge: $E"
done

# --- INVENTORY count in SKILL.md HARD GATES (V19) ---
HARD_HC_COUNT=$(grep -cE '^\s*[0-9]+\.\s+\*\*HC-' "$SKILL_DIR/SKILL.md" || true)
[ "$HARD_HC_COUNT" -ge 13 ] && pass "HARD GATES contains ≥13 HC items ($HARD_HC_COUNT)" || fail "HARD GATES has $HARD_HC_COUNT HC items, expected ≥13"

# --- V9 verbatim quote in §1.5 ---
grep -q "Aggregation is the defining unlock" "$SKILL_DIR/SKILL.md" && pass "V9 quote present in SKILL.md" || fail "V9 quote missing from SKILL.md"

# --- Module frontmatter sanity (V15) ---
for f in "$SKILL_DIR/modules/"*.md; do
  COUNT=$(grep -c '^node_id:' "$f")
  [ "$COUNT" -eq 1 ] || { fail "module frontmatter: $f has $COUNT node_id lines (expected 1)"; }
done
pass "module frontmatter integrity (19 files, 1 node_id each)"

# --- exec_type closed-vocab (subset of HC-04) ---
BAD_EXEC=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
allowed = {'inline','spawn'}
bad = [n['id'] for n in g['nodes'] if n['exec_type'] not in allowed]
print(','.join(bad) if bad else 'NONE')
")
[ "$BAD_EXEC" = "NONE" ] && pass "exec_type closed-vocab" || fail "exec_type drift: $BAD_EXEC"

# --- Hat closed-vocab (HC-04) ---
BAD_HATS=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
schema = json.load(open('$SKILL_DIR/graph.schema.json'))
allowed = set(schema['properties']['nodes']['items']['properties']['hat']['enum'])
bad = [n['id'] for n in g['nodes'] if n['hat'] not in allowed]
print(','.join(bad) if bad else 'NONE')
")
[ "$BAD_HATS" = "NONE" ] && pass "hat closed-vocab (HC-04, from graph.schema.json)" || fail "hat drift: $BAD_HATS"

echo ""
if [ $FAIL -eq 0 ]; then
  echo "ALL SMOKE TESTS PASSED"
  exit 0
else
  echo "SOME SMOKE TESTS FAILED"
  exit 1
fi
