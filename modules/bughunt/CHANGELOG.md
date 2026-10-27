## 2026-10-24

- Step 11: explicitly hunt unauthenticated server/API/database access (writes, IDOR, open Firebase/Supabase/GraphQL) as a primary frontend objective, not only leaked keys.

# Changelog

## [v0.2.4] - 2026-10-10

### Changed

- **Operating rule 15.** A confirmed Low, Medium, or High is reported at that
  severity, whether or not it chains to a Critical. Write the Step 9 report and
  include it in the private disclosure. Do not leave it only in hunt notes, and
  do not wait for a Critical. Killed findings stay out of the report.

## [v0.2.3] - 2026-10-10

### Added

- **Operating rule 15, chain leads to a Critical.** Hunt and keep a Low, Medium,
  or High when it is a usable step toward unauthenticated theft, a freeze, or
  unbounded loss. Record it at its honest severity, name the missing piece, and
  try the chain before closing the path. A fork-proven chain is reported at the
  chain severity. A missing piece stays as a lead on the findings table
  (`chain-to-critical`). Drop the lead only when the chain is impossible. Do not
  upgrade the piece by itself.
- Pointers in Steps 5.5, 6, and 8, the Step 9 findings table, Appendix B prompt
  14, and Appendix C. Description frontmatter mentions the same rule.

## [v0.2.2] - 2026-08-15

### Added

- **Step 10A official contacts (mandatory):** before any DM, hunt the real
  security inbox from official docs / SECURITY.md / staff forum posts / verified
  org X. Write `reports/contacts.md` with URL + exact quote. Do not guess
  `security@` or DM lookalike handles.
- `tools/step10_contact_hunt.sh` fetches pages, extracts emails, bounty-platform
  links, nearby quotes, and decodes Cloudflare `data-cfemail`.
- INTAKE fields `SECURITY_EMAIL` and `DISCLOSURE` (fill from 10A or omit).

## [v0.2.1] - 2026-08-10

### Added

- **Coverage tracking (mandatory):** maintain `coverage.md` during every hunt/audit
  with files opened, code paths traced (not just files touched), coverage %
  (X/Y files), and explicitly excluded areas with one-line reasons.
- Running table format plus top summary line `Coverage: X/Y files (Z%)`.
- Incremental update rule (as files are read, not only at the end).
- Low-coverage honesty gate before final report / user summary.
- Operating rule 10 and token-budget rule 9; Step 3 inventory sets Y; Step 9 and
  multi-finding packs include coverage.md.

## [v0.2.0] - 2026-08-10

### Added

- **Step 5 foundation map** before deep findings: state who-writes, external call
  order, token paths, access gates, structured PASS/FAIL first-pass checklist.
- **Step 5.5 multi-angle adversarial pass** for complex logic: malicious drain/freeze,
  economic/math, state/AC/reentrancy, edges, external integrations. Chunked prompts
  (one mechanism at a time).
- **Step 5.6 dual-ledger / multi-strategy vault hunt**: principal book vs NAV vs cash
  returned; forced questions (gross vs supplied, unrealizable NAV, phantom zero
  withdraw, maxWithdraw lie, view/pull asymmetry, epoch coupling, lastPass over-pull).
- **PRODUCT_TYPE** `multi-strategy-vault` and expanded vault attack questions.
- **Bug classes 8–12**: unrealizable NAV preferential exit; gross book vs supplied;
  phantom zero-return withdraw; view/pull asymmetry; compromised-agent churn without
  external send.
- **Severity second-opinion gate** (gas, AC, reachability, mitigations, temporary vs
  persistent). Temporary restore sandwich must be killed before claiming bank-run theft.
- **Optional companion skills** (forefy/.context): smart-contract-audit, tiny-auditor,
  foundry-poc. This playbook remains lead for intake/disclosure.
- **Slither triage rule**: no Critical from static High without a working PoC.
- **PoC quality bar** and Appendix B adversarial prompt pack; Appendix C hunt hygiene.
- Token-budget rule: chunk analysis, do not full-repo dump.

### Changed

- Operating rules: honest bounds, trust-root vs permissionless, temporary vs persistent.
- Step 3: source-only / pre-deploy repo audits allowed with local unit PoCs.
- Step 9: master findings table + multi-finding private pack guidance.
- Description frontmatter updated for new steps and dual-ledger focus.

## [v0.1.0] - 2026-07-30

### Added

- Initial packaging of **Shaydez's Web3 Bughunt Skill** (`iykes-web3-bughunt-skill`).
- Renamed skill from `duke-web3-bug-hunting` (skill id only; researcher identity remains shaydez / Shaydez).
- Extracted mechanical Steps 1–4 and 7 into `tools/` CLI scripts:
  - `step1_ground_truth.sh`
  - `step2_creator_trace.sh`
  - `step2_bundle_grep.sh`
  - `step3_surface_map.sh`
  - `step4_auth_triage.sh`
  - `step7_poc_scaffold.sh`
- Template fillers for Step 9 report and Step 10 first DM:
  - `step9_report_skeleton.py`
  - `step10_dm_skeleton.py`
- `tools/selftest.sh` smoke-checks graceful failure (usage message, non-zero exit, no hang).
- `tools/README.md` with purpose, usage, examples, and exit codes per script.
- Top-level README, MIT LICENSE, `.gitignore` for Foundry/hunt artifacts.
- Standalone git repo (separate from the broader `secres` workspace).

## [Unreleased] - 2026-09-19

### Added
- **Core Principle: Proactive Problem-Solving** at the top of SKILL.md
  - When you hit a blocker, actively find or build a solution
  - Examples: install decompilers, find alternative APIs, scrape data, query on-chain
  - Document every workaround for future hunts
- **Operating Rule 11: Overcome blockers proactively**
  - Search internet for tools that solve the problem
  - Install packages with pip/cargo/npm when needed
  - Create scripts to automate repetitive tasks
  - Do NOT stop at "source code unavailable" or "tool not installed"
- **Step 3.5: Bytecode Analysis for Unverified Contracts**
  - Comprehensive methodology for dealing with unverified contracts
  - New tool: `tools/analyze-bytecode.sh` for automated bytecode analysis
  - Extracts function selectors, external calls, CREATE/CREATE2, storage writes
  - Integration with Foundry fork testing for behavior verification
  - Honest coverage tracking for bytecode-only analysis
  
### Changed
- Step 3 now branches to Step 3.5 when contracts are unverified
- Coverage tracking updated to document bytecode analysis confidence levels
- Reporting guidelines include unverified finding disclaimer templates
- Skill mindset: from "blocked by missing tools" to "find tools to unblock"

### Why This Update
During the Ellipse hunt on Arc blockchain, all core contracts were unverified.
This blocked the investigation at Step 3. Instead of stopping, we:
1. Searched for decompilation tools
2. Created bytecode analysis methodology when decompilers weren't available
3. Built Foundry fork tests to verify behavior
4. Successfully identified CRITICAL vulnerability pattern (60% confidence)

This update codifies that proactive mindset as a core operating principle.
Future hunts should never stop at "tool not available" - find or build the tool.

### Testing
- Used on Ellipse launchpad (4 unverified contracts)
- Extracted 85 function selectors from 39KB bytecode
- Identified CREATE2 deployment and 13 external CALLs
- Created 6 Foundry fork tests (5 passing)
- Successfully identified CRITICAL vulnerability pattern despite no source code
