#!/usr/bin/env bash
# Initialize a GOTSCS session directory and SIGNAL_STATE file (schema 2.3)
# Schema 2.3 adds (v4.3 fusion pipeline): evolution_mode, contexts_provided_count, waiver_justification,
#   context_advisory, redesign_candidates, fusion_plan, fusion_decisions, fusion_overflow_flag.
# Schema 2.2 adds: review_gate_audit array and degradation_notices array (v4 graceful-degradation).
# Schema 2.1 added: skill_render_result (P-002), behavioral_result/behavioral_pass (P-006).
# Also creates stages/modules/ subdirectory for per-file module emission (P-001).
# GAP-001 fix (v4): upgraded 2.1 → 2.2; added review_gate_audit + degradation_notices.
# v4.3 extension: 2.2 → 2.3; added 8 fusion-pipeline fields. Backward-compat: v4.2 sessions reading 2.2
#   files continue to work; the SKILL.md GAP-001 guard accepts both 2.2 and 2.3.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BASE="${GOTSCS_OUTPUT_BASE:-$HOME/docs/gotscs-output}"
SKILL_NAME_SLUG="${1:-unnamed}"
MODE_ARG="${2:-}"  # optional: skill | spec | both | (empty for null)
# Validate MODE_ARG if provided
case "$MODE_ARG" in
  ""|skill|spec|both) ;;
  *) echo "init-session.sh: invalid mode '$MODE_ARG'; expected one of: skill | spec | both | (empty)" >&2; exit 2 ;;
esac
SESSION_ID="${SKILL_NAME_SLUG}-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="$OUTPUT_BASE/$SESSION_ID"
mkdir -p "$SESSION_DIR/stages/modules"
# C5 fix: mode substitution — write the supplied MODE_ARG (or null) directly into SIGNAL_STATE.
# C4 fix: dispatch_log is part of schema 2.3; init it here so dispatch-parallel.sh + GAP-001 guard see it.
if [[ -n "$MODE_ARG" ]]; then
  MODE_LITERAL="\"$MODE_ARG\""
else
  MODE_LITERAL="null"
fi
cat > "$SESSION_DIR/SIGNAL_STATE.json" <<EOF
{
  "schema_version": "2.3",
  "mode": $MODE_LITERAL,
  "preflight_status": null,
  "input_class": null,
  "evolution_mode": null,
  "contexts_provided_count": null,
  "waiver_justification": null,
  "complex_mode": null,
  "normalize_digest": null,
  "topology_digest": null,
  "decompose_digest": null,
  "constraints_digest": null,
  "context_inventory": null,
  "validation_mode": false,
  "conflict_signals": [],
  "context_advisory": null,
  "redesign_candidates": null,
  "fusion_plan": null,
  "fusion_decisions": null,
  "fusion_overflow_flag": null,
  "design_blueprint": null,
  "gate_pass": null,
  "gate_diagnostic": null,
  "registry_result": null,
  "edges_result": null,
  "waves_result": null,
  "graph_spec": null,
  "spec_path": null,
  "spec_complete": null,
  "modules_result": null,
  "json_result": null,
  "skill_render_result": null,
  "verify_pass": null,
  "verify_result": null,
  "emit_complete": null,
  "behavioral_result": null,
  "behavioral_pass": null,
  "review_gate_audit": [],
  "degradation_notices": [],
  "retry_count_design": 0,
  "retry_count_artifact": 0,
  "repair_targets": [],
  "dispatch_log": [],
  "post_emit_audit_status": null
}
EOF
echo "$SESSION_DIR"
