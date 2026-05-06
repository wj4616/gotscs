#!/usr/bin/env bash
# sync-signal.sh — centralized SIGNAL_STATE.json updater (P-005)
#
# Usage:
#   sync-signal.sh <session_dir> <key>=<value> [<key>=<value> ...]
#
# Each <key>=<value> updates one field in <session_dir>/SIGNAL_STATE.json atomically.
# Values are interpreted as JSON: bare `true`/`false`/`null`/numbers stay typed; everything
# else becomes a string. Use `key=present` for the "stage signal emitted" convention.
#
# Examples:
#   sync-signal.sh "$SESSION_DIR" preflight_status=pass input_class=ec-brief
#   sync-signal.sh "$SESSION_DIR" gate_pass=true retry_count_design=1
#   sync-signal.sh "$SESSION_DIR" graph_spec=present
#
# Used by: orchestrator SKILL.md (every Wave barrier) — replaces ad-hoc inline jq blocks.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: sync-signal.sh <session_dir> <key>=<value> [<key>=<value> ...]" >&2
  exit 2
fi

SESSION_DIR="$1"; shift
SS_FILE="$SESSION_DIR/SIGNAL_STATE.json"

if [[ ! -f "$SS_FILE" ]]; then
  echo "sync-signal.sh: SIGNAL_STATE.json not found at $SS_FILE" >&2
  exit 1
fi

# Build a single jq filter applying every key=value as a separate '|' stage.
# Preserves atomicity: one mktemp, one mv.
_FILTER='.'
_ARGS=()
for kv in "$@"; do
  if [[ "$kv" != *=* ]]; then
    echo "sync-signal.sh: bad pair '$kv' (must be key=value)" >&2
    exit 2
  fi
  k="${kv%%=*}"
  v="${kv#*=}"
  # Auto-type: true/false/null/integer stay as JSON literals; everything else is a string.
  if [[ "$v" == "true" || "$v" == "false" || "$v" == "null" || "$v" =~ ^-?[0-9]+$ ]]; then
    _FILTER="$_FILTER | .$k = $v"
  else
    # Use --arg with a generated arg name so nested jq escaping is handled correctly.
    arg_name="v_${#_ARGS[@]}"
    _ARGS+=(--arg "$arg_name" "$v")
    _FILTER="$_FILTER | .$k = \$$arg_name"
  fi
done

_TMP=$(mktemp)
jq "${_ARGS[@]}" "$_FILTER" "$SS_FILE" > "$_TMP" && mv "$_TMP" "$SS_FILE"
