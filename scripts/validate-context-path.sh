#!/usr/bin/env bash
# HC-25 suspicious-target validation for --context, --context-spec, and GOTSCS_OUTPUT_BASE.
# Usage: validate-context-path.sh <kind> <path>
#   kind in {context, context-spec, output-base}
# Exits 0 if path is safe; exits 1 with diagnostic if forbidden.
set -euo pipefail
KIND="${1:?kind required: context | context-spec | output-base}"
RAW="${2:?path required}"

# Resolve to absolute, canonical path
RESOLVED="$(realpath -m "$RAW" 2>/dev/null || echo "$RAW")"

# Forbidden roots
FORBIDDEN=("/" "/etc" "/usr" "/var" "/tmp")
HOME_LITERAL="$HOME"

for f in "${FORBIDDEN[@]}"; do
  if [[ "$RESOLVED" == "$f" ]]; then
    echo "halt-suspicious-target: $KIND='$RAW' resolves to forbidden root '$RESOLVED'" >&2
    exit 1
  fi
done

# $HOME (without subdir) is forbidden
if [[ "$RESOLVED" == "$HOME_LITERAL" ]]; then
  echo "halt-suspicious-target: $KIND='$RAW' resolves to \$HOME without a subdirectory" >&2
  exit 1
fi

case "$KIND" in
  context)
    # Must be a directory containing at least one recognizable skill file.
    # graph.json is GOTSCS-specific and NOT required for non-GOTSCS skills (v4 fix).
    if [[ ! -d "$RESOLVED" ]]; then
      echo "halt-context-missing-required-files: $RESOLVED is not a directory" >&2
      exit 1
    fi
    if [[ ! -f "$RESOLVED/SKILL.md" && ! -f "$RESOLVED/README.md" && ! -f "$RESOLVED/graph.json" ]]; then
      echo "halt-context-missing-required-files: $RESOLVED contains no recognizable skill file (SKILL.md, README.md, graph.json)" >&2
      exit 1
    fi
    ;;
  context-spec)
    if [[ ! -f "$RESOLVED" ]]; then
      echo "halt-spec-frontmatter-invalid: $RESOLVED is not a file" >&2
      exit 1
    fi
    # Probe frontmatter for node_count, wave_count, topology
    python3 - "$RESOLVED" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f:
    content = f.read()
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if not m:
    print(f"halt-spec-frontmatter-invalid: no YAML frontmatter in {path}", file=sys.stderr)
    sys.exit(1)
fm = m.group(1)
for required in ('node_count', 'wave_count', 'topology'):
    if required not in fm:
        print(f"halt-spec-frontmatter-invalid: '{required}' missing from frontmatter of {path}", file=sys.stderr)
        sys.exit(1)
print(f"context-spec frontmatter valid: {path}")
PYEOF
    ;;
  output-base)
    # Already passed forbidden-root check above
    echo "output-base validated: $RESOLVED"
    ;;
  *)
    echo "halt-suspicious-target: unknown kind '$KIND'" >&2
    exit 1
    ;;
esac

echo "PASS: $KIND='$RAW' -> '$RESOLVED'"
