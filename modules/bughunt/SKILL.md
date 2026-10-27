---
name: kynagos-bughunt
description: >-
  End-to-end smart-contract bug-hunting playbook (researcher: shaydez). Invoke to
  hunt vulnerabilities in an EVM smart contract / DeFi protocol and turn a finding
  into a responsible, paid disclosure. Fill the INTAKE block, then run the steps in
  order. Mechanical probes live in tools/; each step has decision gates and
  fill-in templates for the PoC, report, and disclosure message. Verification is
  fork / eth_call ONLY. Never exploit mainnet. Be token-conservative; use smaller
  models for capable subtasks. After surface map, run foundation maps, multi-angle
  adversarial passes, dual-ledger / complex-logic hunts, and honest severity
  (including kill temporary-vs-persistent conditions). Keep a Low, Medium, or
  High when it is a lead or attack-path step toward a Critical, and report every
  confirmed Low, Medium, or High at its real severity. Maintain coverage.md
  incrementally (files opened, paths traced, %, exclusions); never imply a
  complete audit when coverage is low.
  Use when the user names a target (project, handle, or website) and wants it
  audited for bounties, or says "hunt", "audit this", "find bugs".
---

# Shaydez's Web3 Bughunt Skill

By **shaydez**. Fill the INTAKE, then execute the steps top to bottom. Mechanical
probes are scripts under `tools/`; decision gates tell you exactly what to do next.
You should not have to invent the repeatable parts — run the tool, read the gate.

### Core Principle: Proactive Problem-Solving

**When you hit a blocker, find or build a solution. Do NOT stop at "tool not available" 
or "data unavailable".**

Examples of proactive problem-solving:
- **Unverified contracts?** → Search for and install decompilers (Panoramix, Dedaub API), 
  use bytecode analysis, create Foundry fork tests
- **Missing tool?** → Install with pip/cargo/npm/apt, or find online alternatives
- **Unsupported chain?** → Find RPC endpoints via chainlist.org, check docs, use explorers
- **No API access?** → Scrape data, use alternative sources, query on-chain directly
- **Rate limited?** → Use multiple providers, add delays, cache results
- **Unknown function selectors?** → Use 4byte.directory, analyze bytecode patterns, test behavior
- **Need to find project resources?** → Use `gh search` (repos, code, issues, commits), 
  web search for docs/announcements, explore GitHub org structure

**Document every workaround** so future hunts benefit. Add new tools to this skill's 
`tools/` directory when they prove useful. The goal is continuous improvement of the 
methodology.

### Pair with EVM audit skills

After Step 3 has source (or a solid surface map), also load **`evm-audit-master`**
and follow its routing table. Always pull `evm-audit-general` +
`evm-audit-precision-math`. For launchpads also load `evm-audit-defi-amm`,
`evm-audit-erc20`, `evm-audit-access-control`, `evm-audit-dos`, and usually
`evm-audit-flashloans` + `evm-audit-chain-specific` (Robinhood Chain is an L2).
For multi-strategy / ERC-4626 / agent vaults also load `evm-audit-erc4626`,
`evm-audit-defi-amm` (if swaps), and `evm-audit-oracles` if any external price.
Use audit checklists to find bugs; use this playbook for intake, fork PoC, severity
bound, report (researcher shaydez / Shaydez), and private disclosure DM.

### Optional: forefy /.context skills

If installed (e.g. from `forefy/.context`), you may also load:

| Skill | When |
|---|---|
| `smart-contract-audit` | Full multi-expert pass; write outputs under project `.context/outputs/N/` |
| `tiny-auditor` | Critical-only, low false-positive finding format and severity formula |
| `foundry-poc` | Runnable Foundry tests that prove net fund impact, not pseudocode |

This playbook stays the **lead** for bounty hunt intake, gates, disclosure, and
honest bounds. Companion skills deepen analysis; they do not replace Steps 1–10.

### Token budget and model routing (apply on every hunt)

Be **token-conservative** for the whole hunt. Prefer cheap, narrow work over
reloading giant contexts. Employ **smaller / faster models** (or lightweight
subagents) wherever they are capable; reserve the primary high-capability model
for judgment-heavy steps only.

| Prefer small / cheap model or subagent | Keep on primary (high-capability) model |
|---|---|
| `cast` / RPC probes, address greps, bundle scrapes | Severity call and kill-your-own-finding |
| Listing holders, pots, codesize, auth-triage loops | Root-cause reading of value-moving paths |
| File search, log tails, compiling forge, running tests | Novel attack design and exploit sequencing |
| Drafting report/DM from a filled template | Final report accuracy and bound honesty |
| Parallel explore lanes with narrow prompts | Disclosure strategy if ambiguous |
| Slither / static JSON triage (report a confirmed Low, rule 15) | Complex multi-tx economic logic |

Rules:
1. **Do not re-read entire skills** every turn. Load this playbook once per hunt;
   load only the one EVM checklist section you need for the product type.
   For mechanical steps, run the matching script in the **Tools** table below —
   do not re-derive the bash/python by hand.
2. **Shell first for facts.** Prefer `cast`/`curl`/`rg` (or `tools/*.sh`) over long
   model reasoning when the answer is an on-chain number or a string in a file.
3. **Narrow tool output.** Cap logs, `head` greps, avoid dumping megabyte bundles
   into context; write to files and read slices.
4. **One finding path at a time** until confirmed or killed. No shotgun of five
   parallel deep dives unless each is a small explore subagent with a tight prompt.
5. **Subagents:** use `explore` (read-only) or a small model for map/grep/auth
   triage; bring results back as short bullets. Parent model decides go/no-go.
6. **PoC:** smallest test that proves the bound. Prefer exact-logic local PoC +
   on-chain magnitude over multi-hour full-holder forks when RPC is slow.
7. **User updates:** short status (what proven, what next). No essay recaps of
   tool logs.
8. **Chunk, do not dump.** For complex logic, feed one mechanism at a time
   (redeem path, allocate/budget path, one adapter) with a single adversarial
   question. Full-repo paste increases hallucination and misses interactions.
9. **Coverage tracking is mandatory.** Update `coverage.md` as you read files and
   trace paths (see **Coverage tracking** below). Do not invent thoroughness.

---

## Attack paths to explore FIRST (EVM: Solidity / Vyper)

Before anything else, run every target against this checklist. These are the
highest-yield classes for EVM bounties. For each one, ask "can a stranger reach
this with valid calls?" and write a one-line verdict (reachable / blocked / N/A)
into `coverage.md`. Chase the reachable ones to a fork PoC. Order is rough
priority, not a filter: skip none without a reason logged.

1. Fund draining - direct theft via flawed withdrawal, accounting, or authorization logic.
2. Access control failures - missing or broken role checks, unprotected initializers, forgotten onlyOwner modifiers.
3. Reentrancy - single-function, cross-function, and read-only reentrancy via stale view functions.
4. Oracle manipulation - flash-loan price distortion, thin-liquidity pools, stale or single-source price feeds.
5. Arithmetic and logic errors - overflow/underflow (pre-0.8), rounding-direction errors, off-by-one in accounting.
6. Vault / share inflation - first depositor manipulates share price via direct token donation.
7. Donation attacks - direct token transfer desyncs internal balance tracking from actual holdings.
8. Flash-loan attacks - borrowed capital manipulating accounting, collateral ratios, or governance in one tx.
9. Liquidation manipulation - manipulating price or health factor to trigger unfair liquidations.
10. Governance attacks - flash-loaned voting power, low-quorum exploitation, proposal griefing, timelock bypass.
11. Signature and replay - missing nonce, missing chain id, signature malleability, missing deadline checks.
12. Upgrade and proxy - storage slot collision, unprotected upgrade function, uninitialized proxy implementation.
13. Delegatecall injection - untrusted delegatecall target executes arbitrary code in caller's storage context.
14. Composability risk - malicious or nonstandard ERC20 hooks (ERC777, fee-on-transfer, rebasing tokens).
15. Unchecked external call return values - silent failures on transfer/call treated as success.
16. Denial of service - unbounded loops, forced reverts, blocking shared resources.
17. Gas griefing - forcing out-of-gas via unbounded loops or malicious callback gas consumption.
18. Front-running and MEV - front-running, sandwich attacks, backrunning, generalized frontrunning bots.
19. Block stuffing - flooding the network to block time-sensitive functions (liquidations, auction ends).
20. Insecure randomness - blockhash/timestamp-based RNG, predictable seed sources.
21. Cross-chain bridge attacks - message replay, fake proof acceptance, signature verification bypass.
22. Merkle proof manipulation - malformed or duplicate leaves, missing proof uniqueness checks.
23. Self-destruct griefing - forcing ETH into a contract via selfdestruct to break balance logic.
24. Phantom function / fallback abuse - unexpected fallback execution via selector clashes.

---

## INTAKE - fill this in before running

Fill only fields you actually know. In the written report, **omit any key whose value is
unknown** (do not print `KEY : unknown` or empty placeholders). Drop the whole line.
`none` is fine when that is a real answer (e.g. no bounty program). Prefer leaving a
field out over guessing.

```
PROJECT_NAME   : <e.g. hood.fun>
X_HANDLE       : <e.g. @hooddotfun>          # only if verified official; private disclosure
WEBSITE        : <https://...>               # app URL (where tokens/positions render)
DOCS           : <https://docs...>           # only if known
SECURITY_EMAIL : <security@... or omit>      # fill in Step 10A from a quoted official page
DISCLOSURE     : <immunefi URL / "discretionary" / omit>
CHAIN          : <e.g. Robinhood Chain>
RPC            : <https://...>               # confirm in Step 1
CHAIN_ID       : <e.g. 4663>
EXPLORER       : <Blockscout base>
KNOWN_ADDRS    : <role=0x... pairs; omit line if none known>
PRODUCT_TYPE   : <launchpad | lending/CDP | vault | multi-strategy-vault | perps | distribution/index | other>
BOUNTY/CONTEST : <live program? amount? or "none / discretionary">
NOTES          : <optional extras; omit if empty>
RESEARCHER     : shaydez
```

Set shell vars from the intake and reuse them:
```bash
RPC="<RPC>"; CID="<CHAIN_ID>"; BS="<EXPLORER>/api/v2"
# TOOLS=path/to/tools  # if not already on PATH / cwd-relative
```

---

## Operating rules (non-negotiable read once, apply always)

1. **Fork / `eth_call` verification only. Never move real funds on mainnet.** A
   passing fork test is the proof. This does not bend for revenge, "I'll give it
   back", or "just to prove it".
2. **Honest severity.** State the bound. A Medium is a Medium. Do not upgrade High
   to Critical because the story is dramatic.
3. **Ask, never threaten.** No "pay or I release/exploit". That's extortion.
4. **Kill your own finding if it doesn't hold up.** Disproving yourself is the job.
5. **Never publish a live, unpatched bug.** Private channel + private repo until fixed.
6. **Audit contracts, not narratives.** Day-one hype with no verifiable contract =
   scam trap. Sketchy TLDs (`.online`, `.cash`, brand-impersonation) = assume
   phishing until proven; never connect a wallet to them.
7. **Token-conservative; smaller models when capable.** Every hunt. See
   "Token budget and model routing" above. Do not burn context on bulk RPC spam,
   full-file dumps, or re-loading every skill for mechanical steps.
8. **Separate trust-root from permissionless.** Owner/agent-by-design power is not
   a Critical stranger exploit. Label Trust/centralization honestly.
9. **Temporary condition != permanent condition.** One-block price manip that is
   restored often leaves victims whole. Persistent stuck/depeg while NAV still
   marks face value is a different finding. Kill the first before claiming the second.
10. **Coverage tracking.** Maintain `coverage.md` for the whole hunt. Update it
    **when you open a file or finish tracing a path**, not only at the end. Opening
    a file without tracing its value-moving logic does not count as path coverage.
    If coverage is low, say so explicitly in the report and user status; never
    imply a complete audit was performed.
11. **Overcome blockers proactively.** When you encounter a blocker (unverified 
    contracts, missing tools, unsupported chains, unavailable data), actively search
    for and install/use tools that solve the problem. Search the internet for 
    decompilers, analyzers, APIs, or alternative data sources. Install packages 
    with pip/cargo/npm when needed. Create scripts to automate repetitive tasks.
    Do NOT stop at "source code unavailable" or "tool not installed" - find a way 
    forward. Document the tools used and methods employed so future hunts benefit.
15. **Chain leads to a Critical.** Hunt and keep a Low, Medium, or High when it
    can be a step on an attack path to a Critical. A usable step is a missing
    check, a weak invariant, griefing, a rounding leak, an oracle gap, a trust
    assumption, or a partial auth bypass that combines with another bug, a
    reachable state, or a second call into unauthenticated theft, a freeze, or
    unbounded loss. Record the lead at its honest severity (rule 2). Name the
    missing piece that would make the chain Critical, and try that chain before
    you close the path. If the chain is confirmed with a fork PoC, report the
    chain severity, not the piece alone. If the second piece is missing, keep a
    lead line that names what is missing. Drop the lead only when the chain is
    impossible: the state is unreachable, the auth cannot be bypassed, or the
    condition restores and leaves victims whole. Do not upgrade the piece by
    itself. Report every confirmed Low, Medium, and High, whether or not it
    chains. Write the Step 9 report and include it in the private disclosure at
    that severity. Do not leave it only in hunt notes, and do not wait for a
    Critical before you report it. Killed findings and false positives stay out
    of the report.

---

## Coverage tracking (mandatory every hunt)

During any bug-hunting or security-audit session, maintain a **`coverage.md`**
file that tracks what was actually examined.

### Where to put it

Prefer one of (first match wins for the session):

1. Hunt workspace root: e.g. `hunts/<project>/coverage.md`
2. Audit output dir: e.g. `.context/outputs/<N>/coverage.md` or `hunts/<project>/audit/coverage.md`
3. Repo root of the target under audit (only if that repo is a private hunt workspace)

Do **not** leave coverage only in chat. It must be a file on disk.

### What to track

1. **Files opened** — every source file read during the audit, with path (relative
   to the target repo when possible).
2. **Code paths followed** — not just files touched, but which functions/flows were
   actually traced (e.g. `deposit → _withdraw → _ensureIdle → retreatSelf →
   adapter.withdraw → Uni swap` across `AumoPool.sol` + `RwaUsdgAdapter.sol`).
   A file can be opened without its logic being understood; say so in Notes if
   only skimming.
3. **Coverage percentage** — `files read / total relevant files` in scope, updated
   as the audit progresses. Define the denominator early (e.g. all `src/**/*.sol`
   excluding `lib/`, or all app modules excluding tests).
4. **Explicitly excluded areas** — files/modules deliberately skipped, with a
   one-line reason (e.g. `excluded: test fixtures`, `excluded: generated types`,
   `excluded: vendor OZ under lib/`).

### Format (running table)

Keep a **summary line at the top**, then the table, then exclusions.

```markdown
# Coverage — <PROJECT>

Coverage: X/Y files (Z%).

Last updated: <ISO date or step name>

| File | Read? | Paths traced | Notes |
|------|-------|--------------|-------|
| src/Foo.sol | yes | `bar()` → `baz()` value path | full read |
| src/Bar.sol | partial | skim only | not traced |

## Explicitly excluded

| Path / area | Reason |
|-------------|--------|
| lib/** | vendored dependencies |
| test/** | fixtures / unit tests (unless hunting test-only bugs) |
```

### Update rules

- **Incremental, not retroactive.** When you `read` a file or finish tracing a flow,
  update the row the same turn (or immediately after the batch of reads).
- **Read? values:** `yes` | `partial` | `no` (no only for planned-but-not-yet).
- **Paths traced** empty or `—` means file opened but logic not followed; that does
  **not** inflate the “understood” claim. For Z%, count a file as covered only if
  `Read?` is `yes` or `partial` with at least one real path traced; optional:
  report both “opened %” and “traced %” if partials dominate.
- **Denominator Y:** set after inventory (Step 3 / source tree). If Y changes
  (new modules found), update Y and Z.
- **Low coverage gate:** before Step 9 / final user summary, if Z < 50% of
  in-scope production code (or fewer than the core value-moving files), state
  explicitly: `Coverage incomplete: Z% (X/Y). Findings apply to examined paths
  only.` Do not use language that implies a full audit.
- **Token budget:** coverage.md is short tables; do not dump file contents into it.

### Template bootstrap (create at hunt start)

```bash
# after INTAKE, once PROJECT_NAME and hunt dir are known
# HUNT_DIR=hunts/<project>   # or audit output dir
cat > "$HUNT_DIR/coverage.md" <<'EOF'
# Coverage — <PROJECT_NAME>

Coverage: 0/Y files (0%).  # set Y after inventory

Last updated: intake

| File | Read? | Paths traced | Notes |
|------|-------|--------------|-------|

## Explicitly excluded

| Path / area | Reason |
|-------------|--------|
| lib/** or node_modules/** | vendored |
| test/** or **/*_test* | tests (exclude unless in scope) |
EOF
```

---

## Tools

Mechanical scripts next to this playbook (`tools/`). Prerequisites and full docs:
`tools/README.md`. Run from the hunt workspace; scripts fail non-zero on RPC errors
instead of hanging. Smoke-check: `./tools/selftest.sh`.

| Script | Step | Inputs | Outputs / gates | Why this exists |
|---|---|---|---|---|
| `tools/step1_ground_truth.sh` | 1 | `<RPC> <CHAIN_ID>` | chain-id + block-number; **PASS** or **STOP** | Avoid hours on dead/scam RPCs |
| `tools/step2_creator_trace.sh` | 2A | `<BS> <TOKEN_ADDR>` | creator address (factory/core candidate) | Reliable factory/core discovery |
| `tools/step2_bundle_grep.sh` | 2B | `<WEBSITE>` | role-labeled `0x` hits from JS bundles | Find hidden frontend config addrs |
| `tools/step3_surface_map.sh` | 3 | `<RPC> <CID> <CONTRACT> [BS]` | balance, code size, Sourcify / selectors | Verified vs unverified path |
| `tools/step4_auth_triage.sh` | 4 | `<RPC> <CONTRACT> [extra_sig ...]` | per-sig `guarded` / `OPEN <-- CHECK` | Free-win missing-auth check |
| `tools/step7_poc_scaffold.sh` | 7 | `<RPC> <TARGET> [POC_DIR]` | Foundry PoC skeleton + fork `forge test` cmd | Repeatable fork-only proof setup |
| `tools/step9_report_skeleton.py` | 9 | INTAKE + severity + title (+ optional) | filled Step 9 report skeleton | Same report shape every hunt |
| `tools/step10_contact_hunt.sh` | 10A | one or more official URLs | emails, Immunefi links, nearby quotes | Prove the real security inbox from docs |
| `tools/step10_dm_skeleton.py` | 10 | project/severity/chain/component/impact | filled first DM text | Consistent private first contact |
| `tools/selftest.sh` | — | none | usage/exit smoke for all tools | Catch broken tools before a hunt |

Optional static pass (when available): `slither . --filter-paths 'lib|test|script' --json slither-report.json`.
Triage every High/Medium as genuine vs false positive before writing a finding.
Do not promote a Slither High to Critical without a working PoC.

---

## STEP 1 - Ground truth (is this real, and where)

```bash
./tools/step1_ground_truth.sh "$RPC" "$CID"
```
Confirms RPC alive and chain id matches intake; prints block number.

Gate:
- RPC/chain don't resolve, or no docs/verifiable contract exist → **STOP. Likely
  vaporware/scam.** Report that to the user; do not sink hours.
- Real chain confirmed → continue.

---

## STEP 2 - Locate the core contract(s)

Frontends hide addresses in runtime config. Use these in order until you have an address:

**A. Trace a live token/position → its creator (most reliable).**
```bash
# get a token addr from the app (a /tokens/0x... or /coin/0x... link, or the app's RPC calls)
./tools/step2_creator_trace.sh "$BS" "0x<token>"
```
Prints `creator_address_hash` — usually the factory/core.

**B. Grep the app bundle** (Vite: one `/assets/index-*.js`; Next: `/_next/static/chunks/*.js`):
```bash
./tools/step2_bundle_grep.sh "<WEBSITE>"
```
Fetches HTML + JS assets and greps for role-labeled contract addresses.

**C. Browser** (when config is fetched at runtime): load the app, read the network
requests, and pull the `to` addresses from the `eth_call`s; those are the contracts.

**D. Explorer**: search the chain's Blockscout for the token/contract names
(`qUSD`, `VaultManager`, project name).

**E. GitHub search**: use `gh search` to find official repos, contract deployments, 
documentation, or security contacts:
```bash
# Search for repos by project name
gh search repos "hood.fun" --language solidity

# Search code for contract addresses or deployment scripts
gh search code "0xCONTRACT_ADDR" --language solidity

# Find security policies or contact info
gh search code "SECURITY.md" user:projectname
gh search code "security@" user:projectname

# Search issues/discussions for bug reports or disclosures
gh search issues "vulnerability security" repo:projectname/repo
```

---

## STEP 3 - Verification gate + surface map

```bash
./tools/step3_surface_map.sh "$RPC" "$CID" "0x<core>" "$BS"
```
Prints balance + code size; writes `src.json` (Sourcify) and `code.hex`; if unverified,
maps PUSH4 selectors and top tx-history selectors.

Gate:
- **Verified** → pull the source files from `src.json` and read them (30-min path).
- **Unverified** → use the script's selector map (bytecode + tx history) and continue to Step 3.5.
- **Source-only / pre-deploy** (repo audit, no mainnet address yet) → treat repo as
  scope; still run local unit PoCs; note pre-launch in the report Status line.

After inventory: set **Y** (total relevant production files) in `coverage.md` and list
exclusions. Update coverage as each source file is read.

---

## STEP 3.5 - Bytecode analysis for unverified contracts (when Step 3 finds no source)

When contracts are unverified and Sourcify returns no match, use bytecode analysis
tools to extract function signatures, identify external calls, and search for critical
patterns. This does NOT replace source code review but allows hypothesis-driven
investigation.

### Tools to install/use (in order of preference)

**Install these tools when you encounter unverified contracts:**

```bash
# GitHub CLI (for discovery and contact hunting)
# Linux/WSL:
sudo apt install gh
# or macOS:
brew install gh

# Heimdall decompiler (Rust-based, generates pseudo-Solidity)
cargo install heimdall-rs

# Mythril (symbolic execution and vulnerability scanner)
pip3 install mythril

# Optional but useful
pip3 install slither-analyzer
npm install -g @ethereum-sourcify/cli
```

**Check if tools are already installed before installing:**
```bash
command -v gh >/dev/null 2>&1 || { echo "Installing gh..."; sudo apt install gh -y; }
command -v heimdall >/dev/null 2>&1 || { echo "Installing heimdall..."; cargo install heimdall-rs; }
command -v myth >/dev/null 2>&1 || { echo "Installing mythril..."; pip3 install mythril; }
```

**Bytecode analysis tool preference order:**

1. **cast disassemble** (already available with Foundry)
   - Built-in, no installation needed
   - Basic disassembly and selector extraction
   
2. **Heimdall decompiler** (install with cargo)
   - Generates pseudo-Solidity from bytecode
   - Identifies function signatures and control flow
   - Usage: `heimdall decompile --rpc-url $RPC <contract_address>`
   
3. **Mythril** (install with pip3)
   - Symbolic execution engine
   - Finds common vulnerabilities
   - Usage: `myth analyze -a <contract_address> --rpc $RPC`
   
4. **Foundry fork tests** (already available)
   - Test actual behavior on mainnet fork
   - Verify assumptions about contract logic
   
5. **Online decompilers** (when available)
   - Dedaub (https://library.dedaub.com/decompile)
   - Panoramix/Ethervm (if accessible)
   - Request source from team via official channels

**When to install which tool:**
- **Unverified contracts** → Install Heimdall and Mythril immediately
- **Need security scanning** → Install Slither and Mythril
- **Discovery and contacts** → Install gh CLI
- **Sourcify verification** → Install @ethereum-sourcify/cli

### Bytecode analysis script

Use or adapt this script (save as `tools/analyze-bytecode.sh`):

```bash
#!/bin/bash
# Bytecode Analysis Script for Unverified Contracts
CONTRACT=$1
RPC=$2
OUTPUT_DIR=${3:-"bytecode-analysis"}

mkdir -p "$OUTPUT_DIR"

echo "=== Analyzing contract $CONTRACT ==="

# 1. Get bytecode
cast code "$CONTRACT" --rpc-url "$RPC" > "$OUTPUT_DIR/bytecode.bin"

# 2. Disassemble
cast disassemble $(cat "$OUTPUT_DIR/bytecode.bin") > "$OUTPUT_DIR/disasm.txt" 2>&1

# 3. Extract function selectors
grep -E "PUSH4 0x[0-9a-f]{8}" "$OUTPUT_DIR/disasm.txt" | \
  sed -E 's/.*PUSH4 (0x[0-9a-f]{8}).*/\1/' | \
  sort -u > "$OUTPUT_DIR/selectors.txt"

# 4. Decode known selectors
while read selector; do
    sig=$(cast 4byte-decode "$selector" 2>/dev/null | head -1)
    if [ -n "$sig" ]; then
        echo "$selector $sig"
    else
        echo "$selector UNKNOWN"
    fi
done < "$OUTPUT_DIR/selectors.txt" > "$OUTPUT_DIR/functions.txt"

# 5. Search for critical patterns
{
    echo "=== CREATE/CREATE2 (contract deployment) ==="
    grep -nE "^[0-9a-f]+: (CREATE|CREATE2)$" "$OUTPUT_DIR/disasm.txt"
    echo ""
    echo "=== External CALL instructions ==="
    grep -nE "^[0-9a-f]+: (CALL|STATICCALL|DELEGATECALL)$" "$OUTPUT_DIR/disasm.txt" | head -20
    echo ""
    echo "=== Storage Writes ==="
    grep -cE "^[0-9a-f]+: SSTORE$" "$OUTPUT_DIR/disasm.txt"
} > "$OUTPUT_DIR/patterns.txt"

echo "✓ Analysis complete! Results in $OUTPUT_DIR/"
```

### What to extract from bytecode

1. **Function selectors** - PUSH4 opcodes near function dispatcher
2. **External calls** - CALL/STATICCALL/DELEGATECALL opcodes
3. **Contract creation** - CREATE/CREATE2 opcodes
4. **Storage writes** - SSTORE opcodes (track state changes)
5. **Critical patterns** - Known vulnerability signatures

### Bytecode analysis workflow for unverified contracts

**Step 1: Install necessary tools (if not already installed)**
```bash
# Check and install decompilers
command -v heimdall >/dev/null 2>&1 || cargo install heimdall-rs
command -v myth >/dev/null 2>&1 || pip3 install mythril
```

**Step 2: Run bytecode analysis**
```bash
# 1. Run the bytecode analysis script
./tools/analyze-bytecode.sh "$CONTRACT" "$RPC" hunt-dir/bytecode-analysis

# 2. Decompile with Heimdall (generates pseudo-Solidity)
heimdall decompile --rpc-url "$RPC" "$CONTRACT" -o hunt-dir/heimdall-output

# 3. Run Mythril security scan
myth analyze -a "$CONTRACT" --rpc "$RPC" --max-depth 12 > hunt-dir/mythril-report.txt
```

**Step 3: Review function list**
```bash
# 2. Review function list
cat hunt-dir/bytecode-analysis/functions.txt
# Look for: admin functions, token creation, pool initialization, critical transfers

# 3. Check patterns
cat hunt-dir/bytecode-analysis/patterns.txt
# Look for: CREATE2 (token deployment), CALL instructions (external interactions)

# 4. Review Heimdall pseudo-Solidity output
cat hunt-dir/heimdall-output/*.sol
# Look for: function logic, state variables, external calls

# 5. Review Mythril findings
cat hunt-dir/mythril-report.txt
# Triage: genuine issues vs false positives
```

**Step 4: Search for specific patterns**
```bash
# 4. Search disassembly for specific patterns
# Example: Uniswap v3 createPool selector 0xa1671295
grep -i "a1671295" hunt-dir/bytecode-analysis/disasm.txt

# 5. Get context around critical operations
# Example: context around CREATE2
grep -B 30 -A 30 "CREATE2$" hunt-dir/bytecode-analysis/disasm.txt
```

**Step 5: Create Foundry fork tests to verify behavior**
```bash
# 6. Create Foundry fork tests to verify behavior
# Test actual on-chain behavior instead of guessing from bytecode
```

### Foundry fork testing for verification

When bytecode analysis isn't enough, write fork tests to verify behavior:

```solidity
// test/BytecodeVerification.t.sol
pragma solidity ^0.8.0;
import {Test} from "forge-std/Test.sol";

interface ITarget {
    function unknownFunction0x19e4e914(...) external;
}

contract BytecodeVerificationTest is Test {
    function setUp() public {
        vm.createSelectFork(RPC_URL);
    }
    
    function test_VerifyPoolCreationBehavior() public {
        // Call the contract and observe behavior
        // Check return values, emitted events, state changes
    }
}
```

### Coverage tracking for bytecode analysis

Update `coverage.md` to reflect bytecode-only analysis:

```markdown
Coverage: 0/4 contracts (0% source code access).

**Contracts analyzed via bytecode:**
| Contract | Address | Functions | Analysis Method | Confidence |
|----------|---------|-----------|-----------------|------------|
| Launchpad V6 | 0x66...c16 | 85 selectors | Disassembly + fork tests | Medium |
| Hook V6 | 0x143...a88 | Unknown | Selector extraction only | Low |

**Analysis performed:**
- ✅ Function selector extraction
- ✅ External call identification  
- ✅ CREATE2 deployment found
- ✅ Fork testing (3 passing tests)
- ❌ Source code logic verification

**Confidence level:** MEDIUM (bytecode + fork testing without source)
```

### Reporting unverified findings

When reporting vulnerabilities found via bytecode analysis:

1. **State the limitation clearly:**
   ```
   Status: ⚠️ UNVERIFIED (contracts not verified on explorer)
   Evidence: HIGH (documentation + bytecode analysis + known pattern)
   Confidence: 60% (cannot confirm internal logic without source code)
   ```

2. **Document what you verified:**
   - ✅ External call patterns
   - ✅ Function signatures extracted
   - ✅ Fork test behavior
   - ❌ Internal logic flow

3. **Request source code in disclosure:**
   ```
   I identified a potential CRITICAL vulnerability via bytecode analysis and fork
   testing. To verify and help fix this, I need access to the source code. Can you
   verify the contracts on the block explorer or provide source for security review?
   ```

### When bytecode analysis is insufficient

If after Steps 3.5 and 4 you cannot make progress:

1. **Install and use advanced decompilers:**
   ```bash
   # Try Heimdall if not already used
   heimdall decompile --rpc-url "$RPC" "$CONTRACT" -o decompiled/
   
   # Try Mythril for vulnerability patterns
   myth analyze -a "$CONTRACT" --rpc "$RPC"
   ```

2. **Contact the team** for source code (Step 10A channels)

3. **Use online decompilers** (Dedaub, if available)

4. **Document the blocker** in coverage.md and report

5. **Consider pivoting** to a different target with verified contracts

**Key principle:** Bytecode analysis allows pattern matching and hypothesis testing,
but NEVER claim definitive findings without source code verification. State confidence
levels honestly.

---

## STEP 4 - Auth triage (find the free win first)

`eth_call` every state-changing admin/keeper function from an attacker address. If
it does NOT revert, the access control is missing = likely Critical.
```bash
./tools/step4_auth_triage.sh "$RPC" "0x<core>"
# optional extra signatures from Step 3 surface map:
# ./tools/step4_auth_triage.sh "$RPC" "0x<core>" "setMigrator(address)" "distribute(address[],uint256[])"
```
Probes default admin/keeper sigs from `0x…dEaD`; prints `guarded` or `OPEN <-- CHECK`.

Also list every `onlyOwner` / `onlyAgent` / role gate from source. Confirm siblings
of guarded functions are not missing the same modifier (classic free win).

---

## STEP 5 - Foundation map (before deep findings)

Before writing findings, map the system. Keep this short; store in hunt notes.

### 5A. State who-writes

For each storage variable: who can change it (owner / agent / public / internal)?

### 5B. External call order

For each value path, list checks → effects → interactions. Flag CEI inversions
and any external call inside a loop.

### 5C. Token paths (entry → exit)

Draw cash flow: user → vault/pool → adapter/venue → back. Note any path to an
arbitrary EOA (agent, owner, stranger).

### 5D. Access control gates

Table: function → modifier / require → pausable?

### 5E. Structured first-pass checklist

For each item return **PASS / FAIL / UNCLEAR** with one sentence:

- [ ] Reentrancy / CEI on all fund paths
- [ ] Access control on privileged state changers
- [ ] Oracle / pricing freshness (or explicit face-value assumptions)
- [ ] Slippage on DEX interactions
- [ ] Frontrun / sandwich surface on agent or public swaps
- [ ] Init / proxy (uninitialized implementation?)
- [ ] Upgrade storage safety (if upgradeable)
- [ ] Pause semantics (what still works while paused?)
- [ ] Events on policy / risk parameter changes

---

## STEP 5.5 - Multi-angle adversarial pass (complex logic)

After the foundation map, force interaction bugs with **role-based angles**. Run on
**one chunk at a time** (e.g. only redeem + totalAssets; only allocate + budgets;
only one adapter). Do not dump the whole codebase into one prompt.

### Angle 1 — Malicious actor (payout)

- Walk three hypothetical drain paths focused on deposit/withdraw/redeem/allocate.
- How would you **permanently lock** funds or freeze exits (DoS)?
- If Admin/Owner is compromised, what is max damage, and what cannot be bypassed?

### Angle 2 — Economic and math

- Rounding, precision, fee, reward, share conversion: free mint or leak?
- Flash loan / temporary balance inflation: how does `totalAssets` / NAV react?
- Can **internal books** desync from **actual token balances** or venue face value?

### Angle 3 — State and access

- Every state writer: missing modifier?
- External calls: state before or after? Cross-function reentrancy under one lock?
- Re-init / proxy hijack?

### Angle 4 — Edges

- Unbounded arrays / loops vs block gas?
- `block.timestamp` advantage on epochs / auctions?
- Overflow/underflow on balances or time locks (note 0.8+ checked math still has
  logic skew)?

### Angle 5 — External integrations

- Uniswap / Aave / Chainlink / custom adapter: pause, revert, unexpected return?
- Weird ERC20: fee-on-transfer, rebase, no-return bool, approve race?

For each angle, record: **path attempted → blocked by X** or **confirmed with PoC**.
Killed paths are as valuable as open ones (they prevent false Criticals).
If the block leaves a Low, Medium, or High that can still be a step toward a
Critical, keep it as a chain lead and apply operating rule 15 before you drop
the path.

---

## STEP 5.6 - Dual-ledger / multi-strategy vault hunt

When PRODUCT_TYPE is `vault` or `multi-strategy-vault` (ERC-4626, strategies,
adapters, agent allocators), hunt the **three notions of value** separately:

| Ledger | Typical source | Failure mode |
|---|---|---|
| **Principal book** | `allocated`, `totalDeployed`, internal shares of strategy | Updated on call success even if cash not moved |
| **NAV / share price** | `totalAssets()`, adapter `balanceOf`, oracle | Counts unrealizable or discounted units wrong |
| **Cash returned** | `balanceOf` delta after withdraw/transfer | Silent zero return; under-delivery |

**Complex-logic questions (force these):**

1. Does `allocate` book **gross input** or **post-fee supplied** amount?
2. Does loss/churn budget compare returned cash to **gross book** (double-counting
   entry loss already taken in NAV)?
3. Does redeem isolation (`try/catch` skip stuck venue) still **price** that venue
   in `totalAssets` / `maxWithdraw`? (preferential exit / bank-run on healthy leg)
4. Is temporary depeg-then-restore actually theft, or only **persistent** stuck+face NAV?
5. Does `withdraw` returning 0 **without revert** still decrement principal?
6. Is `maxWithdraw` / `previewRedeem` overstating liquid assets?
7. Are `balanceOf` view failures try/caught in pricing but **not** in pull loops?
8. Do shared epoch lengths couple unrelated rate limits with uncoupled resets?
9. Does last-pass full liquidation (`type(uint256).max`) over-burn a lossy venue
   when a healthy venue could cover dust?

---

## STEP 6 - Read with attack questions (by PRODUCT_TYPE)

Ask a fixed list. Hunt **one wrong assumption at the one moment value moves.**
Also write down a Low, Medium, or High that is not a Critical by itself when it
can be combined into one (operating rule 15). Do not drop it only because the
single bug is below Critical. A confirmed Low, Medium, or High is reported at
that severity.

Universal: who moves the money (every path?); what happens when funds cross
contracts (migration/liquidation/distribution); can a stranger trigger it; can
someone pay less / receive more; external call before state update (reentrancy).

- **launchpad** → graduation/migration into the DEX pool; LP lock; fee split;
  anti-snipe; token transfer restrictions; single-sided vs. raise-holding model.
- **lending/CDP** → oracle (staleness, manipulation, closed-market for equities);
  liquidation math; health factor; LTV; interest; stablecoin peg.
- **vault** → first-depositor / share inflation; rounding direction; donation
  attack; deposit/withdraw accounting; virtual shares offset.
- **multi-strategy-vault** → all vault items, plus dual-ledger (Step 5.6);
  adapter allowlist trust; agent caps vs unmetered user redeem; realizability
  of strategy `balanceOf`; loss/deploy budgets; pause leaves redeem open or not.
- **perps** → is it its own engine or a wrapper (wrapper = smaller surface);
  oracle; funding; liquidation; margin accounting.
- **distribution/index** → snapshot weighting; permissionless crank; flash-inflatable
  balance; claim reentrancy; does it even custody funds (no custody = weak target).

---

## STEP 6.5 - Bug-class detection playbook

Each = the pattern, the detection, the fix.

1. **Migration pool squat (v3).** Graduation calls
   `createAndInitializePoolIfNecessary` and mints with `amount0Min/amount1Min = 0`
   and NO post-init price check. → anyone pre-creates the pool at a fake price
   (needs zero tokens), migration dumps the raise into it. *Detect:* grep for
   `createAndInitializePoolIfNecessary` + missing `slot0()` price check; confirm
   `getPool(token,weth,fee)==0` on a live token. *Dead if* single-sided
   instant-listing (no raise held). *Fix:* read `slot0()`, revert on price mismatch.
2. **Permissionless flash-inflated snapshot (distributions).** Weight = spot
   `balanceOf` at a permissionless snapshot, frozen once captured; token transfers
   fee-free → flash-borrow, get snapshotted, return, still collect. *Detect:*
   snapshot has no access modifier + reads live `balanceOf`; find a fee-free flash
   source (v4 pool `take`/`settle`). Capture ≈ `flashable/(eligible+flashable)`.
   *Fix:* time-weighted/checkpointed balances or Merkle snapshot.
3. **Push-payment DoS.** Handoff/claim pushes ETH to an address that can reject it.
   *Fix:* pull-pattern.
4. **Oracle staleness / closed-market.** Equity collateral prices go stale
   nights/weekends; no buffer-widen/halt → wrong-price borrow/liquidation.
5. **Keeper-trusted fund movement.** `distribute(holders,amounts)` only checks
   `total<=balance` → compromised keeper drains to any address. *Fix:* verify
   amounts on-chain / multisig.
6. **Owner backdoor on live positions.** Admin can swap migrator/oracle/fee on
   already-live positions ("trust owner" not "trust code"). *Fix:* timelock or
   per-position snapshot/freeze.
7. **First-depositor / share inflation (vaults).** Tiny deposit + direct donation
   inflates share price; next depositor rounds to 0 shares. *Fix:* virtual
   shares/dead shares (`_decimalsOffset` or dead mint).
8. **Unrealizable NAV + preferential exit (multi-strategy vaults).** Strategy
   still counted in `totalAssets` while `withdraw` reverts; redeem isolation
   skips it and pays from healthy venues. *Detect:* try/catch on withdraw without
   zeroing NAV; `maxWithdraw` >> liquid. *Kill if* only temporary manip that
   restores. *Fix:* realizability-aware NAV, honest maxWithdraw, pro-rata venue exits.
9. **Gross book vs post-entry supplied.** `allocated += amount` but adapter returns
   less after swap/fee; loss budgets re-charge entry on exit; agent freeze.
   *Fix:* book `supplied`; meter loss vs marked basis.
10. **Phantom zero-return withdraw.** Effects decrement principal; external
    withdraw returns 0 without revert; caps free while face remains. *Fix:* revert
    or restore principal if `returned == 0`.
11. **View/pull asymmetry.** Pricing try/catches `balanceOf`; pull loop does not →
    one bad view bricks all redemptions needing liquidity.
12. **Compromised agent without external send.** Agent cannot send to self but can
    churn lossy venues / socialize via unmetered redeem if deploy budget is off
    (`maxEpochDeploy == 0`). Bound with rate limits; fail-closed defaults.

Separate **owner-by-design centralization** (trust-risk, lower) from a
**permissionless exploit** (the real Critical). Never claim the former as the latter.

---

## STEP 7 - Fork-prove it (mandatory)

```bash
./tools/step7_poc_scaffold.sh "$RPC" "0x<core>" poc
```
Creates/refreshes a Foundry project, writes the SAFE local-fork-only `test/PoC.t.sol`
skeleton with `TARGET` set, and prints the exact `forge test --fork-url ...` command
(current block from RPC).

Fill `test_exploit()` with the value-moving sequence, then run the printed command:
```bash
cd poc && forge test --fork-url $RPC --fork-block-number $BLK -vv
```

Skeleton shape (already on disk after the tool runs; edit in place):
```solidity
// SAFE, read-only, LOCAL FORK ONLY. Uses test cheatcodes (vm.*) that do nothing on
// a real network, so this can never run as a live attack. No mainnet state touched.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
interface ITarget { /* add the exact fns from Step 3 */ }
contract PoC is Test {
    address constant TARGET = 0x<core>;
    address attacker = address(0xA11CE);
    function test_exploit() public {
        // 1. record victim/pot state
        // 2. vm.deal / vm.prank the attacker; execute the value-moving sequence
        // 3. assert the theft/loss in numbers:
        //    assertGt(attackerGain, attackerCost, "net profit"); // or funds stranded
    }
}
```

PoC quality bar:
- Compiles and **passes** with assertions that fail if the bug is fixed.
- Clear attacker vs victim; quantify loss or freeze.
- No synthetic sugar that an on-chain attacker cannot do (unless labeled owner/agent model).
- For multi-strategy NAV bugs: prove **persistent** stuck, and separately kill
  temporary restore sandwich if claiming Critical/High bank-run.
- If a full-scale fork is impractical: exact-logic local unit PoC + cite live
  on-chain magnitudes for bound.

---

## STEP 8 - Severity call (honest rubric)

- **Critical** - unauthenticated theft/loss of a large share of funds, or a full
  drain / freeze. One transaction (or atomic bundle), no special role; capital
  multiplies or unbounded protocol loss.
- **High** - unauthenticated, repeatable theft or preferential extraction of user
  funds but **bounded** (state the bound), or serious loss needing a common
  condition (e.g. multi-venue + stuck strategy). Soft-lock of all exits under
  realistic venue failure can be High.
- **Medium** - limited/conditional loss, griefing, ops freezes (agent cannot
  retreat), bounded value leak, asymmetric views.
- **Trust/centralization** - owner-by-design power; disclose, but not a
  permissionless exploit. Label it as such.

Write the number you can defend, with the bound stated. Do not round up.

**Chain lead (operating rule 15).** Before you close a path as not Critical,
apply that rule: write the honest severity of the piece, name the second bug,
role, state, or call that would make it Critical, and trace that piece if it
exists. A chain confirmed with a fork PoC is reported at the chain severity.
A missing piece stays as a lead line. Killed chains go in hunt notes. A
confirmed Low, Medium, or High is still reported at that severity.

**Second-opinion gate (before disclosure):**
1. Gas-feasible?
2. Access control actually blocks it?
3. State reachable in production config?
4. Mitigating code path elsewhere?
5. Temporary condition killed?
Verdict: CONFIRMED / FALSE POSITIVE / NEEDS MORE WORK.

---

## STEP 9 - Report (fill-in template)

Always use researcher name **shaydez** (never dukedotsol or other handles).
Open every report with a plain-language "What this means" section so a non-technical
reader understands the danger before any code. Do not use em dashes (the long dash
character); use commas, periods, or a normal hyphen instead.

Keep a **master findings table** for the hunt (ID, severity, status, component,
chain-to-critical) and update it when findings are killed, reclassified, or
kept as a chain lead. `chain-to-critical` is the missing or confirmed next
step, or `n/a` when the finding cannot chain. Report every confirmed Low,
Medium, and High (operating rule 15), including ones that do not chain. Use
this template at the finding's real severity. One file per finding, or one
section each in a multi-finding pack. Single-issue disclosure
files still use the template below.

**Coverage honesty in the report:** cite `coverage.md` summary (`Coverage: X/Y
(Z%)`). If Z is low or core modules were only partially traced, state that the
review is path-scoped, not a full audit. Attach or link `coverage.md` in private
multi-finding packs.

Scaffold the file from INTAKE + your Step 8 call (judgment fields you still fill by hand):
```bash
python3 ./tools/step9_report_skeleton.py \
  --project "<PROJECT_NAME>" \
  --severity "<Low/Medium/High/Critical>" \
  --title "<one-line title>" \
  --chain "<CHAIN>" \
  --chain-id "$CID" \
  --core "0x<core>" \
  --bound "<why; state the bound>" \
  --rpc "$RPC" \
  --blk "<BLK>" \
  -o "reports/<project>-<severity>.md"
```
Emits the same report skeleton as below; complete plain-language, root cause, attack,
impact, PoC result, and fix before disclosing.

```markdown
# <PROJECT> - <SEVERITY>: <one-line title>
**Researcher:** shaydez
**Severity:** <Low/Medium/High/Critical> - <why; state the bound>
**Status:** Verified on a local fork / read-only on-chain. No mainnet state touched.
**Disclosure:** Private. Live-exploitable now.  <!-- if applicable -->

## What this means in plain language (read this first)
<Explain the danger for non-technical readers: what users thought was safe, what
can go wrong, who loses money, that no admin key is needed if that is true, and
what the bound is. Use a simple analogy if helpful. No em dashes.>

## Affected contracts (<CHAIN>, chainId <CID>)
| Role | Address |
|---|---|
| <core> | 0x... |

## Summary
<the one wrong assumption, plain language>

## Root cause
<exact code quoted>

## Attack
1. ... 2. ... 3. ...

## Impact
Auth: none | Capital: <flash/zero> | Frequency: <once/every cycle> | Victims: <who> | Magnitude: <number/%>

## Proof of concept
`forge test --fork-url <RPC> --fork-block-number <BLK> -vv`  → <result: attacker gained X / Y stranded>

## Fix
<one or more concrete options>

## Disclosure & compensation
Good-faith private disclosure. I'd appreciate a bounty commensurate with a
<severity>. I am NOT conditioning the disclosure or fix on payment act on it now.
Happy to walk the team through it and review the fix.
shaydez
```

For multi-finding private packs, also ship:
- hunt notes (INTAKE, killed paths, PoC commands)
- structured checklist PASS/FAIL
- adversarial angle scoreboard (path attempted → result)
- **coverage.md** (files opened, paths traced, %, exclusions)
- **reports/contacts.md** (official inbox + source URL + quote)

---

## STEP 10 - Disclose and get paid

Run this **after** the report file exists. Disclose a confirmed Low, Medium, or
High the same way as a Critical (operating rule 15). The DM severity matches
the report. Do not hold a finding back because it is not Critical. Write the
first DM as a separate file
(e.g. `reports/dm-<project>.md`). Do not put full exploit steps in the first DM.

### 10A. Official contacts (mandatory every hunt)

Do not guess `security@` or DM the first @handle Google returns. Build a
`reports/contacts.md` with **URL + exact quote** for every inbox you will use.
An email without a cited official page is not a contact.

Hunt in this order until you have a **bug-report** inbox (security@ / Immunefi /
HackerOne beats a generic contact@):

1. Official docs FAQ / "security" / "bug bounty" / "contact" pages
   (`docs.*`, `help.*`, GitHub `docs/`, GitBook `.md` URLs).
2. `SECURITY.md`, `security.txt` (`/.well-known/security.txt`), Immunefi /
   HackerOne / Cantina / Code4rena program page for this project (not a
   lookalike).
3. Official forum / governance post **by a founder or staff account** that
   names a report address. Prefer `.json` API if the HTML hides emails
   behind Cloudflare (`data-cfemail`).
4. Official GitHub org **People** + matching verified X bios. Founders are
   backup DMs, not the first inbox.
5. **GitHub search methods** - use `gh search` to find security contacts:
   ```bash
   # Search for SECURITY.md files
   gh search code "filename:SECURITY.md" org:projectname
   
   # Search for security email addresses in code/docs
   gh search code "security@" org:projectname --language markdown
   
   # Find bug bounty mentions
   gh search code "bug bounty OR bounty program" org:projectname
   
   # Search commit messages for security contact updates
   gh search commits "security contact" repo:projectname/repo
   ```

Then verify socials:

- Official X: verified org/account whose bio links the **same** website as
  INTAKE. Reject lookalikes (one-letter typos, extra `l`/`o`, copied logo).
- Discord / Telegram: only the invite printed on official docs. FAQ "we have
  no Telegram" means any TG group is a scam.
- Never describe a live bug in a public forum, Discord, tweet, or GitHub issue.

```bash
./tools/step10_contact_hunt.sh "<DOCS_FAQ_URL>" "<WEBSITE>" "<FORUM_OR_SECURITY_MD>"
# write reports/contacts.md from the hits: Role | Address | Source URL | Quote
```

Show the user the **links and quotes** before sending. Prefer `security@` (or
the bounty platform) for the report; `contact@` is general and may be CC only.

Gate: no cited official inbox and no verified org X -> **do not send**. Tell
the user what you searched and what is missing.

1. **Use the inbox from 10A.** Never a public thread while it's live.
2. **First message (short):** use the template below. Who you are, plain impact,
   severity + bound, verified how, nothing touched, offer full report + PoC privately.
3. **Share via a PRIVATE repo** (add them as collaborator) or attach files. Never
   public until patched.
   ```bash
   gh repo create <project>-security-disclosure --private --source=. --push   # confirm the RIGHT account first: gh api user --jq .login
   ```
4. **Skepticism is normal.** Point to the reproducible PoC: "run it yourself." Stay
   calm, don't threaten.
5. **Name the number AFTER they confirm.** Anchor on merit (severity + funds at risk
   + clean disclosure + you helped fix). No program = discretionary; plan a fair range.
6. **Help them fix it and review the patch.** This turns one bounty into repeat work.
7. **If they don't pay:** you still won a portfolio piece. After the fix ships, a
   factual timeline post (receipts, no rage, no threats) builds your name. Never
   bundle "pay or I post".

### First DM template (fill after the report; save separately)

Researcher voice: **Shaydez** (<SHAYDEZ_PROFILE_URL>). Also sign reports as **shaydez** / Shaydez.
No em dashes. Short first message. No full attack runbook. No threats. No "pay or I publish."
Ask who owns the contracts so you get the right inbox. Save as `reports/dm-<project>.md`.

```bash
python3 ./tools/step10_dm_skeleton.py \
  --project "<PROJECT_NAME>" \
  --severity "<SEVERITY>" \
  --chain "<CHAIN>" \
  --component "<one-line component / flow, e.g. graduation flow>" \
  --impact "<one plain sentence: what an attacker can do to user funds>" \
  --scope "<scope, e.g. every un-graduated token>" \
  -o "reports/dm-<project>.md"
```

Filled shape:
```text
Hey <PROJECT_NAME or short product name>.

I'm Shaydez, a security researcher. (<SHAYDEZ_PROFILE_URL>)

I've found and verified a <SEVERITY> vulnerability in <PROJECT_NAME>'s <one-line component / flow, e.g. graduation flow> on <CHAIN> that <one plain sentence: what an attacker can do to user funds>. It's live-exploitable right now on <scope, e.g. every un-graduated token>, so it's time-sensitive.

I reproduced it on a <CHAIN> mainnet fork / local Foundry PoC, nothing was touched on-chain<, with N working PoCs if true>.

I want to share the full private write-up with whoever owns the contracts.

Who's the right person, or who do I talk to on the team?
```

Fill map from the report:
- `<PROJECT_NAME>`, `<CHAIN>` from INTAKE
- `<SEVERITY>` must match the report (do not inflate Critical if the report says High)
- One-line flow + attacker outcome from the plain-language section
- Scope/bound honest (per token vs whole protocol)
- PoC method: fork and/or local Foundry; say "nothing was touched on-chain"

Optional second message (after they reply and want details): attach or link the private
report + PoC repo. Still no public post until patched.

---

## Appendix A - cheat-sheet

- `cast chain-id | block-number | code | balance | call | storage | 4byte | disassemble | tx`
- `forge test --fork-url $RPC --fork-block-number <BLK> -vv` - the PoC engine
- `anvil --fork-url $RPC --fork-block-number <BLK>` - persistent local fork (caches state)
- Sourcify verified source: `sourcify.dev/server/v2/contract/<CID>/<addr>?fields=sources`
- New chains use **Blockscout**, not Etherscan. `to`-addresses in the app's `eth_call`s = the contracts.
- Vanity CA suffix (e.g. tokens ending in a fixed 2 bytes) = a launchpad fingerprint.
- Playbook tools: see **Tools** table above and `tools/README.md`.
- Optional: `slither . --filter-paths 'lib|test|script' --json slither-report.json`
- **GitHub CLI search methods:**
  - `gh search repos "<project>" --language solidity` - find official repos
  - `gh search code "0xADDRESS" --language solidity` - locate deployment references
  - `gh search code "filename:SECURITY.md" org:<org>` - find security policies
  - `gh search code "security@ OR contact@" org:<org>` - discover contact emails
  - `gh search issues "vulnerability OR security" repo:<org>/<repo>` - past reports
  - `gh search commits "deploy OR deployment" repo:<org>/<repo>` - deployment history

## Appendix B - adversarial prompt pack (copy into subagent or self)

Use after Step 5 foundation map. One chunk + one angle per invocation.

1. Act as a malicious actor trying to drain funds. Three exploit paths on deposit/withdraw.
2. How would you permanently lock user funds or freeze exits (DoS)?
3. Assume Admin/Owner is compromised. Max damage? What safeguards remain?
4. Analyze share math, fees, rewards. Rounding or free mint?
5. Flash loan temporarily inflates a balance or price. How does the contract react?
6. Can internal accounting desync from actual token balances?
7. Every state-writing function: missing access control?
8. Reentrancy: external calls and whether state updates are before or after.
9. Re-init or proxy hijack possible?
10. Unbounded loops / gas grief?
11. Timestamp manipulation advantage?
12. External protocol pause/fail/unexpected data?
13. Weird ERC20 (FoT, rebase, no bool return)?
14. Which Low, Medium, or High is not a Critical alone, but is a step on a path
    to one? Name the missing piece (operating rule 15).

## Appendix C - hunt session hygiene

- Keep private: INTAKE fills, addresses, draft reports/DMs, live PoCs until patched.
- Master findings table stays updated when severity changes.
- Killed Critical candidates and killed chain leads listed in hunt notes
  (prevents re-opening bad claims).
- Open Low, Medium, and High chain leads stay on the master findings table at
  their real severity (operating rule 15).
- Prefer local exact-logic unit tests for accounting bugs; use fork for live magnitude.
- **coverage.md** updated incrementally; low Z% stated openly; exclusions listed with reasons.
- **reports/contacts.md** before any DM: official inbox, source URL, exact quote.

**Reminder:** fork only, honest severity, keep Low / Medium / High chain leads
and report every confirmed Low, Medium, and High (operating rule 15), ask
don't threaten, kill your own bad findings, private until patched, stay
token-conservative and route mechanical work to smaller models. Map first,
multi-angle second, dual-ledger on vaults,
PoC before Critical, **track coverage so thoroughness is real**. That discipline
is the job.

shaydez

---

## STEP 11 - Frontend Security Audit (always check)

**Run this step for every bug hunt, regardless of product type.** Frontend vulnerabilities can be as critical as smart contract bugs, especially unauthenticated server/database access and exposed API keys that control gas sponsorship or authentication.

### 11A. Bundle Analysis - Extract Frontend Secrets

Modern web apps bundle JavaScript into `/assets/*.js` or `/_next/static/chunks/*.js`. These files often contain hardcoded secrets that should never be client-side.

**Create and run the frontend analysis script:**

```bash
# Save as tools/step11_frontend_security.sh
cat > tools/step11_frontend_security.sh << 'SCRIPT'
#!/bin/bash
# Frontend Security Scanner
WEBSITE=$1
OUTPUT_DIR=${2:-"frontend-security"}

mkdir -p "$OUTPUT_DIR"

echo "=== Frontend Security Analysis for $WEBSITE ==="

# 1. Fetch main page
echo "[1] Fetching main page..."
curl -s "$WEBSITE" -H "User-Agent: Mozilla/5.0" -o "$OUTPUT_DIR/index.html"

# 2. Extract JavaScript files
echo "[2] Extracting JavaScript files..."
grep -oP 'src="[^"]*\.js[^"]*"' "$OUTPUT_DIR/index.html" | \
  sed 's/src="//g' | sed 's/"//g' | sort -u > "$OUTPUT_DIR/js_files.txt"

echo "Found $(wc -l < "$OUTPUT_DIR/js_files.txt") JavaScript files"

# 3. Download largest bundle (usually the main app)
MAIN_JS=$(head -1 "$OUTPUT_DIR/js_files.txt")
if [[ $MAIN_JS == /* ]]; then
    MAIN_JS="${WEBSITE}${MAIN_JS}"
elif [[ $MAIN_JS != http* ]]; then
    MAIN_JS="${WEBSITE}/${MAIN_JS}"
fi

echo "[3] Downloading main bundle: $MAIN_JS"
curl -s "$MAIN_JS" -o "$OUTPUT_DIR/bundle.js"

# 4. Search for exposed credentials
echo ""
echo "=== CRITICAL: API Keys & Tokens ==="
grep -oiE '(api[_-]?key|apikey|secret[_-]?key|access[_-]?token)["\s:=]+[a-zA-Z0-9_-]{20,}' "$OUTPUT_DIR/bundle.js" | head -20

echo ""
echo "=== Bearer Tokens ==="
grep -oiE '(bearer|authorization)[":\s]+(bearer\s+)?[a-zA-Z0-9_-]{20,}' "$OUTPUT_DIR/bundle.js" | head -10

# 5. Extract contract addresses
echo ""
echo "=== Contract Addresses (non-zero) ==="
grep -oiE '0x[a-fA-F0-9]{40}' "$OUTPUT_DIR/bundle.js" | \
  grep -v "^0x0000000000000000000000000000000000000" | \
  sort -u | head -20 > "$OUTPUT_DIR/contract_addresses.txt"
echo "Found $(wc -l < "$OUTPUT_DIR/contract_addresses.txt") unique addresses"

# 6. RPC endpoints with keys
echo ""
echo "=== RPC Endpoints (check for embedded keys) ==="
grep -oiE 'https?://[^"'\'']+\.(infura|alchemy|quicknode|ankr)\.[^"'\'']+' "$OUTPUT_DIR/bundle.js" | \
  sort -u

# 7. API endpoints
echo ""
echo "=== API Endpoints ==="
grep -oiE 'https?://[a-zA-Z0-9.-]+/(api|v1|v2|graphql)[^"'\'']*' "$OUTPUT_DIR/bundle.js" | \
  sort -u | head -20

# 8. WebSocket endpoints
echo ""
echo "=== WebSocket Endpoints ==="
grep -oiE 'wss?://[^"'\'']+' "$OUTPUT_DIR/bundle.js" | sort -u

# 9. Database connection strings
echo ""
echo "=== Database/Private Data Exposure ==="
grep -iE '(mongodb|postgres|mysql|redis|connection.*string)' "$OUTPUT_DIR/bundle.js" | wc -l
echo "Found potential database references"

# 10. localStorage/sessionStorage (private data leakage)
echo ""
echo "=== Local Storage Keys ==="
grep -oE 'localStorage\.(get|set)Item\([^)]+\)' "$OUTPUT_DIR/bundle.js" | \
  sort -u | head -20

# 11. Authentication patterns
echo ""
echo "=== Authentication Patterns ==="
grep -oiE '(jwt|session|auth|token)[^,;]{0,50}' "$OUTPUT_DIR/bundle.js" | head -10

echo ""
echo "=== Analysis complete. Results in $OUTPUT_DIR/ ==="
echo "Review bundle.js for hardcoded secrets and credentials."
SCRIPT

chmod +x tools/step11_frontend_security.sh
```

**Run the analysis:**
```bash
./tools/step11_frontend_security.sh "$WEBSITE" hunt-dir/frontend-security
```

### 11B. Critical Patterns to Check

For each finding, assess severity and impact:

**🔴 CRITICAL Findings:**
1. **Gas sponsorship keys** (Pimlico, Gelato, etc.)
   - Search: `pim_`, `pimlico`, `gelato`, `paymaster`, `sponsor`
   - Impact: Direct financial drain (gas costs charged to project)
   - Action: Rotate immediately, estimate potential loss

2. **Bearer authentication tokens**
   - Search: `Authorization.*Bearer`, hardcoded 32+ char hex strings
   - Impact: Authentication bypass, impersonation
   - Action: Rotate token, audit backend for unauthorized access

3. **Database credentials**
   - Search: `mongodb://`, `postgres://`, connection strings, API keys to database services
   - Impact: Direct database access, data breach
   - Action: Rotate all credentials, check for data exfiltration

4. **Admin API keys**
   - Search: `admin`, `secret`, `master`, service-specific patterns
   - Impact: Privileged access, service abuse
   - Action: Rotate and move to backend

**🟠 HIGH Findings:**
5. **RPC endpoint keys** (Alchemy, Infura, QuickNode)
   - Pattern: `https://.*alchemy.com/v2/KEY` or `/v3/KEY`
   - Impact: Rate limit exhaustion, monitoring, cost
   - Mitigation: Check if origin whitelisting is enabled

6. **Third-party API keys** (CoinGecko, TheGraph, etc.)
   - Impact: Service abuse, rate limiting, unexpected bills
   - Action: Move to backend proxy with rate limiting

**🟡 MEDIUM Findings:**
7. **Private user data in localStorage**
   - Check: What's being stored unencrypted
   - Impact: XSS attacks can steal sensitive data
   - Action: Encrypt sensitive data, use httpOnly cookies

8. **Internal API endpoints exposed**
   - Pattern: `/internal/`, `/admin/`, `/debug/`
   - Impact: Information disclosure, potential unauthorized access
   - Action: Verify authentication requirements

9. **WebSocket endpoints**
   - Check: Oracle feeds, real-time data sources
   - Impact: Front-running, competitive intelligence
   - Action: Consider if direct client connection is necessary

### 11C. Account Abstraction Services

**Pimlico / Gelato / Biconomy (ERC-4337):**

If you find keys for account abstraction services:

```bash
# Check what features are used
grep -i "pimlico\|gelato\|biconomy" hunt-dir/frontend-security/bundle.js | \
  grep -oE "(bundler|paymaster|sponsor|userOp)" | sort -u
```

**Critical questions:**
1. Is gas sponsorship enabled? (check for `paymaster`, `sponsor`)
2. What's the potential financial impact? (gas costs × expected usage)
3. Are there spending limits configured?
4. Can this be automated to drain the budget?

**Financial impact calculation:**
```
Estimated Loss = (Operations per day × Gas cost per op × Days until detected)
Example: 10,000 ops × $0.50 × 7 days = $35,000
```

### 11D. Testing Exposed Credentials

**Only test with user approval and document results:**

```bash
# Test if RPC key works (check error message)
curl -X POST "https://eth-mainnet.g.alchemy.com/v2/EXPOSED_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Expected responses:
# - "Unspecified origin not on whitelist" = Good (protected)
# - Valid block number = Bad (key works from anywhere)
# - "Invalid API key" = Already rotated
```

**Document test results in findings:**
- ✅ Tested and protected by origin whitelist (still should be backend)
- ⚠️ Tested and works without restrictions (CRITICAL)
- ℹ️ Not tested (would require service account)

### 11E. Reporting Frontend Vulnerabilities

**Update severity assessment:**

Frontend findings can be CRITICAL when they enable:
1. Direct financial loss (gas sponsorship drain)
2. Authentication bypass (bearer tokens)
3. Database access (connection strings)
4. Mass user data breach (admin keys)

**Report structure for frontend findings:**

```markdown
# <PROJECT> - CRITICAL: Exposed <Service> API Key Enables Financial Drain

**Researcher:** shaydez
**Severity:** CRITICAL - $X,000-$Y,000 potential loss
**Component:** Frontend bundle (`/assets/index-*.js`)
**Status:** Publicly accessible, live exploitable

## What this means in plain language

The project's <Service> API key is hardcoded in publicly accessible JavaScript.
Anyone can extract it and <specific impact>. This could cost the project 
$X,000-$Y,000 if exploited.

## Affected components
- **Frontend bundle:** https://<website>/assets/index-<hash>.js
- **Exposed credential:** `<KEY_PREFIX>...<KEY_SUFFIX>`
- **Service:** <Service Name> (<what it controls>)

## Root cause
API keys are embedded in client-side JavaScript instead of being protected
server-side. The key appears at line <N> in the bundle.

## Attack scenario
1. Attacker views page source or inspects network requests
2. Extracts API key from JavaScript bundle (trivial, no tools needed)
3. Uses key to <specific attack>
4. Project incurs costs or service disruption

## Impact
- **Auth required:** None (public website)
- **Financial impact:** $X-Y estimated (see calculation)
- **Exploitation difficulty:** Trivial (view-source)
- **Scope:** All users, entire service budget

## Proof of concept
```bash
# Extract key
curl -s https://<website>/assets/index-<hash>.js | grep -o "<pattern>"

# [OPTIONAL: Test key with approval]
# Result: <response showing it works or is protected>
```

## Fix
1. **Immediate (< 1 hour):**
   - Rotate the exposed key at <service dashboard URL>
   - Check usage logs for unauthorized activity
   - Set up spending alerts

2. **Permanent (this week):**
   - Move API calls to backend proxy
   - Store keys in environment variables (server-side only)
   - Implement per-user rate limiting
   - Add request authentication

3. **Architecture:**
   ```
   Before: Browser → Service API (exposed key)
   After:  Browser → Your Backend → Service API (key in secrets)
   ```

## Additional findings
[List other exposed credentials found in same bundle]

## References
- Frontend bundle: <URL>
- Service pricing: <URL to understand costs>
- Service documentation: <URL>
```

### 11F. Update Coverage Tracking

Add frontend security to coverage.md:

```markdown
## Frontend Security Analysis

| Component | Analyzed | Findings | Severity |
|-----------|----------|----------|----------|
| JavaScript bundles | yes | 5 exposed keys | CRITICAL |
| API endpoints | yes | 2 internal paths | MEDIUM |
| localStorage usage | yes | No PII stored | PASS |
| WebSocket endpoints | yes | Oracle feeds exposed | LOW |

**Frontend security grade:** F (critical issues found)
```

### 11G. Tools Table Update

Add to the main Tools table:

| Script | Step | Inputs | Outputs / gates | Why this exists |
|---|---|---|---|---|
| `tools/step11_frontend_security.sh` | 11 | `<WEBSITE> [OUTPUT_DIR]` | API keys, tokens, RPC endpoints, addresses | Catch hardcoded secrets in frontend |

### 11H. When to Run Frontend Analysis

**Always run Step 11 when:**
- Target has a web frontend (most DeFi projects)
- User asks to "check frontend" or "data leakage"
- Looking for quick wins before deep contract analysis
- Contract addresses are hard to find (frontend config)

**Run before or in parallel with contract analysis:**
- Step 2 (locate contracts) can use frontend findings
- Frontend keys might indicate centralization risks
- Exposed admin keys affect threat model

### 11I. Frontend Findings Checklist

Before finalizing the report:

- [ ] All exposed credentials documented with severity
- [ ] Financial impact calculated for gas sponsorship keys
- [ ] Testing results documented (what works, what's protected)
- [ ] Architecture recommendations provided
- [ ] Immediate and long-term fixes specified
- [ ] Cost-benefit analysis included
- [ ] Other projects notified if using same vulnerability pattern

---


### 11J. Unauthenticated server / database access (primary frontend hunt goal)

**When hunting a frontend, exposed secrets are one path. The other — and often
higher-impact — path is unauthenticated (or under-authenticated) access to the
project's backend, APIs, or database.** Treat this as a first-class objective of
Step 11, not an afterthought.

You are looking for ways a stranger (no session, no wallet signature, no admin
cookie) can:

1. **Read or write the database** — open Firebase / Supabase / Appwrite / Hasura
   rules, leaked service-role keys, GraphQL that accepts mutations without auth,
   REST that creates / updates / deletes rows without a check.
2. **Call privileged server endpoints** — `/admin`, `/internal`, `/debug`,
   webhooks with no shared-secret, unsigned cloud-function URLs, open CORS +
   cookie-less state-changing POSTs.
3. **Bypass auth on user actions** — IDOR (change `userId` / `wallet` in the
   request and hit another account), missing ownership checks on update/delete,
   unsigned "claim" / "payout" / "credit" APIs that trust a client-supplied
   address.
4. **Abuse storage / queues** — public S3 / GCS / R2 buckets writable by anyone,
   open Redis / Mongo endpoints, message queues that accept unauthenticated
   publish.
5. **Chain a frontend secret into server access** — a leaked Bearer / service key
   that unlocks (1)–(4). Rate-limit-only keys are usually Low; keys that mutate
   production data are High/Critical.

**How to hunt (read-only / non-destructive first):**
- From the bundle, list every API base URL, GraphQL endpoint, Firebase config,
  Supabase URL + `anon` / `service_role` key, and webhook path.
- For each write-shaped endpoint (`POST`/`PUT`/`PATCH`/`DELETE`, GraphQL
  mutation, Firebase `.set` / `.update`, Supabase `.insert` / `.upsert`):
  try the call **without** cookies, Authorization headers, or wallet signatures.
  Document status codes and whether the mutation stuck.
- Check Firebase / Supabase security rules if the project is public or the
  rules file ships in the bundle / repo. Look for `allow read, write: if true`
  and `service_role` used from the client.
- IDOR: replay a legitimate update with a different `id` / `wallet` / `userId`.
- Never dump production user data, never delete, never spam write volume. One
  inert prove-it row (or a dry-run that the server rejects after the auth check)
  is enough for the PoC. Prefer staging / the project's own test fixtures when
  available.

**Severity (honest):**
- Unauthenticated **write** that changes balances, credits, inventory, roles, or
  payouts → Critical / High (map to the program's payout table).
- Unauthenticated **read** of PII, private keys, or full DB dumps → High.
- Unauthenticated read of non-sensitive public-ish data, or write that only
  affects the attacker's own empty sandbox → Low / Informational.
- Exposed `anon` keys that are designed to be public (Supabase anon with tight
  RLS) are not findings unless RLS actually fails.

Record every tested endpoint in `frontend-security/api-auth-matrix.md`
(method, path, auth required?, stranger result, data impact). Failures to
mutate as a stranger go in the kill-log, not the findings table.


## Operating Rules Update (add to main list)

**12. Frontend security is mandatory.** Every bug hunt must check the frontend for
    exposed credentials, even if focusing on smart contracts. Hardcoded API keys,
    bearer tokens, and gas sponsorship keys can be as critical as contract bugs.
    Also hunt for unauthenticated (or under-authenticated) server, API, and
    database access reachable from the frontend — open write endpoints, IDOR,
    and misconfigured Firebase/Supabase/GraphQL are primary targets (see 11J).
    Run Step 11 before or during contract analysis.

**13. Financial impact for infrastructure keys.** When gas sponsorship keys
    (Pimlico, Gelato, Biconomy) or authenticated service keys are exposed, calculate
    the financial impact: `max_operations × cost_per_op × time_until_detected`.
    State this in the severity justification.

**14. Test frontend exposures responsibly.** Only test exposed keys with user
    approval. Document whether keys are protected by origin whitelisting. Testing
    should be read-only verification, never exhausting rate limits or budgets.

**See also operating rule 15** (chain leads to a Critical) in the main list.
A frontend Low, Medium, or High stays in scope when it is a step toward a
Critical, and a confirmed one is reported at that severity. Do not upgrade it
on its own.

---

