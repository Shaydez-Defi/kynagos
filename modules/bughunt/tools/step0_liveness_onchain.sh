#!/usr/bin/env bash
# =============================================================================
# step0_liveness_onchain.sh
#
# Purpose:
#   Prove that the contract you are reading is the contract that is deployed.
#   Kynagos mind/LIVENESS.md, gate L0. Resolves EIP-1967 proxies and beacons,
#   then compares deployed runtime bytecode with a local build artifact.
#   Read-only: eth_getCode and eth_getStorageAt only.
#
# Usage:
#   step0_liveness_onchain.sh <RPC_URL> <ADDRESS> [ARTIFACT_JSON]
#
# Args:
#   RPC_URL        JSON-RPC endpoint
#   ADDRESS        the in-scope address (proxy or implementation)
#   ARTIFACT_JSON  optional Foundry/Hardhat artifact with deployedBytecode
#
# Example:
#   ./tools/step0_liveness_onchain.sh "$RPC" 0xAbc... out/Vault.sol/Vault.json
#
# Exit codes:
#   0  code deployed, and matches the artifact if one was given
#   1  no code at the address/implementation, bytecode mismatch, or RPC error
#   2  bad usage / --help
#   3  UNKNOWN: same length but not identical (immutables, linked libraries,
#      compiler settings); resolve by hand before calling it live
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step0_liveness_onchain.sh <RPC_URL> <ADDRESS> [ARTIFACT_JSON]

Resolve EIP-1967 proxy/beacon, confirm code is deployed, and compare runtime
bytecode with a local artifact (metadata stripped). Read-only.

Exit: 0 live/match; 1 no code or mismatch or RPC error; 2 usage; 3 unknown
EOF
  exit 2
}

if [[ $# -ge 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -ge 2 ]] || usage
RPC="$1"
ADDR="$2"
ART="${3:-}"

if [[ ! "$ADDR" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  echo "error: address must be 0x + 40 hex chars" >&2
  exit 2
fi
command -v cast >/dev/null 2>&1 || { echo "error: cast (Foundry) is required" >&2; exit 2; }
if [[ -n "$ART" ]]; then
  command -v jq >/dev/null 2>&1 || { echo "error: jq is required to read the artifact" >&2; exit 2; }
  [[ -f "$ART" ]] || { echo "error: artifact not found: $ART" >&2; exit 2; }
fi

export CAST_TIMEOUT="${CAST_TIMEOUT:-20}"
run_cast() {
  if command -v timeout >/dev/null 2>&1; then timeout "$CAST_TIMEOUT" cast "$@"; else cast "$@"; fi
}

IMPL_SLOT=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
BEACON_SLOT=0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50
ZERO=0x0000000000000000000000000000000000000000000000000000000000000000

slot_to_addr() { echo "0x${1: -40}"; }

echo "== STEP 0: liveness (on-chain) =="
block=$(run_cast block-number --rpc-url "$RPC" 2>&1) || { echo "GATE: FAIL — RPC error: $block" >&2; exit 1; }
echo "block:   $block (record this in the finding's target_version)"
echo "address: $ADDR"

TARGET="$ADDR"
impl=$(run_cast storage "$ADDR" "$IMPL_SLOT" --rpc-url "$RPC" 2>/dev/null || echo "$ZERO")
beacon=$(run_cast storage "$ADDR" "$BEACON_SLOT" --rpc-url "$RPC" 2>/dev/null || echo "$ZERO")
if [[ "$impl" != "$ZERO" ]]; then
  TARGET=$(slot_to_addr "$impl")
  echo "proxy:   EIP-1967, current implementation $TARGET"
  echo "         audit THIS implementation, not an older one from the repo or an explorer tab"
elif [[ "$beacon" != "$ZERO" ]]; then
  b=$(slot_to_addr "$beacon")
  TARGET=$(run_cast call "$b" "implementation()(address)" --rpc-url "$RPC" 2>/dev/null || echo "")
  echo "proxy:   EIP-1967 beacon $b, current implementation ${TARGET:-unknown}"
  [[ -n "$TARGET" ]] || { echo "GATE: UNKNOWN — beacon implementation() did not answer"; exit 3; }
else
  echo "proxy:   no EIP-1967 slot set (not a standard proxy; check custom proxy patterns by hand)"
fi

code=$(run_cast code "$TARGET" --rpc-url "$RPC" 2>&1) || { echo "GATE: FAIL — RPC error: $code" >&2; exit 1; }
code="${code#0x}"
if [[ -z "$code" ]]; then
  echo "GATE: FAIL — no code at $TARGET (self-destructed, never deployed, or wrong chain)"
  exit 1
fi
echo "code:    $(( ${#code} / 2 )) bytes at $TARGET"

if [[ -z "$ART" ]]; then
  echo "GATE: PASS (code deployed). No artifact given, so source identity is NOT proven;"
  echo "      use verified source on the explorer or pass a build artifact."
  exit 0
fi

local_code=$(jq -r '.deployedBytecode.object // .deployedBytecode // empty' "$ART")
local_code="${local_code#0x}"
[[ -n "$local_code" && "$local_code" != "null" ]] || { echo "error: no deployedBytecode in $ART" >&2; exit 2; }

# Strip the CBOR metadata tail: last 2 bytes give its length.
strip_meta() {
  local hex="$1" n
  n=$(( 16#${hex: -4} ))
  if (( n > 0 && n * 2 + 4 < ${#hex} )); then echo "${hex:0:$(( ${#hex} - n * 2 - 4 ))}"; else echo "$hex"; fi
}
a=$(strip_meta "$(echo "$code" | tr 'A-F' 'a-f')")
b=$(strip_meta "$(echo "$local_code" | tr 'A-F' 'a-f')")

if [[ "$a" == "$b" ]]; then
  echo "GATE: PASS — deployed runtime matches $ART (metadata stripped)"
  exit 0
elif [[ ${#a} -eq ${#b} ]]; then
  diffs=0
  for (( i = 0; i < ${#a}; i += 2 )); do [[ "${a:i:2}" == "${b:i:2}" ]] || diffs=$((diffs + 1)); done
  echo "GATE: UNKNOWN — same length, $diffs byte(s) differ. Usually immutables or linked libraries."
  echo "      Confirm those bytes are immutables (constructor args) before calling the source live."
  exit 3
fi
echo "GATE: FAIL — deployed code ($(( ${#a} / 2 )) B) does not match artifact ($(( ${#b} / 2 )) B)."
echo "      You are probably reading a different version. Find the commit that matches before hunting."
exit 1
