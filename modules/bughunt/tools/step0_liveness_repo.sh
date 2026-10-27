#!/usr/bin/env bash
# =============================================================================
# step0_liveness_repo.sh
#
# Purpose:
#   Before any hunting on a file, check that the code is the code that ships.
#   Kynagos mind/LIVENESS.md, gate L0. A bug in deprecated, removed, unused,
#   mock, test or example code is not a finding.
#
# Usage:
#   step0_liveness_repo.sh <REPO_DIR> <FILE_PATH> [SYMBOL]
#
# Args:
#   REPO_DIR   local git clone of the target
#   FILE_PATH  path of the file under review, relative to REPO_DIR
#   SYMBOL     optional function / contract / class name to look for callers of
#
# Example:
#   ./tools/step0_liveness_repo.sh ~/targets/vault src/Vault.sol withdrawAll
#
# Exit codes:
#   0  no blocking signal found (still needs scope + deployment proof)
#   1  DEAD: file missing on the default branch, or symbol has no callers
#   2  bad usage / --help
#   3  UNKNOWN: warning signals that must be resolved before reporting
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step0_liveness_repo.sh <REPO_DIR> <FILE_PATH> [SYMBOL]

Check that a file (and optionally a symbol) is live code on the default branch
and latest release, not deprecated, removed, unused, test, mock or example code.

Args:
  REPO_DIR   local git clone of the target
  FILE_PATH  path relative to REPO_DIR
  SYMBOL     optional function / contract / class name

Exit: 0 no blocking signal; 1 dead; 2 usage; 3 unknown (resolve warnings)
EOF
  exit 2
}

if [[ $# -ge 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -ge 2 ]] || usage
REPO="$1"
FILE="$2"
SYMBOL="${3:-}"

if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: $REPO is not a git repository" >&2
  exit 2
fi

fails=0
warns=0
pass() { echo "  PASS  $*"; }
warn() { echo "  WARN  $*"; warns=$((warns + 1)); }
fail() { echo "  FAIL  $*"; fails=$((fails + 1)); }

# Default branch: origin/HEAD if known, else main, else master, else current HEAD.
DEFAULT=""
if ref=$(git -C "$REPO" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null); then
  DEFAULT="$ref"
else
  for b in origin/main origin/master main master; do
    if git -C "$REPO" rev-parse -q --verify "$b^{commit}" >/dev/null 2>&1; then DEFAULT="$b"; break; fi
  done
fi
[[ -n "$DEFAULT" ]] || DEFAULT="HEAD"
DEFAULT_SHA=$(git -C "$REPO" rev-parse --short "$DEFAULT")

echo "== STEP 0: liveness (repo) =="
echo "repo:            $REPO"
echo "default branch:  $DEFAULT @ $DEFAULT_SHA"
echo "working HEAD:    $(git -C "$REPO" rev-parse --short HEAD)"
echo "file:            $FILE"
[[ -n "$SYMBOL" ]] && echo "symbol:          $SYMBOL"
echo

# 1. File exists on the default branch.
if git -C "$REPO" cat-file -e "$DEFAULT:$FILE" 2>/dev/null; then
  pass "file exists on $DEFAULT"
else
  fail "file is NOT on $DEFAULT (removed, renamed, or only on a side branch)"
  last=$(git -C "$REPO" log --all -1 --format='%h %ad %s' --date=short -- "$FILE" 2>/dev/null || true)
  [[ -n "$last" ]] && echo "        last commit touching it: $last"
fi

# 2. Working copy matches the default branch for this file.
if git -C "$REPO" cat-file -e "$DEFAULT:$FILE" 2>/dev/null && [[ -f "$REPO/$FILE" ]]; then
  if git -C "$REPO" diff --quiet "$DEFAULT" -- "$FILE" 2>/dev/null; then
    pass "working copy matches $DEFAULT"
  else
    warn "working copy differs from $DEFAULT; you may be reading a version that does not ship"
  fi
fi

# 3. Latest release tag reachable from the default branch.
TAG=$(git -C "$REPO" describe --tags --abbrev=0 "$DEFAULT" 2>/dev/null || true)
if [[ -z "$TAG" ]]; then
  warn "no release tag found; prove the deployed version another way (bytecode match, scope listing)"
elif git -C "$REPO" cat-file -e "$TAG:$FILE" 2>/dev/null; then
  if git -C "$REPO" diff --quiet "$TAG" "$DEFAULT" -- "$FILE" 2>/dev/null; then
    pass "file identical in latest tag $TAG"
  else
    warn "file changed since latest tag $TAG; confirm which version is deployed"
  fi
else
  warn "file is not in latest tag $TAG (unreleased, or added after the release)"
fi

# 4. Path smells.
lower=$(echo "$FILE" | tr '[:upper:]' '[:lower:]')
if echo "$lower" | grep -qE '(^|/)(deprecated|legacy|old|archive[sd]?|unused|attic|graveyard|backup|bak)(/|_|-|\.|$)'; then
  fail "path looks deprecated/archived: $FILE"
elif echo "$lower" | grep -qE '(^|/)(tests?|spec|mocks?|fixtures?|examples?|samples?|demo|scripts?|testing|harness|echidna|medusa|certora)(/|$)|\.t\.sol$|(test|mock)[^/]*\.[a-z]+$'; then
  warn "path looks like test/mock/example/script code: $FILE"
else
  pass "path has no deprecated/test/mock smell"
fi

# 5. In-file markers.
if [[ -f "$REPO/$FILE" ]]; then
  # Only comment lines (//, #, *, /*, --, <!--) so identifiers like unusedFoo do not trip it.
  markers=$(grep -niE '(//|#|/\*|^\s*\*|--|<!--).*(@deprecated|\bdeprecated\b|\blegacy\b|no longer used|not used|\bunused\b|do not use|kept for (storage|backwards|compat)|to be removed|remove (me|this|after))' "$REPO/$FILE" | head -5 || true)
  if [[ -n "$markers" ]]; then
    warn "deprecation/unused markers inside the file:"
    echo "$markers" | sed 's/^/        /'
  else
    pass "no deprecation markers inside the file"
  fi
fi

# 6. Recent history: was it superseded?
recent=$(git -C "$REPO" log "$DEFAULT" -5 --format='%h %ad %s' --date=short -- "$FILE" 2>/dev/null || true)
if echo "$recent" | grep -qiE 'deprecat|remove|replace|legacy|migrat|v2|sunset|disable'; then
  warn "recent commits mention deprecation/replacement:"
  echo "$recent" | sed 's/^/        /'
fi

# 7. Callers of the symbol outside the file and outside tests.
if [[ -n "$SYMBOL" ]]; then
  callers=$(git -C "$REPO" grep -nwI "$SYMBOL" "$DEFAULT" -- . \
    ":(exclude)$FILE" ':(exclude)*test*' ':(exclude)*Test*' ':(exclude)*mock*' ':(exclude)*Mock*' \
    ':(exclude)*.md' ':(exclude)docs/*' ':(exclude)*.t.sol' 2>/dev/null | head -20 || true)
  n=$(echo -n "$callers" | grep -c '' || true)
  internal=$(git -C "$REPO" grep -cwI "$SYMBOL" "$DEFAULT" -- "$FILE" 2>/dev/null | awk -F: '{print $NF}' || echo 0)
  if [[ "$n" -gt 0 ]]; then
    pass "symbol '$SYMBOL' referenced in $n other non-test place(s):"
    echo "$callers" | sed "s|^$DEFAULT:||" | head -5 | sed 's/^/        /'
  elif [[ "${internal:-0}" -gt 1 ]]; then
    warn "symbol '$SYMBOL' only referenced inside its own file; confirm it is an external/public entry point or called internally"
  elif [[ -f "$REPO/$FILE" ]] && grep -E "\b$SYMBOL\b" "$REPO/$FILE" | grep -qE '\b(external|public)\b|pub (async )?fn|^\s*export |@(app|router)\.|#\[(ink\(message|pallet::call)'; then
    warn "symbol '$SYMBOL' has no callers in the repo but is declared as an entry point; prove it is in the deployed ABI/routes and in scope"
  else
    fail "symbol '$SYMBOL' has no callers outside tests and is not an entry point; treat as dead code"
  fi
fi

echo
if [[ $fails -gt 0 ]]; then
  echo "VERDICT: DEAD-candidate ($fails fail, $warns warn). Do not hunt or report this as live code."
  exit 1
elif [[ $warns -gt 0 ]]; then
  echo "VERDICT: UNKNOWN ($warns warn). Resolve every warning before calling anything here CONFIRMED."
  exit 3
fi
echo "VERDICT: no blocking signal. Still prove scope + deployment (step0_liveness_onchain.sh or scope listing)."
exit 0
