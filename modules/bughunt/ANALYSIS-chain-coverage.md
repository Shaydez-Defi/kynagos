# Chain coverage analysis — `iykes-web3-bughunt-skill`

**Repo:** https://github.com/shaydez/iykes-web3-bughunt-skill  
**Analyzed:** 2026-07-30  
**Scope:** `SKILL.md` + every script under `tools/` (no skill code was modified for this report).

This report answers: **on which chains is this playbook actually effective as written**, what breaks when assumptions fail, and how much the `tools/` extraction saves in model tokens.

---

## 1. Hard technical assumptions

Each assumption is something the skill **requires or hard-codes**. Soft preferences (e.g. “prefer Blockscout”) that still work with workarounds are noted in §3–§5.

### A1 — EVM-compatible JSON-RPC + Foundry (`cast` / `forge`)

| Source | Evidence |
|---|---|
| `SKILL.md` frontmatter / pairing | “EVM smart contract”; pairs with `evm-audit-*` skills |
| `tools/step1_ground_truth.sh` | `cast chain-id --rpc-url`, `cast block-number --rpc-url` |
| `tools/step3_surface_map.sh` | `cast balance`, `cast code`, `cast disassemble`, `cast 4byte` |
| `tools/step4_auth_triage.sh` | `cast call … --from $ATK --rpc-url` |
| `tools/step7_poc_scaffold.sh` | `forge init`, skeleton `pragma solidity ^0.8.24`, `forge test --fork-url` |
| `SKILL.md` Steps 4, 7, Appendix | `eth_call` auth probes; fork PoC mandatory |

**Assumes:** 20-byte addresses (`0x` + 40 hex), Ethereum JSON-RPC methods (`eth_chainId`, `eth_blockNumber`, `eth_getCode`, `eth_getBalance`, `eth_call`), and a Foundry-compatible fork (Anvil/revm-style).

### A2 — Blockscout-style REST API at `<EXPLORER>/api/v2`

| Source | Evidence |
|---|---|
| `SKILL.md` INTAKE | `EXPLORER : <Blockscout base>`; shell: `BS="<EXPLORER>/api/v2"` |
| `SKILL.md` Appendix | “New chains use **Blockscout**, not Etherscan.” |
| `tools/step2_creator_trace.sh` | `GET $BS/addresses/$T` then JSON field `creator_address_hash` |
| `tools/step3_surface_map.sh` | `GET $BS/addresses/$C/transactions` then `items[]` with `raw_input` / `input` |

**Assumes exact shape:**

- Path: `/api/v2/addresses/{addr}` and `/api/v2/addresses/{addr}/transactions`
- Address payload includes `creator_address_hash`
- Tx list payload is `{ "items": [ { "raw_input": "0x…" } ] }` (or `input`)

This is **not** Etherscan’s `?module=account&action=txlist` form and not Routescan/custom GraphQL.

### A3 — Sourcify v2 verification lookup

| Source | Evidence |
|---|---|
| `tools/step3_surface_map.sh` | `https://sourcify.dev/server/v2/contract/${CID}/${C}?fields=sources,compilation` |
| `SKILL.md` Step 3 gate | Verified → read `src.json`; Unverified → selector map |
| `SKILL.md` Appendix | `sourcify.dev/server/v2/contract/<CID>/<addr>?fields=sources` |

**Assumes:** public Sourcify indexes that `CHAIN_ID`, returns `match` + `compilation.name` + `sources` for verified contracts. No Etherscan `getsourcecode` path exists in the tools.

### A4 — Standard EVM bytecode + PUSH4/EQ selector recovery

| Source | Evidence |
|---|---|
| `tools/step3_surface_map.sh` | `cast disassemble` → `awk '/PUSH4 0x/… /EQ/'` → `cast 4byte` |
| `SKILL.md` Step 3 | “map selectors from bytecode + tx history” |

**Assumes:** Solidity/Yul-style dispatcher (PUSH4 selector, EQ, jump), not pure EOF-only layouts the disassembler cannot walk, and that many selectors appear in the Ethereum Signature Database for `cast 4byte`.

### A5 — Vite or Next.js frontend asset layout (bundle-grep)

| Source | Evidence |
|---|---|
| `SKILL.md` Step 2B | “Vite: one `/assets/index-*.js`; Next: `/_next/static/chunks/*.js`” |
| `tools/step2_bundle_grep.sh` | greps `/assets/…\.js`, `/_next/static/…\.js`, absolute `https?://…\.js` |
| Same script | role regex: `(factory\|launch\|vault\|pool\|router\|oracle\|manager\|locker)"?:"?0x[a-fA-F0-9]{40}` |

**Assumes:** addresses are baked into public JS with those role keys. Step 2C/2D are manual fallbacks when this is false (SPA config at runtime, React Native, non-web clients).

### A6 — Solidity-centric product and bug-class model

| Source | Evidence |
|---|---|
| `SKILL.md` Steps 5–6 | launchpad / lending / vault / perps / distribution; Uniswap v3 `createAndInitializePoolIfNecessary`, ERC20 `balanceOf`, share inflation, etc. |
| `SKILL.md` Step 7 skeleton | `interface ITarget`, `vm.prank` / `vm.deal` |
| Pairing section | always load `evm-audit-general` + `evm-audit-precision-math` |

**Assumes:** value is moved by EVM smart contracts with Solidity-era DeFi patterns. Not Solana programs, Move modules, Cosmos CosmWasm, etc.

### A7 — Public HTTP(S) JSON-RPC (forkable)

| Source | Evidence |
|---|---|
| `step1`, `step3`, `step4`, `step7` | all take `RPC_URL`; timeouts via `CAST_TIMEOUT` / `timeout(1)` |
| Step 7 | `forge test --fork-url $RPC --fork-block-number $BLK` |

**Assumes:** an archive-capable or at least recent-state RPC that Foundry can fork. Rate-limited or non-forkable RPCs degrade Step 7 (skill already allows “exact-logic local PoC” as escape hatch).

### A8 — Optional / soft assumptions (not hard blockers alone)

| Assumption | Source | Notes |
|---|---|---|
| Numeric chain ID matches intake | `step1_ground_truth.sh` | Hard gate for continuing Step 1, not for “is this EVM” |
| Browser DevTools for eth_call `to` | Step 2C | Manual; no script |
| `gh` for private disclosure repo | Step 10 | Optional packaging of disclosure, not hunting |
| Python 3 + curl on PATH | all tools / README | Runtime deps |
| 4byte.org / Foundry sig DB useful | `cast 4byte` in step3 | Soft: misses still leave hex selectors |

---

## 2. What breaks if each assumption is false

| Assumption | If false → impact |
|---|---|
| **A1 EVM + Foundry** | **Total failure of mechanical path.** `step1`, `step3` (RPC half), `step4`, `step7` are dead on arrival. Steps 5–6 bug classes and PoC skeleton do not map. Skill is the wrong tool. |
| **A2 Blockscout `/api/v2`** | **`step2_creator_trace.sh` fails** (no `creator_address_hash`). **Step 3 tx-history selector fallback fails** (no `items`/`raw_input`). RPC/Sourcify/disassemble half of Step 3 still works. Recovery: point `BS` at a real Blockscout instance for that chain if one exists, or port scripts to Etherscan-family API (see §5). |
| **A3 Sourcify indexes chain** | Step 3 almost always takes **unverified path** even when source is verified on Etherscan/BscScan. Hunt is slower (selector map + manual source pull), not impossible. False negative risk: miss readable source and invent wrong ABIs. |
| **A4 PUSH4/EQ dispatcher** | Unverified surface map under-reports selectors (proxy + impl, diamond facets, EOF, heavy assembly). **False negatives on auth triage** if interesting selectors never appear. Tx-history fallback partially compensates when A2 holds. |
| **A5 Vite/Next bundles** | `step2_bundle_grep.sh` returns empty GATE; fall through to Step 2C/2D. Discovery slower, not fatal. |
| **A6 Solidity DeFi patterns** | Steps 5–6 give **wrong attack questions** (e.g. Uniswap v3 squat on a pure AMM-less chain). Auth triage defaults (`setOwner`, `mint`) may be irrelevant. PoC shape still works if EVM, but class playbook is low value. |
| **A7 Forkable RPC** | Step 1/3/4 may work on light RPC; **Step 7 fork tests hang or fail**. Skill already allows logic-only PoC + on-chain magnitude citation. |
| **A8 4byte misses** | Selectors print as hex/`?`; auth triage needs manual sigs from Step 3 history. No hard stop. |

**Composition note:** Full “happy path” automation needs **A1 + A2 + (A3 or A4) + A7**. Partial hunts work on A1+A7 alone if addresses are already known (skip or replace 2A/2B).

---

## 3. Chain effectiveness tables

Classification rules used here:

- **FULLY EFFECTIVE:** EVM + Foundry works + a live **Blockscout-compatible** `/api/v2` explorer exists for the chain + Sourcify commonly useful (or Blockscout+Sourcify path is the documented norm). Playbook can be run without rewriting tools.
- **PARTIALLY EFFECTIVE:** EVM + Foundry work, but **primary explorer is Etherscan-family** (or other non-Blockscout API), and/or Sourcify coverage is thin. Core RPC tools work; creator-trace + tx-history need adaptation or a secondary Blockscout URL.
- **NOT EFFECTIVE:** Non-EVM execution environment (or EVM only as a side channel that is not the app’s security surface).

Public sources consulted for explorer type: Blockscout docs/blog (`chains.blockscout.com`, eth/base/arbitrum/polygon Blockscout hosts), Etherscan V2 multichain family (Basescan, Arbiscan, Polygonscan, BscScan, etc.), Sourcify chain docs.

### 3.1 FULLY EFFECTIVE (or “fully effective with the Blockscout URL”)

These are EVM chains where you can set `EXPLORER` to a known Blockscout host, `BS=$EXPLORER/api/v2`, and run Steps 1–4 and 7 as written. Many also have an Etherscan-family **primary** UI for users; the skill still works if you deliberately use the Blockscout base.

| Chain | Chain ID (mainnet) | Blockscout (examples) | Sourcify | Why FULLY |
|---|---|---|---|---|
| **Ethereum** | 1 | https://eth.blockscout.com | Strong (canonical) | EVM + Blockscout API + Sourcify; Foundry native |
| **Optimism** | 10 | https://explorer.optimism.io (Blockscout-backed) | Strong | OP Stack EVM; Blockscout is first-class |
| **Base** | 8453 | https://base.blockscout.com | Strong | OP Stack; Blockscout instance exists (users often use Basescan) |
| **Arbitrum One** | 42161 | https://arbitrum.blockscout.com | Strong | Nitro EVM; Blockscout instance exists |
| **Polygon PoS** | 137 | https://polygon.blockscout.com | Strong | EVM; Blockscout instance exists |
| **Gnosis Chain** | 100 | https://gnosis.blockscout.com | Strong | Long-time Blockscout “home” chain |
| **Celo** | 42220 | Blockscout-hosted instances (see Chainscout) | Good | EVM; Blockscout commonly used |
| **Linea** | 59144 | Blockscout deployments in ecosystem | Good | zkEVM-compatible JSON-RPC; tools apply |
| **Scroll** | 534352 | Blockscout common for zkEVM L2s | Good | EVM-equivalent for cast/forge |
| **zkSync Era** | 324 | Blockscout / ecosystem explorers | Partial–good | EVM tooling works with caveats (§4) |
| **Gnosis / OP / Base / Arb appchains & RaaS L2s** (Conduit, Caldera, Gelato, AltLayer, etc.) | varies | Often **default Blockscout** via RaaS | Varies | Skill’s appendix (“new chains use Blockscout”) targets exactly this set |
| **Robinhood Chain** (skill example) | 4663 (as in INTAKE example) | Expected Blockscout-style per playbook | Depends on listing | Playbook explicitly designed around this class of L2 |

> **Operational tip:** On dual-explorer chains (Base, Arbitrum, Polygon, Ethereum), set `EXPLORER` to the **Blockscout** host, not Basescan/Arbiscan/Polygonscan/Etherscan, or Steps 2A and 3-tx-history will 404.

### 3.2 PARTIALLY EFFECTIVE — EVM, tools need adaptation or careful EXPLORER choice

| Chain | Chain ID | Primary explorer type | What still works | What breaks / needs change |
|---|---|---|---|---|
| **Ethereum** if you only use **Etherscan** API | 1 | Etherscan | Steps 1, 3 (RPC+Sourcify), 4, 7 | `step2_creator_trace` + Step 3 tx list: need Etherscan port (§5) **or** switch base to eth.blockscout.com |
| **BNB Smart Chain** | 56 | **BscScan** (Etherscan family) dominant | cast/forge, auth triage, fork PoC | Blockscout may exist but is not the default; creator-trace/tx-history as written often fail against BscScan URLs |
| **Avalanche C-Chain** | 43114 | Snowtrace (Etherscan-family) / Routescan | EVM tools | Same API mismatch; Sourcify support must be checked per contract |
| **Fantom Opera** | 250 | FTMScan family | EVM tools | Explorer API port |
| **Moonbeam / Moonriver** | 1284 / 1285 | Moonscan family | EVM tools | Explorer API port |
| **Blast** | 81457 | Blastscan family | EVM tools | Explorer API port; share-economics quirks not in Step 6 |
| **Mantle** | 5000 | Mantlescan family | EVM tools | Explorer API port |
| **Mode, Fraxtal, Zora, World Chain, Unichain, Ink, Soneium** (OP Stack) | varies | Mix of Blockscout and Etherscan-family | Foundry full path | Confirm explorer: if Blockscout → FULLY; if scan.io clone → PARTIAL |
| **Polygon zkEVM / other zkEVM** | varies | Mix | Foundry often works | Opcode/gas quirks (§4); explorer varies |
| **Hedera (JSON-RPC EVM)** | 295 | HashScan + Sourcify support announced | cast/forge for EVM contracts; Sourcify path may work | Not classic Blockscout `/api/v2`; creator-trace needs HashScan/API adapter |
| **Sei EVM** | 1329 | Sei explorers + Sourcify docs | EVM contracts + Sourcify | Confirm Blockscout vs custom; dual-stack chain (non-EVM surface is out of scope) |
| **Kaia (ex-Klaytn)** | 8217 | KaiaScan / Sourcify docs | EVM tools | Explorer API port |
| **TRON** | — | Tronscan | **Not** Ethereum JSON-RPC as first-class | Treat as NOT for this skill unless using a true EVM side with cast support (rare for target apps) |

**Port note for PARTIAL:** Changing only `EXPLORER` in INTAKE is **not** enough if the host is Etherscan-shaped. You must change URL paths and JSON field names in `step2_creator_trace.sh` and the tx-history block of `step3_surface_map.sh` (see §5).

### 3.3 NOT EFFECTIVE — non-EVM (or wrong VM for this skill)

| Chain / stack | Why the skill does not apply |
|---|---|
| **Solana** | No EVM bytecode; no `cast`/`forge` Solidity PoC; bug classes (Uniswap v3 squat, ERC4626 inflation, etc.) do not map. Need Sealevel/Anchor tooling. |
| **Aptos** | Move VM; different account model; no Foundry fork of Move modules. |
| **Sui** | Move/object model; same. |
| **Cosmos SDK chains (Cosmos Hub, Osmosis, …)** without an EVM side | Tendermint + CosmWasm/SDK modules; not `eth_call`. |
| **Cosmos EVM sides (e.g. some Ethermint/Evmos-class)** | Only the **EVM module** is PARTIAL/FULLY; app logic on CosmWasm stays out of scope. |
| **Near** (non-EVM contracts) | Different runtime; Blockscout integrations exist for some ecosystems but skill’s Solidity path is wrong. |
| **Bitcoin, Lightning, Stacks clarity-primary, RGB, etc.** | UTXO / non-EVM; cast/forge irrelevant. |
| **Polkadot / Substrate ink! (non-EVM parachains)** | Different tooling; EVM parachains only if true Ethereum JSON-RPC + Solidity targets. |
| **Cardano, Algorand, Tezos (Michelson primary)** | Non-EVM. (Tezos may have an EVM rollup — that rollup alone could be PARTIAL if Blockscout+Foundry work.) |
| **TON** | Different VM and tooling. |

---

## 4. EVM wrinkles — false negatives / false positives even when “EVM + tools run”

These chains can look FULLY or PARTIALLY effective but still mislead the playbook.

| Wrinkle | Chains / contexts | Effect on skill |
|---|---|---|
| **L2 sequencer downtime / delayed finality** | OP Stack (Optimism, Base, …), Arbitrum, many RaaS L2s | Step 1 “RPC alive” can pass while apps are stuck; fork at block N may not match user-visible state. Severity bounds must account for sequencer trust (centralization ≠ Critical exploit). |
| **Nonstandard `block.number` / L1 block** | OP Stack, some zkEVMs | Time/block assumptions in PoCs and oracle staleness (Step 6.4) can be wrong if you use L2 block as wall clock. |
| **Arbitrum address aliasing / retryables** | Arbitrum One / Nova | Cross-domain auth patterns; default Step 4 probes miss bridge-specific roles. False “guarded” on L2 while L1 entrypoint is open (or reverse). |
| **zkSync Era opcode / account abstraction differences** | zkSync Era | Some Solidity patterns differ; `cast disassemble` still works on bytecode but semantics of system contracts differ. Step 6 Uniswap-v3 patterns may not exist the same way. |
| **Missing PUSH0 / older EVM revision** | Some alt-L1s, older forks | Rare deploy issues; usually not fatal for cast. |
| **`cast 4byte` miss rate** | All chains with custom/proprietary selectors | Step 3 prints `0xdeadbeef ?`; Step 4 default list never hits real admin fns → **false sense of “all guarded”**. Mitigate: always feed Step 3 tx-history sigs into `step4_auth_triage.sh` extra args. |
| **Proxy / diamond / minimal proxy** | Everywhere, esp. upgradeable DeFi | PUSH4 map of **proxy** bytecode under-reports **implementation** surface → false negatives. Need implementation address from storage slots or explorer. |
| **CREATE2 / metamorphic** | Launchpads, factories | Creator-trace still finds factory; factory code may be thin router — surface map must follow clones. |
| **Fee markets / blob base fee** | Ethereum post-4844, OP chains | Unlikely to break tools; can break economic PoC assumptions. |
| **Native multi-token / no classic ETH** | Celo, some appchains | `cast balance` is native token only; “funds at risk ~0” can be **false negative** if value is in ERC20s held by the contract. Always check token balances separately. |
| **Permissioned / allowlisted RPC eth_call** | Some enterprise L2s | Step 4 may always “revert” → false “guarded”. |
| **Heavy rate limits on public RPC** | BSC public endpoints, free L2 RPCs | Timeouts (`CAST_TIMEOUT`); selftest-like hangs if timeout missing. Use private RPC. |
| **Sourcify “not listed” chain ID** | Brand-new RaaS L2 day-one | Always unverified path; do not assume unverified = unaudited source unavailable (check explorer UI / GitHub). |
| **Step 6 pattern locality** | Non-Uniswap ecosystems (e.g. chains without univ3) | Migration pool squat detector never fires; does not mean safe — different DEX primitives. |

---

## 5. Token savings (tools/ extraction vs pre-tools inline)

### 5.1 Method and assumptions

Token counts are **approximate English/code tokens** (roughly 1 token ≈ 4 characters of dense code, or ~0.75 words of prose). They measure **model context cost per hunt step**, not wall-clock or RPC cost.

| Cost component | Pre-tools (inline) | Post-tools (script call) |
|---|---|---|
| Playbook text for the step | In `SKILL.md` once per hunt either way | Same (slightly shorter now) |
| Re-deriving / regenerating the bash/python | Model rewrites the block every hunt (and often every retry) | **Zero** — script is on disk |
| Invocation line | N/A | ~20–80 tokens |
| Tool stdout ingested | Same magnitude either way | Same |
| Repair loops when a one-liner is wrong | High for dense blocks (Step 3) | Low (script already tested; `selftest.sh`) |

**Assumptions for the table below:**

1. “Inline code” = characters of the historical/extracted block × ~0.25 tokens/char.
2. “Inline reasoning tax” = extra tokens the model burns to get flags, quoting, and error handling right **the first time** each hunt (not counting successful stdout).
3. “Script call” = invocation (~40 tokens) + reading typical successful stdout (estimated per step).
4. Steps 9–10 fillers save **template retyping**, not judgment (severity still manual).
5. Savings **compound across hunts** because re-derivation cost was paid every hunt; script authoring is paid once (amortized to ~0 after packaging).

### 5.2 Per-script estimates

| Script | Inline code (approx tokens) | Inline reasoning tax / hunt | Script call + typical output | Tokens saved / hunt | Reduction (order of magnitude) |
|---|---:|---:|---:|---:|---|
| `step1_ground_truth.sh` | ~40 (two cast lines) | ~80–150 (timeouts, compare CID) | ~80–120 | ~50–150 | **Small** (~30–50%). Was already cheap. |
| `step2_creator_trace.sh` | ~80 (curl + python one-liner) | ~150–250 (JSON field names, errors) | ~60–100 | ~150–250 | **Medium** |
| `step2_bundle_grep.sh` | ~120 (html fetch + vite/next greps) | ~200–400 (asset discovery branches) | ~80–200 | ~200–400 | **Medium–high** |
| `step3_surface_map.sh` | ~350–500 (balance, code, sourcify, disassemble awk, 4byte loop, tx Counter) | ~400–800 (fragile multi-stage; often re-tried) | ~150–350 | **~500–1000** | **Large** (biggest win) |
| `step4_auth_triage.sh` | ~120 (for-loop cast call) | ~150–300 (arg arity, revert detection) | ~100–200 | ~150–300 | **Medium** |
| `step7_poc_scaffold.sh` | ~200 (forge init + solidity skeleton + BLK) | ~200–400 (paths, pragma, forge flags) | ~100–180 | ~250–450 | **Medium–high** |
| `step9_report_skeleton.py` | ~250 (full markdown template) | ~100–200 (field plumbing) | ~80–150 | ~200–350 | **Medium** (mechanical fill only) |
| `step10_dm_skeleton.py` | ~120 (DM text) | ~80–150 | ~60–120 | ~100–200 | **Medium-small** |
| `selftest.sh` | N/A (new) | N/A | ~50 once | Prevents wasteful hunts on broken tools | **Meta savings** |

### 5.3 Aggregate: Steps 1–4 + 7 (core mechanical hunt)

Using midpoints of “saved / hunt” from §5.2:

| Bundle | Approx tokens saved per hunt |
|---|---:|
| Step 1 | ~100 |
| Step 2A + 2B | ~450 |
| Step 3 | ~750 |
| Step 4 | ~220 |
| Step 7 | ~350 |
| **Total Steps 1–4 + 7** | **~1,800–2,000 tokens / hunt** |

If you also use Steps 9–10 fillers when filing: **+~400–500** → **~2.3k–2.5k tokens / hunt** mechanical savings.

**Honest caveats:**

- **Step 1** savings are modest; two `cast` lines were never expensive.
- **Step 3** dominates savings: dense disassemble/selector/tx-history pipeline was re-derived (and often re-debugged) every hunt.
- Judgment steps (**5, 6, 8**) are **unchanged** in cost — they still dominate hard hunts. Tools do not make root-cause reading free.
- Output tokens (long selector lists, bundle hits) can still blow context if the model dumps full stdout; skill rule “narrow tool output” still applies.
- If the model previously **copy-pasted** the playbook block without regenerating, savings are lower (closer to 30–40% of the numbers above). If it **re-invented** flags under pressure, savings approach the high end.

### 5.4 Compounding over N hunts

| Hunts | Approx mechanical tokens saved (Steps 1–4+7 only) |
|---:|---:|
| 1 | ~2,000 |
| 5 | ~10,000 |
| 10 | ~20,000 |
| 25 | ~50,000 |

One-time cost to author/maintain scripts (~few thousand tokens of human/agent work, plus `selftest.sh`) is amortized after ~2–3 hunts.

**Secondary savings (harder to quantify, often larger than raw tokens):** fewer failed RPC hangs, fewer wrong explorer field names, fewer broken forge scaffolds — i.e. fewer **multi-turn repair loops** (each repair loop can cost more than the entire script call).

---

## 6. Porting checklist — new chain fails Blockscout API and/or Sourcify

Minimal changes to support a chain that is still **EVM + Foundry** but not Blockscout/Sourcify-shaped.

### 6.1 Confirm EVM baseline (no code change)

1. Public RPC: `cast chain-id --rpc-url $RPC` matches documented chain id.
2. `cast code $ADDR` returns bytecode for a known contract.
3. `forge test --fork-url $RPC --fork-block-number $BLK` can fork (or plan logic-only PoC).

If any fail → do not port explorers; skill remains NOT EFFECTIVE.

### 6.2 Explorer adapter (replace A2)

**Target files:** `tools/step2_creator_trace.sh`, tx-history section of `tools/step3_surface_map.sh`.

| Blockscout (current) | Etherscan-family v2-style replacement (illustrative) |
|---|---|
| `GET {BS}/addresses/{addr}` | `GET {BASE}/api?module=contract&action=getcontractcreation&contractaddresses={addr}&apikey=…` (or account APIs that return creator) |
| JSON `creator_address_hash` | Map response field (e.g. `contractCreator`) → print as `creator` |
| `GET {BS}/addresses/{addr}/transactions` | `GET …&module=account&action=txlist&address={addr}&sort=desc` |
| `items[].raw_input` | `result[].input` — feed first 10 chars into the same `Counter` logic |

**Checklist:**

- [ ] Add optional `--explorer-kind blockscout|etherscan` (or `EXPLORER_KIND` env) rather than forking scripts per chain.
- [ ] Support API key via env (`ETHERSCAN_API_KEY`) without committing secrets.
- [ ] Normalize pagination (Etherscan returns arrays; Blockscout returns `{items, next_page_params}`).
- [ ] Extend `tools/selftest.sh` with a mocked JSON fixture test for the new parser (optional but recommended).
- [ ] Document the explorer base + kind in INTAKE (`EXPLORER`, `EXPLORER_KIND`).

### 6.3 Sourcify gap (replace or skip A3)

- [ ] Check https://docs.sourcify.dev/docs/chains/ for the chain id.
- [ ] If unsupported: keep Step 3 unverified path; add optional Etherscan `getsourcecode` fetch into `step3_surface_map.sh` writing `src.json`-compatible or `Source.sol` files.
- [ ] If using explorer-verified ABI only: still run PUSH4 map; do not pretend Sourcify `match` succeeded.

### 6.4 Opcode / fork wrinkles (§4)

- [ ] Note L2 block vs L1 time in hunt NOTES.
- [ ] For proxies: resolve implementation before auth triage.
- [ ] Pass real selectors from tx history into `step4_auth_triage.sh` as extra args.
- [ ] Load `evm-audit-chain-specific` for OP/Arb/zkSync-class targets (already suggested in `SKILL.md`).

### 6.5 Frontend discovery (A5)

- [ ] If not Vite/Next: skip `step2_bundle_grep.sh`; use Step 2C network tab or chain-specific config URLs.
- [ ] Optionally extend grep patterns for Remix/Webpack (`/static/js/`) if that stack is common on the chain’s apps.

### 6.6 Validation before calling the chain “supported”

- [ ] `./tools/selftest.sh` still passes.
- [ ] One smoke hunt: Step 1 → 2A or 2B → 3 → 4 → 7 dry scaffold on a known low-value contract.
- [ ] Record chain id, RPC, explorer base, explorer kind, Sourcify yes/no in a one-line row for future hunts.

---

## 7. Summary judgment

| Question | Answer |
|---|---|
| What is this skill optimized for? | **EVM appchains and L2s with Blockscout + Foundry**, launchpad/DeFi-style Solidity, fork-only disclosure workflow |
| Where is it strongest? | OP Stack / RaaS L2s, Gnosis, chains whose canonical explorer is Blockscout; dual-explorer majors **if** you point at Blockscout |
| Where does it half-work? | BSC, Avalanche C-Chain, and other **Etherscan-family** primaries — RPC/PoC fine, explorer scripts need a port |
| Where is it useless? | Solana, Move chains, Cosmos non-EVM, Bitcoin-family, and any non-`eth_*` JSON-RPC environment |
| Biggest tools/ token win? | **Step 3 surface map** (~0.5–1k tokens/hunt), then Steps 2B and 7; Step 1 is almost noise |
| Full mechanical path savings | **~2k tokens/hunt** (Steps 1–4+7); **~20k over 10 hunts**, before counting avoided repair loops |

---

*Report only — no changes to skill logic. Prepared for inclusion as `ANALYSIS-chain-coverage.md` in the repo root.*
