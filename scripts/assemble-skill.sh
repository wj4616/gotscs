#!/usr/bin/env bash
# Copy completed stage outputs into the final skill directory
set -euo pipefail
SESSION_DIR="${1:?usage: assemble-skill.sh <session_dir> <output_skill_dir>}"
DEST="${2:?usage: assemble-skill.sh <session_dir> <output_skill_dir>}"
mkdir -p "$DEST/modules" "$DEST/tests"

python3 - "$SESSION_DIR/stages/N-JSON.md" "$DEST/graph.json" "$DEST/hats.json" <<'PYEOF'
import sys, re
src, graph_out, hats_out = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src) as f:
    content = f.read()
blocks = re.findall(r'```json\n(.*?)```', content, re.DOTALL)
if len(blocks) >= 1:
    with open(graph_out, 'w') as f: f.write(blocks[0].strip())
    print(f"Extracted graph.json ({len(blocks[0])} chars)")
if len(blocks) >= 2:
    with open(hats_out, 'w') as f: f.write(blocks[1].strip())
    print(f"Extracted hats.json ({len(blocks[1])} chars)")
if len(blocks) < 2:
    print(f"WARNING: found only {len(blocks)} JSON block(s) (expected 2)", file=sys.stderr)
    sys.exit(1)
PYEOF

echo "Assembled skill at $DEST"
