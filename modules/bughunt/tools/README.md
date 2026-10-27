# Bug-hunt playbook tools

Mechanical helpers for **Shaydez's Web3 Bughunt Skill** (`iykes-web3-bughunt-skill`).
Judgment (severity, root cause, disclosure strategy) stays in `SKILL.md`. These
scripts only run the repeatable shell/python steps.

## Prerequisites

```bash
# Foundry (forge + cast)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Python 3 (stdlib only for the fillers)
# Debian/Ubuntu: sudo apt-get install -y python3
# macOS: brew install python3

# curl (usually preinstalled)
# gh is optional (only for Step 10 private disclosure repo creation)
# jq is optional (not required by these scripts)
```

Make scripts executable once:

```bash
chmod +x tools/*.sh tools/*.py
```

Optional: `CAST_TIMEOUT` (seconds, default 15–20) for cast wrappers that use `timeout(1)`.

Smoke-check graceful failures:

```bash
./tools/selftest.sh
```

## Scripts

### `step0_liveness_repo.sh` / `step0_liveness_onchain.sh` — Step 0 (Kynagos liveness gate)

Prove the code is the code that runs before hunting it (Kynagos `mind/LIVENESS.md`).

**Usage:** `step0_liveness_repo.sh <REPO_DIR> <FILE_PATH> [SYMBOL]`
Default branch + latest tag presence, working-copy drift, deprecated/test/mock path and comment
markers, recent "deprecate/replace" commits, live callers or declared entry point.
Exit 0 no blocking signal, 1 DEAD-candidate, 3 UNKNOWN.

**Usage:** `step0_liveness_onchain.sh <RPC_URL> <ADDRESS> [ARTIFACT_JSON]`
Resolves EIP-1967 proxy/beacon to the current implementation, confirms code is deployed, compares
runtime bytecode with a build artifact (metadata stripped). Read-only.
Exit 0 live/match, 1 no code or mismatch, 3 same length but differing bytes (check immutables).

### `humanize_check.py` — Steps 7, 9, 10 (Kynagos voice)

Flags machine-written tells in reports, DMs and PoCs: filler words, chatbot phrases, emoji,
em-dash crutches, banner logs, over-commenting. Exit 1 when a FIX-level tell is found.

**Usage:** `humanize_check.py FILE [FILE ...] [--strict]`

### `step1_ground_truth.sh` — Step 1

**Purpose:** Confirm RPC alive and chain id matches intake.

**Usage:** `step1_ground_truth.sh <RPC_URL> <EXPECTED_CHAIN_ID>`

**Example:**
```bash
./tools/step1_ground_truth.sh "https://rpc.example.chain" "4663"
```

**Prints:** chain-id, block-number, GATE PASS/FAIL.

**Exit:** `0` pass · `1` RPC error or chain mismatch · `2` usage

---

### `step2_creator_trace.sh` — Step 2A

**Purpose:** Trace token/position → creator (factory/core candidate) via Blockscout API.

**Usage:** `step2_creator_trace.sh <EXPLORER_API_V2_BASE> <TOKEN_OR_POSITION_ADDR>`

**Example:**
```bash
./tools/step2_creator_trace.sh "https://explorer.example/api/v2" \
  "0x1111111111111111111111111111111111111111"
```

**Prints:** `token`, `creator`, GATE line.

**Exit:** `0` creator found · `1` HTTP/JSON error · `2` usage

---

### `step2_bundle_grep.sh` — Step 2B

**Purpose:** Grep Vite/Next JS bundles for role-labeled `0x` addresses.

**Usage:** `step2_bundle_grep.sh <WEBSITE_URL>`

**Example:**
```bash
./tools/step2_bundle_grep.sh "https://app.example"
```

**Prints:** matching role/address lines or empty-grep GATE.

**Exit:** `0` HTML fetched (hits optional) · `1` fetch failed · `2` usage

---

### `step3_surface_map.sh` — Step 3

**Purpose:** Balance, code size, Sourcify verification, bytecode/tx selectors.

**Usage:** `step3_surface_map.sh <RPC_URL> <CHAIN_ID> <CONTRACT_ADDR> [EXPLORER_API_V2_BASE]`

**Example:**
```bash
./tools/step3_surface_map.sh "https://rpc.example.chain" "4663" \
  "0x2222222222222222222222222222222222222222" \
  "https://explorer.example/api/v2"
```

**Prints:** balance, code size, Sourcify match; may write `src.json`, `code.hex`, selector list.

**Exit:** `0` mapped · `1` hard RPC fail or no code · `2` usage

---

### `step4_auth_triage.sh` — Step 4

**Purpose:** `eth_call` admin/keeper sigs from attacker; flag `OPEN <-- CHECK`.

**Usage:** `step4_auth_triage.sh <RPC_URL> <CONTRACT_ADDR> [extra_sig ...]`

**Example:**
```bash
./tools/step4_auth_triage.sh "https://rpc.example.chain" \
  "0x2222222222222222222222222222222222222222" "setMigrator(address)"
```

**Prints:** per-sig `guarded` or `OPEN <-- CHECK`.

**Exit:** `0` triage done (OPEN is still 0) · `1` RPC failure · `2` usage

---

### `step7_poc_scaffold.sh` — Step 7

**Purpose:** Foundry PoC scaffold + SAFE fork-only skeleton; print `forge test` cmd.

**Usage:** `step7_poc_scaffold.sh <RPC_URL> <TARGET_ADDR> [POC_DIR]`

**Example:**
```bash
./tools/step7_poc_scaffold.sh "https://rpc.example.chain" \
  "0x2222222222222222222222222222222222222222" "poc"
```

**Prints:** path to `test/PoC.t.sol`, fork block, exact `forge test --fork-url ...` command.

**Exit:** `0` scaffold ready · `1` forge/cast missing or RPC fail · `2` usage

---

### `step9_report_skeleton.py` — Step 9

**Purpose:** Fill report markdown skeleton (researcher shaydez). No severity judgment.

**Usage:**
```text
step9_report_skeleton.py --project P --severity S --title T --chain C --chain-id ID
  [--core ADDR] [--bound TEXT] [--rpc URL] [--blk N] [-o PATH]
```

**Example:**
```bash
python3 ./tools/step9_report_skeleton.py \
  --project "example.fun" --severity High --title "one-line title" \
  --chain "Example Chain" --chain-id 4663 \
  --core 0x2222222222222222222222222222222222222222 \
  --bound "state the bound" -o reports/example-high.md
```

**Prints:** report markdown to stdout or `-o`.

**Exit:** `0` written · `2` missing required args / `--help`

---

### `step10_contact_hunt.sh` — Step 10A

**Purpose:** Fetch official docs/forum URLs and extract candidate security emails,
bounty-platform links, nearby quote lines, and Cloudflare-decoded `data-cfemail`.

**Usage:** `step10_contact_hunt.sh <URL> [URL ...]`

**Example:**
```bash
./tools/step10_contact_hunt.sh \
  "https://raw.githubusercontent.com/example/docs/master/faq.md" \
  "https://forum.example.com/t/bug-bounty/1.json"
```

**Prints:** per-URL emails, quotes, GATE line. Agent still writes
`reports/contacts.md` with URL + exact quote.

**Exit:** `0` at least one fetch ok · `1` all fetches failed · `2` usage

---

### `step10_dm_skeleton.py` — Step 10

**Purpose:** Fill first private DM text (voice: Shaydez / shaydez). No strategy judgment.

**Usage:**
```text
step10_dm_skeleton.py --project P --severity S --chain C --component FLOW --impact SENTENCE
  [--scope BOUND] [-o PATH]
```

**Example:**
```bash
python3 ./tools/step10_dm_skeleton.py \
  --project "example.fun" --severity High --chain "Example Chain" \
  --component "graduation flow" \
  --impact "an attacker can drain the raise into a fake-priced pool" \
  --scope "every un-graduated token" \
  -o reports/dm-example.md
```

**Prints:** DM text to stdout or `-o`.

**Exit:** `0` written · `2` missing required args / `--help`

---

### `selftest.sh`

**Purpose:** Confirm every script fails gracefully on missing args / prints usage.

**Usage:** `./tools/selftest.sh`

**Exit:** `0` all OK · `1` hang, cryptic crash, or wrong exit

---

## Summary table

| Script | Step | Inputs | Outputs / gates | Why this exists |
|---|---|---|---|---|
| `step0_liveness_repo.sh` | 0 | repo, file, [symbol] | LIVE / UNKNOWN / DEAD | Never hunt deprecated or unused code |
| `step0_liveness_onchain.sh` | 0 | RPC, address, [artifact] | current impl + bytecode match | Audit the version that is deployed |
| `humanize_check.py` | 7/9/10 | report, DM, PoC files | FIX / NOTE tells | Reports that read human |
| `step1_ground_truth.sh` | 1 | RPC, chain id | PASS/STOP on chain | Avoid hours on dead/scam RPCs |
| `step2_creator_trace.sh` | 2A | explorer API, token | creator address | Reliable factory/core discovery |
| `step2_bundle_grep.sh` | 2B | website URL | role-labeled 0x hits | Find hidden frontend config addrs |
| `step3_surface_map.sh` | 3 | RPC, chain, contract, [API] | balance, Sourcify, selectors | Verified vs unverified path |
| `step4_auth_triage.sh` | 4 | RPC, contract, [sigs] | guarded / OPEN | Free-win missing-auth check |
| `step7_poc_scaffold.sh` | 7 | RPC, target, [dir] | Foundry PoC + forge cmd | Repeatable fork-only proof setup |
| `step9_report_skeleton.py` | 9 | INTAKE + severity fields | report markdown | Same report shape every hunt |
| `step10_contact_hunt.sh` | 10A | official URLs | emails + quotes | Prove the real security inbox |
| `step10_dm_skeleton.py` | 10 | project/severity/impact | first DM text | Consistent private first contact |
| `selftest.sh` | — | none | pass/fail per script | CI-style smoke for tools |

**Reminder:** fork / `eth_call` only. Never exploit mainnet. Honest severity. Private until patched.
