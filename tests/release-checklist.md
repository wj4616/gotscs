# GOTSCS v4.3.0 — Release Checklist

Operator runbook for HC-26 (RELEASE-SAFETY-GATE) + HC-27 (V4.3-ROLLBACK-TRIGGER) per spec §8 Phase 4 step 6.

This is the human-driven procedure. The structural smoke + regression suites (`tests/run-smoke-tests.sh`, `tests/run-regression-suite.sh`) are already green and verify contract-level correctness — but they cannot verify that GOTSCS's *output* on real briefs is correct. That's what HC-26 covers.

---

## Pre-release: HC-26 RELEASE-SAFETY-GATE (5-brief battery + backup)

Run BEFORE replacing v4.2.x on disk.

### Step 1 — Backup the current installed version

```bash
cp -r ~/.claude/skills/gotscs ~/.claude/skills/gotscs.v4-2-x.bak.$(date +%Y%m%d-%H%M%S)
```

Confirm the backup directory exists. If your current version is already v4.3.0 (this skill), back up that instead — HC-26 backs up *whatever is currently installed*, not specifically v4.2.

### Step 2 — Run the 5-brief regression battery

Five end-to-end GOTSCS invocations, one per input class. Each is a full pipeline run (Wave 1 → Wave 10), typically 5-15 minutes wall-clock per brief. Budget 30-90 minutes total.

For each brief:
- Confirm pipeline reaches `emit_complete=true` (no halt)
- `cd <produced_skill> && bash tests/run-smoke-tests.sh` → all PASS
- For overlay-mode runs (#2, #3, #4): the produced skill should be byte-equivalent (or at least behaviorally equivalent) to a v4.2.0 reference run on the same input

| # | Brief style | Flags | Tests path coverage |
|---|---|---|---|
| 1 | minimal one-sentence brief, no context | `/gotscs "<brief>" --skill` | ec-brief / greenfield path |
| 2 | minimal brief + `--context <existing-skill>` | `/gotscs "<brief>" --skill --context <path>` | ec-skill / overlay path |
| 3 | minimal brief + `--context-spec <spec.md>` | `/gotscs "<brief>" --skill --context-spec <path>` | ec-spec / overlay path |
| 4 | brief + both contexts + `--strict` | `/gotscs "<brief>" --skill --context <path> --context-spec <path> --strict` | ec-both overlay (v4.2 parity check — the most important regression check) |
| 5 | brief + both contexts + `--evolve` | `/gotscs "<brief>" --skill --context <path> --context-spec <path> --evolve` | ec-both evolve (v4.3 new fusion path) |

**Brief #5 additional checks** (evolve-mode-specific):
- `<produced_skill>/FUSION.md` exists and contains the 10 required `## ` sections
- `<produced_skill>/REGRESSION.md` exists
- `<produced_skill>/RATIONALE.md` includes a `## Fusion Redesign Justifications` section
- `<produced_skill>/SKILL.md` has a `## GENESIS` block in §0
- N-VERIFY V26 sub-checks (a/b/c/d/f) all PASSED in `<produced_skill>` stage outputs

### Step 3 — Replace on disk

Only after all 5 briefs pass:

```bash
# Move the current install aside
mv ~/.claude/skills/gotscs ~/.claude/skills/gotscs.v4-2-x.replaced.$(date +%Y%m%d-%H%M%S)
# Install v4.3.0 (assuming the new version lives somewhere staged)
cp -r <staged-v4.3-dir> ~/.claude/skills/gotscs
# Sanity check
cd ~/.claude/skills/gotscs && bash tests/run-smoke-tests.sh && bash tests/run-regression-suite.sh
```

Both should report ALL PASSED (90+ smoke / 21+ mutations / 100% kill rate).

---

## Post-release: HC-27 V4.3-ROLLBACK-TRIGGER (48-hour window)

The 48-hour clock starts when v4.3.0 replaces v4.2.x on disk.

### What to monitor

For 48 hours after replacement, watch for ANY:
- Overlay-mode skill production failure (`/gotscs "<brief>"` with single context OR `--strict` halts unexpectedly, or produces malformed output)
- v4.3-only smoke test regression (this is the structural floor; any failure means the replacement was incomplete)
- User-reported skill-output drift compared to v4.2 baseline

### If ≥1 failure within 48 hours: rollback

Execute briefing-core.md §EVOLVE-6 procedure verbatim:

```bash
# Step 1 — Identify the affected v4.2.x backup
ls -1d ~/.claude/skills/gotscs.v4-2-x.replaced.* | tail -1
# (note the path; this is your rollback source)

# Step 2 — Restore
mv ~/.claude/skills/gotscs ~/.claude/skills/gotscs.v4-3-rollback.$(date +%Y%m%d-%H%M%S)
mv <v4-2-x-backup-path> ~/.claude/skills/gotscs

# Step 3 — Verify
cd ~/.claude/skills/gotscs && bash tests/run-smoke-tests.sh
# Expected: 41 tests / v4.2 counts (19/59 nodes/edges, 2 conditional, 11 spawn). NOT the v4.3 90+ count.
bash tests/run-regression-suite.sh
# Expected: 14/14 mutations killed (NOT 21).

# Step 4 — Freeze v4.3 branch
# Document the failure that triggered rollback. Do NOT re-attempt v4.3 replacement until root-caused.
```

### Re-engagement after root-cause fix

After fixing the root cause:
1. Re-run the FULL 5-brief HC-26 battery (don't skip — root-cause fixes can introduce new regressions)
2. Update SHA-256 baseline for the NEW v4.3.0 release: `find ~/.claude/skills/gotscs -type f \( -name "*.md" -o -name "*.json" \) | sort | xargs sha256sum > /tmp/gotscs-v4.3.X-baseline.sha256`
3. Replace and start a NEW 48-hour HC-27 window

---

## Quick reference

| Constraint | What | When |
|---|---|---|
| HC-26 | 5-brief regression battery + backup | BEFORE replacement |
| HC-27 | 48-hour rollback window | AFTER replacement |
| HC-13b | Subagent module-delegation reads | Runtime (every spawn) — NOT release-related |

HC-13b is *not* the release gate (corrected from a prior misattribution in earlier docs). It's a subagent reading rule. The release gate is HC-26 + HC-27.
