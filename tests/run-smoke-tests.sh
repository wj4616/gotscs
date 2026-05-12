#!/usr/bin/env bash
# GOTSCS v4.3.0 — smoke tests (Phase 1 of evolution-spec)
# Purpose: structural validity check. Run after every install / change.
# Exits 0 if all checks pass; 1 otherwise.
# v4.4 deltas: caps raised to 30/15/100 standard, 36/18/120 aggressive, 40/20/150 complex;
#   added --complex flag, cap_tier.md consolidation, FUSION-11 test.
#   adds N-FUSION-ANALYZE module + edges E60-E64.

set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
pass()  { echo "PASS: $1"; }
fail()  { echo "FAIL: $1"; FAIL=1; }
check() { [ "$1" = "$2" ] && pass "$3 ($1)" || fail "$3 (got '$1', expected '$2')"; }

echo "GOTSCS v4.3 smoke tests — $(date)"

# --- File existence ---
for f in SKILL.md graph.json hats.json graph.schema.json briefing-core.md \
         briefing-appendix-topology.md briefing-appendix-contract.md \
         briefing-appendix-memory.md briefing-appendix-antipatterns.md \
         briefing-appendix-vocab.md; do
  test -f "$SKILL_DIR/$f" && pass "file exists: $f" || fail "missing: $f"
done

# --- 20 module files (one per node, per P-001; v4.3 added N-FUSION-ANALYZE) ---
MOD_COUNT=$(ls "$SKILL_DIR/modules/" | wc -l)
check "$MOD_COUNT" "20" "module file count"

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
check "$NODES" "20" "node count"
check "$EDGES" "64" "edge count"

# --- Conditional nodes (3: N-CONTEXT-ANALYZE, N-BEHAVIORAL, N-FUSION-ANALYZE) ---
COND=$(python3 -c "import json; g=json.load(open('$SKILL_DIR/graph.json')); print(sum(1 for n in g['nodes'] if n.get('conditional')))")
check "$COND" "3" "conditional node count"

# --- Spawn count parity (V8): 9 unconditional + 3 conditional = 12 ---
SPAWNS=$(python3 -c "import json; g=json.load(open('$SKILL_DIR/graph.json')); print(sum(1 for n in g['nodes'] if n['exec_type']=='spawn'))")
check "$SPAWNS" "12" "spawn node count (9 unconditional + 3 conditional)"

# --- All edges have closed-vocab edge_type (HC-03) ---
BAD_EDGE_TYPES=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
allowed = {'required','optional','gate-open','forward-conditional','back-edge','terminal'}
bad = [e['id'] for e in g['edges'] if e['edge_type'] not in allowed]
print(','.join(bad) if bad else 'NONE')
")
[ "$BAD_EDGE_TYPES" = "NONE" ] && pass "edge_type closed-vocab (HC-03)" || fail "edge_type drift: $BAD_EDGE_TYPES"

# --- 4 new v4 back-edges present (E50/E51/E52 + E59 added in v4.1.0) ---
for E in E50 E51 E52 E59; do
  python3 -c "import json,sys; g=json.load(open('$SKILL_DIR/graph.json')); sys.exit(0 if any(e['id']=='$E' for e in g['edges']) else 1)" \
    && pass "v4 new back-edge: $E" || fail "missing v4 back-edge: $E"
done

# --- topology-fix edges: E53-E56 (N-CONTEXT-ANALYZE→Wave-3+AGG), E57 (N-JSON→N-SKILL-RENDER), E58 (N-PREFLIGHT→N-CONTEXT-ANALYZE) ---
for E in E53 E54 E55 E56 E57 E58; do
  python3 -c "import json,sys; g=json.load(open('$SKILL_DIR/graph.json')); sys.exit(0 if any(e['id']=='$E' for e in g['edges']) else 1)" \
    && pass "topology-fix edge: $E" || fail "missing topology-fix edge: $E"
done

# --- v4.3 fusion edges: E60 (N-CONTEXT-ANALYZE→N-FUSION-ANALYZE), E61 (N-NORMALIZE→N-FUSION-ANALYZE),
#     E62 (N-FUSION-ANALYZE→N-AGG-DESIGN), E63 (N-FUSION-ANALYZE→N-DECOMPOSE), E64 (N-FUSION-ANALYZE→N-CONSTRAINTS) ---
for E in E60 E61 E62 E63 E64; do
  python3 -c "import json,sys; g=json.load(open('$SKILL_DIR/graph.json')); sys.exit(0 if any(e['id']=='$E' for e in g['edges']) else 1)" \
    && pass "v4.3 fusion edge: $E" || fail "missing v4.3 fusion edge: $E"
done

# --- v4.3 N-FUSION-ANALYZE node presence + module file ---
python3 -c "import json,sys; g=json.load(open('$SKILL_DIR/graph.json')); sys.exit(0 if any(n['id']=='N-FUSION-ANALYZE' for n in g['nodes']) else 1)" \
  && pass "v4.3 node N-FUSION-ANALYZE present in graph" || fail "missing v4.3 node N-FUSION-ANALYZE"
test -f "$SKILL_DIR/modules/N-FUSION-ANALYZE.md" \
  && pass "v4.3 module file: N-FUSION-ANALYZE.md" || fail "missing module file: N-FUSION-ANALYZE.md"

# --- v4.3 N-FUSION-ANALYZE is conditional + spawn + AGGREGATION + model-large ---
python3 -c "
import json, sys
g = json.load(open('$SKILL_DIR/graph.json'))
n = next((n for n in g['nodes'] if n['id']=='N-FUSION-ANALYZE'), None)
if not n: sys.exit(2)
ok = (n.get('conditional') is True
      and n.get('exec_type')=='spawn'
      and n.get('type')=='AGGREGATION'
      and n.get('hat')=='aggregator'
      and n.get('tier')=='model-large'
      and n.get('wave')==2
      and n.get('mode_gate'))
sys.exit(0 if ok else 1)
" && pass "v4.3 N-FUSION-ANALYZE shape (conditional+spawn+AGGREGATION+aggregator+model-large+wave2+mode_gate)" \
  || fail "v4.3 N-FUSION-ANALYZE shape drift"

# --- v4.3 Phase 2: N-CONSTRAINTS declares mode-dependent sections ---
grep -q "## hard_constraints" "$SKILL_DIR/modules/N-CONSTRAINTS.md" \
  && pass "v4.3 N-CONSTRAINTS declares hard_constraints section" \
  || fail "v4.3 N-CONSTRAINTS missing hard_constraints section (Phase 2)"
grep -q "## soft_constraints" "$SKILL_DIR/modules/N-CONSTRAINTS.md" \
  && pass "v4.3 N-CONSTRAINTS declares soft_constraints section" \
  || fail "v4.3 N-CONSTRAINTS missing soft_constraints section (Phase 2)"
grep -q "## fusion_constraints" "$SKILL_DIR/modules/N-CONSTRAINTS.md" \
  && pass "v4.3 N-CONSTRAINTS declares fusion_constraints section" \
  || fail "v4.3 N-CONSTRAINTS missing fusion_constraints section (Phase 2)"
# All 9 FC-01..FC-09 referenced in N-CONSTRAINTS
FC_COUNT=$(grep -cE "FC-0[1-9]" "$SKILL_DIR/modules/N-CONSTRAINTS.md")
[ "$FC_COUNT" -ge 9 ] && pass "v4.3 N-CONSTRAINTS references FC-01..FC-09 ($FC_COUNT mentions)" \
  || fail "v4.3 N-CONSTRAINTS only $FC_COUNT FC-* references (expected ≥9)"

# --- v4.3 Phase 2: N-DECOMPOSE declares 8 task categories ---
TASK_CATS=$(grep -cE "^[[:space:]]*\| \`(preserve|upgrade|replace|merge|add|remove|resequence|recontract)\`" "$SKILL_DIR/modules/N-DECOMPOSE.md" || true)
[ "$TASK_CATS" -eq 8 ] && pass "v4.3 N-DECOMPOSE declares 8 task categories (preserve/upgrade/replace/merge/add/remove/resequence/recontract)" \
  || fail "v4.3 N-DECOMPOSE has $TASK_CATS task categories (expected 8)"
grep -q "decomposition_tasks" "$SKILL_DIR/modules/N-DECOMPOSE.md" \
  && pass "v4.3 N-DECOMPOSE emits decomposition_tasks signal" \
  || fail "v4.3 N-DECOMPOSE missing decomposition_tasks (Phase 2)"

# --- v4.3 Phase 2: N-AGG-DESIGN consumes fusion_plan + emits fusion_task_trace ---
grep -q "fusion_plan" "$SKILL_DIR/modules/N-AGG-DESIGN.md" \
  && pass "v4.3 N-AGG-DESIGN reads fusion_plan input" \
  || fail "v4.3 N-AGG-DESIGN missing fusion_plan input port (Phase 2)"
grep -q "fusion_task_trace" "$SKILL_DIR/modules/N-AGG-DESIGN.md" \
  && pass "v4.3 N-AGG-DESIGN emits fusion_task_trace section" \
  || fail "v4.3 N-AGG-DESIGN missing fusion_task_trace (Phase 2)"

# --- v4.3 Phase 2: external-contract registry exists in briefing-appendix-contract ---
grep -q "EC-FC04-1" "$SKILL_DIR/briefing-appendix-contract.md" \
  && pass "v4.3 briefing-appendix-contract.md has external-contract registry (EC-FC04-1..5)" \
  || fail "v4.3 briefing-appendix-contract.md missing EC-FC04 registry"

# --- v4.3 Phase 2 (F108): all three Phase-2 modules declare evolution_mode input port ---
for MOD in N-CONSTRAINTS N-DECOMPOSE N-AGG-DESIGN; do
  # Count YAML lines with `port: evolution_mode` in the input_ports block of the module's frontmatter
  HAS_EVOLUTION=$(awk '/^---$/{f=!f; next} f && /port: evolution_mode/{print}' "$SKILL_DIR/modules/$MOD.md" | wc -l)
  [ "$HAS_EVOLUTION" -ge 1 ] \
    && pass "v4.3 $MOD declares evolution_mode input port (F108)" \
    || fail "v4.3 $MOD missing evolution_mode input port (F108 regression)"
done

# --- v4.3 Phase 2 (F101): N-FUSION-ANALYZE listed in input_dependencies of three Phase-2 consumers ---
for CONSUMER in N-DECOMPOSE N-CONSTRAINTS N-AGG-DESIGN; do
  python3 -c "
import json, sys
g = json.load(open('$SKILL_DIR/graph.json'))
n = next((n for n in g['nodes'] if n['id']=='$CONSUMER'), None)
if not n: sys.exit(2)
sys.exit(0 if 'N-FUSION-ANALYZE' in n.get('input_dependencies', []) else 1)
" && pass "v4.3 $CONSUMER lists N-FUSION-ANALYZE in input_dependencies (F101)" \
  || fail "v4.3 $CONSUMER missing N-FUSION-ANALYZE in input_dependencies (F101)"
done

# --- v4.3 Phase 3 FUSION-* structural smoke tests (per spec §6.2 — contract assertions, not behavioral) ---

# FUSION-01/02/03: precedence stack P1 brief > P2 spec > P3 original > P4 default declared in N-FUSION-ANALYZE
grep -qE "P1.*brief.*P2.*spec.*P3.*original.*P4" "$SKILL_DIR/modules/N-FUSION-ANALYZE.md" \
  && pass "FUSION-01/02/03 precedence stack contract declared (P1>P2>P3>P4)" \
  || fail "FUSION-01/02/03 precedence stack contract missing in N-FUSION-ANALYZE"

# FUSION-04: FUSION.md emission contract present in N-EMIT
grep -q "FUSION\.md" "$SKILL_DIR/modules/N-EMIT.md" \
  && pass "FUSION-04 FUSION.md emission contract declared in N-EMIT" \
  || fail "FUSION-04 missing FUSION.md emission contract in N-EMIT"

# FUSION-04 honors --no-fusion-doc suppression
grep -q "NO_FUSION_DOC=true" "$SKILL_DIR/modules/N-EMIT.md" \
  && pass "FUSION-04 N-EMIT honors --no-fusion-doc suppression flag" \
  || fail "FUSION-04 N-EMIT does not honor --no-fusion-doc"

# FUSION-05: redesign_candidates contract in N-CONTEXT-ANALYZE
grep -q "redesign_candidates" "$SKILL_DIR/modules/N-CONTEXT-ANALYZE.md" \
  && pass "FUSION-05 redesign_candidates contract in N-CONTEXT-ANALYZE" \
  || fail "FUSION-05 missing redesign_candidates in N-CONTEXT-ANALYZE"

# FUSION-06: preservation_map contract present in N-FUSION-ANALYZE step 7
grep -q "preservation_map" "$SKILL_DIR/modules/N-FUSION-ANALYZE.md" \
  && pass "FUSION-06 preservation_map declared in N-FUSION-ANALYZE" \
  || fail "FUSION-06 missing preservation_map in N-FUSION-ANALYZE"

# FUSION-07: divergence_map with rationale in N-FUSION-ANALYZE
grep -qE "divergence_map.*rationale|divergence_rationale" "$SKILL_DIR/modules/N-FUSION-ANALYZE.md" \
  && pass "FUSION-07 divergence_map carries rationale field" \
  || fail "FUSION-07 missing divergence_map rationale field"

# FUSION-08: risk_assessment / regression_risk fields in divergence_map
grep -q "regression_risk" "$SKILL_DIR/modules/N-FUSION-ANALYZE.md" \
  && pass "FUSION-08 regression_risk field in divergence_map" \
  || fail "FUSION-08 missing regression_risk field"

# FUSION-09: produced-skills HC-02 caps in normal mode (≤100 edges) declared in graph.json metadata
PRODUCED_NORMAL_CAP=$(python3 -c "import json; m=json.load(open('$SKILL_DIR/graph.json'))['metadata']; print(m.get('produced_skill_edge_cap_normal', 'MISSING'))")
[ "$PRODUCED_NORMAL_CAP" = "100" ] \
  && pass "FUSION-09 produced_skill_edge_cap_normal=100 (per spec)" \
  || fail "FUSION-09 produced_skill_edge_cap_normal=$PRODUCED_NORMAL_CAP (expected 100)"

# FUSION-10: produced-skills HC-02 caps in aggressive mode (≤120 edges) declared in graph.json metadata
PRODUCED_AGG_CAP=$(python3 -c "import json; m=json.load(open('$SKILL_DIR/graph.json'))['metadata']; print(m.get('produced_skill_edge_cap_aggressive', 'MISSING'))")
[ "$PRODUCED_AGG_CAP" = "120" ] \
  && pass "FUSION-10 produced_skill_edge_cap_aggressive=120 (per spec)" \
  || fail "FUSION-10 produced_skill_edge_cap_aggressive=$PRODUCED_AGG_CAP (expected 120)"

# FUSION-11: produced-skills HC-02 caps in complex mode (≤150 edges) declared in graph.json metadata
PRODUCED_COMPLEX_CAP=$(python3 -c "import json; m=json.load(open('$SKILL_DIR/graph.json'))['metadata']; print(m.get('produced_skill_edge_cap_complex', 'MISSING'))")
[ "$PRODUCED_COMPLEX_CAP" = "150" ] \
  && pass "FUSION-11 produced_skill_edge_cap_complex=150 (per spec)" \
  || fail "FUSION-11 produced_skill_edge_cap_complex=$PRODUCED_COMPLEX_CAP (expected 150)"

# FUSION-11: FC-07 functional contract check in N-VERIFY V26(c)
grep -qE "V26.*c.*FC-07|V26\(c\).*FC-07|FC-07.*output_ports" "$SKILL_DIR/modules/N-VERIFY.md" \
  && pass "FUSION-11 V26(c) FC-07 functional-contract check declared in N-VERIFY" \
  || fail "FUSION-11 V26(c) FC-07 check missing from N-VERIFY"

# FUSION-12: FC-08 regression-test coverage check in N-VERIFY V26(e)
grep -qE "V26.*e.*FC-08|V26\(e\).*FC-08|FC-08.*regression" "$SKILL_DIR/modules/N-VERIFY.md" \
  && pass "FUSION-12 V26(e) FC-08 regression-coverage check declared in N-VERIFY" \
  || fail "FUSION-12 V26(e) FC-08 check missing from N-VERIFY"

# Phase 3 (additional): REGRESSION.md emission contract in N-EMIT
grep -q "REGRESSION\.md" "$SKILL_DIR/modules/N-EMIT.md" \
  && pass "v4.3 Phase 3 REGRESSION.md emission contract declared in N-EMIT" \
  || fail "v4.3 Phase 3 REGRESSION.md emission contract missing"

# Phase 3 (additional): N-VERIFY V26 fusion-contract residual check declared
grep -q "V26.*fusion-contract" "$SKILL_DIR/modules/N-VERIFY.md" \
  && pass "v4.3 Phase 3 V26 fusion-contract residual check declared in N-VERIFY" \
  || fail "v4.3 Phase 3 V26 missing from N-VERIFY"

# Phase 3 (additional): RATIONALE.md evolve extension references fusion redesign justifications
grep -qE "Fusion Redesign Justifications|evolve mode.*RATIONALE|fusion.*divergence_map" "$SKILL_DIR/modules/N-EMIT.md" \
  && pass "v4.3 Phase 3 RATIONALE.md evolve extension declared in N-EMIT" \
  || fail "v4.3 Phase 3 RATIONALE.md evolve extension missing"

# Phase 3 (additional): N-SKILL-RENDER §0 GENESIS block for evolve mode
grep -q "GENESIS" "$SKILL_DIR/modules/N-SKILL-RENDER.md" \
  && pass "v4.3 Phase 3 §0 GENESIS block declared in N-SKILL-RENDER" \
  || fail "v4.3 Phase 3 §0 GENESIS block missing from N-SKILL-RENDER"

# Phase 3 (I020): all 6 V26 sub-check labels (a)-(f) present in N-VERIFY
V26_SUBCHECKS=$(grep -cE "\*\*\(a\) FUSION\.md|\*\*\(b\) REGRESSION\.md|\*\*\(c\) FC-07|\*\*\(d\) FC-03|\*\*\(e\) FC-08|\*\*\(f\) FC-09" "$SKILL_DIR/modules/N-VERIFY.md" || true)
[ "$V26_SUBCHECKS" -eq 6 ] && pass "v4.3 Phase 3 V26 has all 6 sub-checks (a/b/c/d/e/f) declared in N-VERIFY" \
  || fail "v4.3 Phase 3 V26 sub-checks: found $V26_SUBCHECKS (expected 6)"

# Phase 3 (I020): V26(d) canonical location locked to fusion_task_trace per F204 fix
grep -qE "canonical .## fusion_task_trace|canonical location is fusion_task_trace" "$SKILL_DIR/modules/N-VERIFY.md" \
  && pass "v4.3 Phase 3 V26(d) reads canonical fusion_task_trace location (F204 lock)" \
  || fail "v4.3 Phase 3 V26(d) does not reference fusion_task_trace as canonical FC-03 source"

# Phase 3 (I020): N-AGG-DESIGN risk_acknowledgment is in fusion_task_trace per F204 fix
grep -qE "risk_acknowledgment.*column|risk_acknowledgment.*fusion_task_trace|canonical FC-03" "$SKILL_DIR/modules/N-AGG-DESIGN.md" \
  && pass "v4.3 Phase 3 N-AGG-DESIGN places risk_acknowledgment in fusion_task_trace canonical column (F204 lock)" \
  || fail "v4.3 Phase 3 N-AGG-DESIGN risk_acknowledgment location not specified canonically"

# Phase 3 (F206 lock): GENESIS heading in N-SKILL-RENDER does not use §0 prefix in rendered output
grep -qE "Heading style.*## GENESIS|matches sibling.*HARD GATES|## GENESIS$" "$SKILL_DIR/modules/N-SKILL-RENDER.md" \
  && pass "v4.3 Phase 3 GENESIS heading uses bare ## (no §0 prefix; F206 lock)" \
  || fail "v4.3 Phase 3 GENESIS heading style guidance missing"

# --- v4.3 Phase 4 (briefing-core schema extension) ---
grep -q "§EVOLVE" "$SKILL_DIR/briefing-core.md" \
  && pass "v4.3 Phase 4 briefing-core.md has §EVOLVE schema extension" \
  || fail "v4.3 Phase 4 briefing-core.md missing §EVOLVE section"
# All 6 EVOLVE sub-sections present
EVOLVE_SUBSECTIONS=$(grep -cE "^### EVOLVE-[1-6]" "$SKILL_DIR/briefing-core.md" || true)
[ "$EVOLVE_SUBSECTIONS" -eq 6 ] \
  && pass "v4.3 Phase 4 briefing-core.md has all 6 EVOLVE sub-sections" \
  || fail "v4.3 Phase 4 briefing-core.md has $EVOLVE_SUBSECTIONS EVOLVE sub-sections (expected 6)"

# F304 lock: EVOLVE-4 must enumerate FC-01 through FC-09 (the catalogue is the substantive content)
EVOLVE4_FC_COUNT=$(awk '/^### EVOLVE-4/,/^### EVOLVE-5/' "$SKILL_DIR/briefing-core.md" | grep -cE "FC-0[1-9]" || true)
[ "$EVOLVE4_FC_COUNT" -ge 9 ] \
  && pass "v4.3 Phase 4 EVOLVE-4 enumerates FC-01..FC-09 ($EVOLVE4_FC_COUNT mentions, F304 lock)" \
  || fail "v4.3 Phase 4 EVOLVE-4 only $EVOLVE4_FC_COUNT FC-* mentions (expected ≥9)"

# --- v4.3 Phase 4 (HC-27 release rollback trigger) ---
grep -q "HC-27" "$SKILL_DIR/SKILL.md" \
  && pass "v4.3 Phase 4 HC-27 V4.3-ROLLBACK-TRIGGER declared in SKILL.md HARD GATES" \
  || fail "v4.3 Phase 4 HC-27 missing from SKILL.md"
# graph.json metadata carries the rollback trigger machine-readable
ROLLBACK_WINDOW=$(python3 -c "import json; m=json.load(open('$SKILL_DIR/graph.json'))['metadata']; print(m.get('v4_3_release_rollback_window_hours', 'MISSING'))")
[ "$ROLLBACK_WINDOW" = "48" ] \
  && pass "v4.3 Phase 4 graph.json metadata.v4_3_release_rollback_window_hours=48" \
  || fail "v4.3 Phase 4 rollback window metadata=$ROLLBACK_WINDOW (expected 48)"

# --- v4.3 Phase 4 (behavioral fusion scaffold) ---
test -d "$SKILL_DIR/tests/behavioral-fusion" \
  && pass "v4.3 Phase 4 tests/behavioral-fusion/ scaffold directory exists" \
  || fail "v4.3 Phase 4 tests/behavioral-fusion/ missing"
test -f "$SKILL_DIR/tests/behavioral-fusion/README.md" \
  && pass "v4.3 Phase 4 behavioral-fusion README documents scaffold status" \
  || fail "v4.3 Phase 4 behavioral-fusion README missing"
test -x "$SKILL_DIR/tests/behavioral-fusion/run-fusion-acceptance.sh" \
  && pass "v4.3 Phase 4 run-fusion-acceptance.sh scaffold executable" \
  || fail "v4.3 Phase 4 run-fusion-acceptance.sh missing or non-executable"
# F306 lock: scaffold MUST exit 78 (EX_CONFIG) until end-to-end harness is wired.
# Capture exit without tripping `set -e`: invoke in a subshell with `|| true` so the bare exit reaches $?.
SCAFFOLD_EXIT=0
bash "$SKILL_DIR/tests/behavioral-fusion/run-fusion-acceptance.sh" >/dev/null 2>&1 || SCAFFOLD_EXIT=$?
[ "$SCAFFOLD_EXIT" -eq 78 ] \
  && pass "v4.3 Phase 4 run-fusion-acceptance.sh exits 78 (EX_CONFIG; scaffold-not-wired signal; F306 lock)" \
  || fail "v4.3 Phase 4 run-fusion-acceptance.sh exited $SCAFFOLD_EXIT (expected 78)"
# At least one example fixture (F04 minimum)
test -f "$SKILL_DIR/tests/behavioral-fusion/fixtures/F04-fusion-md-emitted/expected.yaml" \
  && pass "v4.3 Phase 4 example fixture F04 expected.yaml present" \
  || fail "v4.3 Phase 4 example fixture F04 missing"

# I030 lock: release-checklist.md exists with HC-26 + HC-27 procedure
test -f "$SKILL_DIR/tests/release-checklist.md" \
  && pass "v4.3 Phase 4 tests/release-checklist.md present (I030 operator runbook)" \
  || fail "v4.3 Phase 4 tests/release-checklist.md missing"
grep -qE "HC-26.*5-brief|5-brief.*battery" "$SKILL_DIR/tests/release-checklist.md" 2>/dev/null \
  && grep -qE "HC-27.*48-hour|48-hour.*window" "$SKILL_DIR/tests/release-checklist.md" 2>/dev/null \
  && pass "v4.3 Phase 4 release-checklist documents both HC-26 5-brief and HC-27 48-hour procedures (I030)" \
  || fail "v4.3 Phase 4 release-checklist missing HC-26 / HC-27 procedure documentation"

# --- §2 edge breakdown parity (SKILL.md §2 vs graph.json actuals) ---
EDGE_BREAKDOWN_CHECK=$(python3 -c "
import json, re
g = json.load(open('$SKILL_DIR/graph.json'))
counts = {}
for e in g['edges']:
    t = e['edge_type']
    counts[t] = counts.get(t, 0) + 1
with open('$SKILL_DIR/SKILL.md') as f:
    text = f.read()
m = re.search(r'Edge type breakdown: (.+?)\.', text)
if not m:
    print('MISSING-BREAKDOWN-LINE')
else:
    claimed = {}
    for part in m.group(1).split(','):
        k, v = part.strip().split('=')
        claimed[k.strip()] = int(v.strip())
    mismatches = [f'{k}: claimed={expected}, actual={counts.get(k,0)}' for k, expected in claimed.items() if counts.get(k,0) != expected]
    mismatches += [f'{k}: in graph.json but not in §2' for k in counts if k not in claimed]
    print(','.join(mismatches) if mismatches else 'MATCH')
" 2>/dev/null || echo "CHECK-ERROR")
[ "$EDGE_BREAKDOWN_CHECK" = "MATCH" ] && pass "§2 edge breakdown matches graph.json" || fail "§2 edge breakdown drift: $EDGE_BREAKDOWN_CHECK"

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
pass "module frontmatter integrity (20 files, 1 node_id each)"

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

# --- v4.3 evolve-mode invariants (M2 audit fix — kill mutations 22-25) ---

# M22 kill: N-FUSION-ANALYZE must raise fusion_overflow_flag
FOF=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
for n in g['nodes']:
    if n['id'] == 'N-FUSION-ANALYZE':
        print('YES' if 'fusion_overflow_flag' in n.get('raises_signals', []) else 'NO')
        break
")
[ "$FOF" = "YES" ] && pass "N-FUSION-ANALYZE raises fusion_overflow_flag (v4.3)" || fail "N-FUSION-ANALYZE missing fusion_overflow_flag in raises_signals"

# M23 kill: V26 sub-check arity matches module spec (a/b/c/d/e/f = 6 sub-checks)
V26_ARITY=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
md = g.get('metadata', {})
# If metadata claims a v26_subcheck_count, it must be 6 (a/b/c/d/e/f)
declared = md.get('v26_subcheck_count')
print('OK' if declared is None or declared == 6 else f'DRIFT:{declared}')
")
[ "$V26_ARITY" = "OK" ] && pass "V26 sub-check arity 6 (a/b/c/d/e/f) — or undeclared" || fail "V26 sub-check arity drift: $V26_ARITY"

# M24 kill: N-FUSION-ANALYZE is AGGREGATION type → must declare aggregation_policy
FUSION_AGG=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
for n in g['nodes']:
    if n['id'] == 'N-FUSION-ANALYZE':
        if n.get('type') == 'AGGREGATION':
            print('OK' if 'aggregation_policy' in n else 'MISSING')
        else:
            print('NA')
        break
")
[ "$FUSION_AGG" = "OK" ] || [ "$FUSION_AGG" = "NA" ] && pass "N-FUSION-ANALYZE aggregation_policy declared (HC-04 AGGREGATION discipline)" || fail "N-FUSION-ANALYZE is AGGREGATION but missing aggregation_policy"

# M25 kill: hc23_parallel_dispatch_waves entries must each have ≥2 nodes with parallel_dispatch_required
HC23_OK=$(python3 -c "
import json
g = json.load(open('$SKILL_DIR/graph.json'))
md = g.get('metadata', {})
hc23_waves = md.get('hc23_parallel_dispatch_waves', [])
result = 'OK'
for w in hc23_waves:
    nodes_in_wave = [n for n in g['nodes'] if n.get('wave') == w]
    parallel_count = sum(1 for n in nodes_in_wave if n.get('parallel_dispatch_required'))
    # If parallel_dispatch_required isn't used as a node-level flag, count multi-node waves instead
    if parallel_count == 0:
        spawn_count = sum(1 for n in nodes_in_wave if n.get('exec_type') == 'spawn')
        if spawn_count < 2:
            result = f'WAVE_{w}_BROKEN(spawns={spawn_count})'
            break
    elif parallel_count < 2:
        result = f'WAVE_{w}_BROKEN(parallel={parallel_count})'
        break
print(result)
")
[ "$HC23_OK" = "OK" ] && pass "hc23_parallel_dispatch_waves consistency (each wave has ≥2 parallel-eligible nodes)" || fail "HC-23 dispatch-waves array inconsistent: $HC23_OK"

echo ""
if [ $FAIL -eq 0 ]; then
  echo "ALL SMOKE TESTS PASSED"
  exit 0
else
  echo "SOME SMOKE TESTS FAILED"
  exit 1
fi
