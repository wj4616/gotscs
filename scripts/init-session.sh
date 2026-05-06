#!/usr/bin/env bash
# Initialize a GOTSCS session directory and SIGNAL_STATE file (schema 2.2)
# Schema 2.2 adds: review_gate_audit array and degradation_notices array (v4 graceful-degradation).
# Schema 2.1 added: skill_render_result (P-002), behavioral_result/behavioral_pass (P-006).
# Also creates stages/modules/ subdirectory for per-file module emission (P-001).
# GAP-001 fix: upgraded from schema 2.1 → 2.2; added review_gate_audit + degradation_notices.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_BASE="${GOTSCS_OUTPUT_BASE:-$HOME/docs/gotscs-output}"
SKILL_NAME_SLUG="${1:-unnamed}"
SESSION_ID="${SKILL_NAME_SLUG}-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="$OUTPUT_BASE/$SESSION_ID"
mkdir -p "$SESSION_DIR/stages/modules"
cat > "$SESSION_DIR/SIGNAL_STATE.json" <<'EOF'
{
  "schema_version": "2.2",
  "mode": null,
  "preflight_status": null,
  "input_class": null,
  "normalize_digest": null,
  "topology_digest": null,
  "decompose_digest": null,
  "constraints_digest": null,
  "context_inventory": null,
  "validation_mode": false,
  "conflict_signals": [],
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
  "repair_targets": []
}
EOF
echo "$SESSION_DIR"
