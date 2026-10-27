# Shaydez's Web3 Bughunt Skill

End-to-end playbook for hunting bugs in **EVM smart contracts and DeFi protocols**, then turning a verified finding into a **responsible, private disclosure**.

Fill the INTAKE block in [`SKILL.md`](SKILL.md), run Steps 1–10 in order, and use the scripts in [`tools/`](tools/) for every mechanical probe (RPC checks, contract discovery, surface map, auth triage, PoC scaffold, report/DM skeletons). Judgment calls — severity, root cause, exploit design, disclosure strategy — stay manual.

**Researcher identity for reports and DMs:** [shaydez](<SHAYDEZ_PROFILE_URL>) / **Shaydez**.

| | |
|---|---|
| Skill id | `iykes-web3-bughunt-skill` |
| License | [MIT](LICENSE) — Copyright (c) 2026 Shaydez / shaydez |
| Chain coverage | [ANALYSIS-chain-coverage.md](ANALYSIS-chain-coverage.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

---

## What this is

A **copy-paste operational playbook** plus **CLI tools** so you (or an agent) do not re-derive the same bash every hunt:

1. **Ground truth** — is the chain/RPC real?
2. **Find core contracts** — creator trace, bundle grep, browser, explorer
3. **Surface map** — balance, code size, Sourcify, selectors (+ set coverage denominator Y)
4. **Auth triage** — `eth_call` admin paths from an attacker
5. **Foundation map** — state who-writes, call order, token paths, AC, checklist
5.5 **Multi-angle adversarial pass** — drain/freeze/owner, economic, reentrancy, edges, externals (chunked)
5.6 **Dual-ledger vault hunt** — principal vs NAV vs cash (multi-strategy)
6. **Product-type attack questions + bug-class playbook** (manual patterns)
7. **Fork-prove** with Foundry (never mainnet exploit); kill temporary-vs-persistent
8. **Honest severity** + second-opinion gate
9. **Report** (template + master findings table + **coverage.md** honesty + optional filler script)
10. **Private first DM** (template + optional filler script)

**Coverage:** every hunt maintains `coverage.md` (files opened, paths traced, X/Y %, exclusions), updated as work proceeds—not only at the end.

**Best fit:** EVM L2s and appchains with a Blockscout-style `/api/v2` explorer and Foundry-compatible RPC. Also strong for **source/pre-deploy** repo hunts (multi-strategy ERC-4626 vaults, agent allocators, adapters) with local unit PoCs. See the [chain coverage analysis](ANALYSIS-chain-coverage.md) for FULLY / PARTIALLY / NOT EFFECTIVE chains and a porting checklist.

Optional companions (if installed): [forefy/.context](https://github.com/forefy/.context) skills `smart-contract-audit`, `tiny-auditor`, `foundry-poc`. This playbook remains the lead for intake, gates, severity honesty, and private disclosure.

This repo is **tooling only**. Do not commit filled INTAKE blocks, live hunt addresses, draft reports/DMs, or `poc/` build artifacts. Keep hunt work in a private workspace.

---

## Repository layout

```text
.
├── SKILL.md                      # Playbook: INTAKE, rules, Steps 1–10, templates
├── ANALYSIS-chain-coverage.md    # Where the skill works and how to port chains
├── LICENSE
├── CHANGELOG.md
├── README.md
└── tools/
    ├── README.md                 # Per-script usage, examples, exit codes
    ├── selftest.sh               # Graceful-failure smoke test
    ├── step1_ground_truth.sh
    ├── step2_creator_trace.sh
    ├── step2_bundle_grep.sh
    ├── step3_surface_map.sh
    ├── step4_auth_triage.sh
    ├── step7_poc_scaffold.sh
    ├── step9_report_skeleton.py
    └── step10_dm_skeleton.py
```

---

## Prerequisites

```bash
# Foundry (forge + cast)
curl -L https://foundry.paradigm.xyz | bash
foundryup
export PATH="$HOME/.foundry/bin:$PATH"

# Python 3 + curl
# Debian/Ubuntu:
sudo apt-get update && sudo apt-get install -y python3 curl
# macOS: brew install python3 curl

# Optional: GitHub CLI (private disclosure repo in Step 10)
# https://github.com/cli/cli#installation  then: gh auth login
```

**Versions used when packaging/testing tools:**

| Tool | Version |
|---|---|
| `forge` | 1.7.1 |
| `cast` | 1.7.1 |
| `python3` | 3.13.x |
| `gh` | 2.x (optional) |

```bash
git clone https://github.com/shaydez/iykes-web3-bughunt-skill.git
cd iykes-web3-bughunt-skill
chmod +x tools/*.sh tools/*.py
./tools/selftest.sh
```

---

## Quickstart

1. Open [`SKILL.md`](SKILL.md) and fill **INTAKE** (only fields you know; omit unknowns).
2. Export shell vars:

   ```bash
   RPC="<RPC_URL>"
   CID="<CHAIN_ID>"
   BS="<EXPLORER_BASE>/api/v2"   # Blockscout-style API base
   ```

3. Run steps in order (details and gates live in `SKILL.md`):

   | Step | Command / action |
   |---|---|
   | 1 | `./tools/step1_ground_truth.sh "$RPC" "$CID"` |
   | 2 | `./tools/step2_creator_trace.sh "$BS" "0x<token>"` and/or `./tools/step2_bundle_grep.sh "<WEBSITE>"` |
   | 3 | `./tools/step3_surface_map.sh "$RPC" "$CID" "0x<core>" "$BS"` |
   | 4 | `./tools/step4_auth_triage.sh "$RPC" "0x<core>"` |
   | 5–6 | Manual: attack questions + bug-class playbook in `SKILL.md` |
   | 7 | `./tools/step7_poc_scaffold.sh "$RPC" "0x<core>" poc` → fill test → `forge test --fork-url …` |
   | 8 | Manual: honest severity rubric |
   | 9 | `python3 ./tools/step9_report_skeleton.py … -o reports/…` then complete judgment sections |
   | 10A | `./tools/step10_contact_hunt.sh <docs-url> [url…]` then `reports/contacts.md` (URL + quote) |
   | 10 | `python3 ./tools/step10_dm_skeleton.py … -o reports/dm-…` then private DM only |

4. Obey the **operating rules** in `SKILL.md` on every hunt (fork-only verification, honest severity, no threats, private until patched).

Full CLI usage, examples, and exit codes: [`tools/README.md`](tools/README.md).

---

## Tools overview

| Script | Step | Inputs | Outputs / gates | Why it exists |
|---|---|---|---|---|
| `step1_ground_truth.sh` | 1 | RPC, chain id | PASS/STOP | Avoid hours on dead/scam RPCs |
| `step2_creator_trace.sh` | 2A | explorer API, token | creator address | Factory/core discovery |
| `step2_bundle_grep.sh` | 2B | website URL | role-labeled `0x` hits | Hidden frontend config |
| `step3_surface_map.sh` | 3 | RPC, chain, contract, [API] | balance, Sourcify, selectors | Verified vs unverified path |
| `step4_auth_triage.sh` | 4 | RPC, contract, [sigs] | guarded / OPEN | Missing-auth free wins |
| `step7_poc_scaffold.sh` | 7 | RPC, target, [dir] | Foundry PoC + forge cmd | Repeatable fork-only proof |
| `step9_report_skeleton.py` | 9 | INTAKE + severity fields | report markdown | Same report shape every hunt |
| `step10_contact_hunt.sh` | 10A | official URLs | emails + quotes | Prove the real security inbox |
| `step10_dm_skeleton.py` | 10 | project/severity/impact | first DM text | Consistent private first contact |
| `selftest.sh` | — | none | pass/fail smoke | Catch broken tools before a hunt |

---

## Responsible disclosure

Non-negotiable rules (full text in `SKILL.md`):

1. **Fork / `eth_call` verification only. Never move real funds on mainnet.**
2. **Honest severity.** State the bound. A Medium is a Medium.
3. **Chain leads and reports.** Keep a Low, Medium, or High when it can be a step toward a Critical, and report every confirmed one. Full rule: operating rule 15 in `SKILL.md`.
4. **Ask, never threaten.** No "pay or I release/exploit".
5. **Kill your own finding if it does not hold up.**
6. **Never publish a live, unpatched bug.** Private channel + private repo until fixed.

Sign reports as **shaydez**. First DM voice: **Shaydez** (<SHAYDEZ_PROFILE_URL>).

---

## Contributing

Contributions are welcome via **pull request** against `main`.

### Welcome

- **New chain support** following the porting checklist in [`ANALYSIS-chain-coverage.md`](ANALYSIS-chain-coverage.md) (e.g. Etherscan-family explorer adapters, Sourcify gaps, docs for FULLY/PARTIAL chains).
- **New `tools/` scripts** for other *mechanical, repeatable* steps (same bar: CLI args, usage message, fail loudly on RPC/HTTP errors, header comment, `selftest.sh` coverage).
- **Step 6 bug-class additions** that are pattern + detect + fix (concrete, not vague advice).
- Bug fixes, clearer docs, and tests for existing scripts.

### Not welcome (will be closed)

- Changes to the **operating rules**, **severity rubric**, or **disclosure process** — those are deliberate and researcher-specific.
- Replacing researcher identity (**shaydez** / **Shaydez**) or weakening fork-only / no-threat rules.
- Committing hunt artifacts (real addresses, filled INTAKE, draft reports, `poc/` outputs, `.env`).

### How to propose a change

1. Fork the repo and branch from `main`.
2. Keep PRs focused (one concern per PR when possible).
3. Run `./tools/selftest.sh` if you touch `tools/`.
4. Open a PR with a short description of *what* and *why*.
5. For new chains, note explorer type (Blockscout vs Etherscan-family), chain id, and what you tested.

---

## License

MIT — Copyright (c) 2026 Shaydez / shaydez. See [LICENSE](LICENSE).

## Step 3.5: Bytecode Analysis (NEW)

When contracts are unverified (Step 3 finds no source), use the new bytecode analysis workflow:

```bash
# Automated bytecode analysis
./tools/analyze-bytecode.sh 0x<contract> $RPC output-dir

# Creates:
# - bytecode.bin (raw bytecode)
# - disasm.txt (full disassembly)
# - functions.txt (decoded selectors)
# - patterns.txt (CREATE2, CALL, SSTORE)
# - ANALYSIS.md (summary report)
```

**What it finds:**
- Function selectors and signatures
- External call patterns (CALL/STATICCALL/DELEGATECALL)
- Contract deployment (CREATE/CREATE2)
- Storage modifications (SSTORE)

**Combine with Foundry fork testing** to verify behavior without source code.

See [SKILL.md Step 3.5](SKILL.md#step-35---bytecode-analysis-for-unverified-contracts) for full methodology.

**Coverage honesty:** Bytecode analysis allows pattern matching but NOT definitive findings. Always state confidence levels and document the source code limitation.
