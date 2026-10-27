#!/usr/bin/env bash
# =============================================================================
# skill_doctor.sh
#
# Purpose:
#   Health check for the Kynagos skill itself (mind/RETRO.md). Run before
#   publishing a change.
#
# Usage:
#   bash tools/skill_doctor.sh
#
# Checks:
#   1. every modules/... and mind/... path named in SKILL.md exists
#   2. module SKILL.md names are unique and prefixed kynagos-
#   3. tool scripts are executable and pass modules/bughunt/tools/selftest.sh
#   4. pipeline validator tests pass (node --test)
#   5. no module pipes remote content into a shell or fetches remote skill text
#
# Exit codes:
#   0  healthy (warnings allowed)
#   1  at least one failure
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fails=0
warns=0
pass() { echo "  PASS  $*"; }
warn() { echo "  WARN  $*"; warns=$((warns + 1)); }
fail() { echo "  FAIL  $*"; fails=$((fails + 1)); }

echo "== kynagos skill doctor =="
echo "root: $ROOT"

echo "-- 1. paths referenced by SKILL.md"
missing=0
while read -r ref; do
  path="${ref%%§*}"
  path="${path%%#*}"
  [[ -z "$path" ]] && continue
  # strip trailing punctuation and glob/placeholder refs
  path="${path%%[),.;:]}"
  [[ "$path" == *"<"* || "$path" == *"*"* ]] && continue
  if [[ ! -e "$path" ]]; then fail "SKILL.md names missing path: $path"; missing=$((missing + 1)); fi
done < <(grep -oE '(modules|mind|tools)/[A-Za-z0-9_./-]+' SKILL.md | sort -u)
[[ $missing -eq 0 ]] && pass "all referenced paths exist"

echo "-- 2. module names"
names=$(grep -hE '^name:' modules/*/SKILL.md modules/*/skills/*/SKILL.md 2>/dev/null | awk '{print $2}')
dups=$(echo "$names" | sort | uniq -d)
[[ -n "$dups" ]] && fail "duplicate module names: $dups" || pass "module names unique"
bad=$(echo "$names" | grep -v '^kynagos' || true)
[[ -n "$bad" ]] && warn "module names without kynagos- prefix: $(echo $bad)" || pass "module names prefixed"

echo "-- 3. tools"
nonexec=$(find modules/*/tools modules/*/scripts tools -type f \( -name '*.sh' -o -name '*.py' \) ! -perm -u+x 2>/dev/null || true)
[[ -n "$nonexec" ]] && warn "not executable: $(echo $nonexec)" || pass "scripts executable"
if bash modules/bughunt/tools/selftest.sh >/tmp/kynagos-selftest.log 2>&1; then
  pass "bughunt selftest"
else
  fail "bughunt selftest failed (see /tmp/kynagos-selftest.log)"
fi

echo "-- 4. validators"
if command -v node >/dev/null 2>&1; then
  if node --test modules/pipeline/validate-findings.test.cjs modules/pipeline/validate-coverage-ledger.test.cjs \
      >/tmp/kynagos-node.log 2>&1; then
    pass "pipeline validator tests"
  else
    fail "pipeline validator tests failed (see /tmp/kynagos-node.log)"
  fi
else
  warn "node not installed; validator tests skipped"
fi

echo "-- 5. remote instruction / self-update patterns"
risky=$(grep -rnE '(curl|wget)[^|]*\|\s*(ba)?sh|raw\.githubusercontent\.com/[^ ]*(SKILL|VERSION)' modules mind SKILL.md 2>/dev/null \
  | grep -v 'skill_doctor' || true)
if [[ -n "$risky" ]]; then
  warn "remote fetch patterns (SKILL.md rule 10 overrides them; review):"
  echo "$risky" | head -10 | sed 's/^/        /'
else
  pass "no remote fetch patterns"
fi

echo
if [[ $fails -gt 0 ]]; then echo "DOCTOR: $fails fail, $warns warn"; exit 1; fi
echo "DOCTOR: healthy ($warns warn)"
exit 0
