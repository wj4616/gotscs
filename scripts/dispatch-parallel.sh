#!/usr/bin/env bash
# dispatch-parallel.sh — HC-23 parallel-dispatch documentation helper (G-01)
#
# GOTSCS skills are Claude-Code-class: "dispatch" means issuing multiple Agent
# tool calls in a single LLM response. This script cannot enforce that at runtime
# (the LLM orchestrator controls response boundaries), but it:
#   1. Documents which waves require single-response parallel dispatch (HC-23).
#   2. Appends a dispatch_log entry to SIGNAL_STATE.json for V20 verification.
#
# Usage:
#   dispatch-parallel.sh <session_dir> <wave> <spawn_id1> [<spawn_id2> ...]
#
# Example (call once after issuing all Wave-3 Agent calls in one response):
#   dispatch-parallel.sh "$SESSION_DIR" 3 N-TOPOLOGY N-DECOMPOSE N-CONSTRAINTS

set -euo pipefail

SESSION_DIR="${1:?Usage: dispatch-parallel.sh <session_dir> <wave> <spawn_id...>}"
WAVE="${2:?wave number required}"
shift 2
SPAWN_IDS=("$@")

SIGNAL_FILE="$SESSION_DIR/SIGNAL_STATE.json"
if [[ ! -f "$SIGNAL_FILE" ]]; then
  echo "dispatch-parallel.sh: SIGNAL_STATE.json not found at $SIGNAL_FILE" >&2
  exit 1
fi

RESPONSE_ID="wave${WAVE}-dispatch"

python3 - "$SIGNAL_FILE" "$WAVE" "$RESPONSE_ID" "${SPAWN_IDS[@]}" << 'PYEOF'
import json, sys

signal_file = sys.argv[1]
wave = int(sys.argv[2])
response_id = sys.argv[3]
spawn_ids = sys.argv[4:]

ss = json.load(open(signal_file))
if "dispatch_log" not in ss:
    ss["dispatch_log"] = []

entry = {"wave": wave, "response_id": response_id, "spawn_ids": list(spawn_ids)}
ss["dispatch_log"].append(entry)

with open(signal_file, "w") as f:
    json.dump(ss, f, indent=2)

print(f"dispatch-parallel: logged wave={wave} response_id={response_id} spawn_ids={spawn_ids}")
PYEOF
