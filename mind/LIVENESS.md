# LIVENESS — audit only the code that runs

Gate L0 of every hunt. Runs before the multi-lens read (SKILL.md P1/P2), and
again before any candidate is written `confirmed` (P7/P8).

A bug is only a bug if the broken code is the code that actually runs or ships.
Three of Shaydez's real findings were valid bugs in code that no one deployed:
deprecated contracts, a removed mechanism kept for storage layout, an unused
helper. A perfect proof-of-concept against dead code is worth nothing and burns
trust with the team you report to. So: **be 100% sure the code is live before
you spend a lens on it, and prove it before you call anything confirmed.**

## The rule

> No liveness, no CONFIRMED. A finding against code you have not shown to be
> live, current, reachable and in scope is at most `needs_validation`, with the
> exact missing liveness fact named as its blocker.

This is rule 3 of SKILL.md ("No proof, no CONFIRMED") applied to the target
itself, not just the exploit. Two separate proofs are required for a confirmed
finding and they do not substitute for each other:

1. **Exploit proof** — the bug triggers (fork, harness, unit test, `eth_call`).
2. **Liveness proof** — the exploited code is the code that runs.

## What "live" means — all five must hold

1. **In scope.** The address, repo, package or path is inside the authorized
   engagement or the published bounty/contest scope. "It's on a public chain"
   or "it's in the repo" is not scope.
2. **Current.** It is the version that is deployed or shipping now: the default
   branch, the latest release tag, or the bytecode at the live address — not an
   old commit, a side branch, a stale explorer tab, or an unmerged PR.
3. **Reachable.** A real, unprivileged-or-stated actor can reach it through a
   public entry point. A private/internal function with no live caller is
   reachable only through a caller you must also show is live.
4. **Not retired.** Not deprecated, legacy, sunset, "kept for storage layout",
   or behind a kill switch that is already off.
5. **Not scaffolding.** Not test, mock, example, sample, script, fixture or
   demo code. These ship in repos but not to users.

## The signals that fooled good hunters (treat each as DEAD until disproven)

- **Deprecated / legacy.** `@deprecated`, "legacy", "no longer used", "kept for
  backwards compat", a `legacy/`, `deprecated/`, `old/` or `archive/` path, a V2
  that supersedes this V1. The code compiles and the bug is real; nobody calls it.
- **Removed-but-retained.** An empty or trivial body, a function that always
  returns a default, a storage variable declared but never meaningfully read or
  written, a slot preserved only so a proxy's storage layout does not shift.
- **Unused.** No caller anywhere outside tests, and not itself a public/external
  entry point. An internal helper with zero live callers is dead.
- **Not deployed.** Source in the repo whose bytecode is not at the in-scope
  address: a different implementation behind the proxy, an unverified or
  mismatched contract, a module built but never wired into the deployed system.
- **Test / mock / example.** `test/`, `*.t.sol`, `mocks/`, `examples/`,
  `scripts/`, `fixtures/`. A reentrancy "bug" in a `MockToken` is not a finding.
- **Behind a dead flag.** Guarded by `if (featureEnabled)` / `whenNotPaused`
  where the flag is off or the feature was never switched on in production.

## How to prove it (attach to the finding's `liveness` block)

Use the tools, then record at least two different `method` values in
`findings.json` (`report-schema.json` enforces this on every `confirmed`):

- **Repo targets:** `modules/bughunt/tools/step0_liveness_repo.sh <repo> <file> [symbol]`.
  Checks the file is on the default branch and latest tag, the working copy
  matches it, the path and file carry no deprecation/test/mock smell, recent
  history did not replace it, and the symbol has live callers or is a declared
  entry point. DEAD-candidate → do not hunt it. UNKNOWN → resolve every warning first.
- **On-chain targets:** `modules/bughunt/tools/step0_liveness_onchain.sh <rpc> <address> [artifact]`.
  Resolves EIP-1967 proxy/beacon to the **current** implementation, confirms code
  is deployed, and compares runtime bytecode to your build artifact (metadata
  stripped). Audit the implementation it reports, never an older tab.
- **Scope listing / verified source:** the bounty or contest page listing the
  exact address/commit; the explorer's verified source matching your build.
- **Reachability:** `step3_surface_map.sh` / `step4_auth_triage.sh` to show a
  public entry point reaches the sink.

`method` values the schema accepts: `deployed_bytecode_match`,
`proxy_implementation_current`, `scope_listing`, `default_branch_head`,
`release_tag`, `reachable_from_entrypoint`, `runtime_observation`,
`build_artifact_inclusion`, `maintainer_confirmation`.

## When it is genuinely ambiguous

If you cannot prove the code is live (no deployment yet, scope unclear, cannot
tell which implementation is active), the finding is `needs_validation`, not
`confirmed`, and the blocker names the exact fact: "not proven to be the
deployed implementation at <address>", "file not on the default branch", "no
live caller found; may be an unexposed entry point". Say it plainly in the
report. Never quietly upgrade it, and never report a bug in dead code as if it
were live — flag the dead code separately as a low/informational hygiene note
if it still carries risk (e.g. a deprecated contract that still holds approvals).

## In the lifecycle

- **P1/P2:** run L0 on every unit before it enters the coverage ledger. Mark a
  dead unit `excluded(dead: <reason>)`; it does not get lenses.
- **P7 (kill):** the fresh reviewer re-checks liveness independently. "Is this
  reachable by a real actor on the live version?" is the first kill question.
- **P8 (report):** every `confirmed` finding carries its `liveness` block with
  `target_version` (the exact address/commit/tag/version) and ≥2 methods.
