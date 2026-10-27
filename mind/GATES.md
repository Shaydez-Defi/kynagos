# GATES — work like a careful human, not a confident junior

Load at the start of every Standard or Full run, next to SCHNEIER.md and LENSES.md.
Adapted for security audits from the SureForge quality-control workflow
(github.com/Da7-Tech/SureForge, MIT, see CREDITS.md). This is a discipline, not
a guarantee and not software enforcement.

The failures this stops: starting to hunt before scope is clear, treating
silence as "yes", reading a sample and calling it coverage, grading your own
work, and declaring victory after the review rounds ran out.

## Five rules that stay on

1. **Know the contract.** Keep the original request, scope, out-of-scope list,
   authorization, permissions and budget written down (`scope.md`). A proposal
   you made, a question the user skipped, or silence is never approval.
2. **Advance on evidence.** Every gate ends READY, REPAIR or BLOCKED. A required
   check that did not run is not passed. Running out of review rounds is BLOCKED,
   never "done".
3. **Separate hunting from judging.** The agent that found a candidate does not
   approve it. The reviewer gets the candidate, the code and the scope, not the
   finder's confidence, reasoning or desired verdict. Investigate criticism
   before applying it; do not break a correct finding to please a wrong reviewer.
4. **Cover the agreed scope on the current version.** Enumerate every unit in
   the coverage ledger. Sampling is not coverage. Evidence from an older commit,
   an older run, or an older deployment counts only after you re-check it still
   applies, and you say it was reused, never "freshly verified".
5. **Report honestly.** Missing tools, unrun checks, unproven liveness and
   uncertain results stay visible in the final report. This file grants no
   permission to touch live systems, spend money, or disclose anything.

## Pick the tier (write it in scope.md with one sentence why)

| Tier | When | What it costs |
| --- | --- | --- |
| Light | A question, one function, a quick sanity check | Understand, check liveness, answer. No ceremony. |
| Standard | A normal audit or bounty hunt | Four gates below. At least **two different methods** per gate. Independent reviewer at G3 and G4 when one is available, else write `self-review-only` in the report. |
| Full | The user asks, a Critical/High is on the table, or the result is hard to undo (public disclosure, a paid contest submission) | At every gate **three genuinely different owner methods**, then a fresh-context reviewer that picks its own three methods. |

Escalate the tier when risk grows. Never quietly downgrade a review you promised.
If the reviewer or a third method is unavailable in Full mode, stop that gate
and ask the user for access, a human reviewer, or an explicit tier change.
Label reduced assurance as reduced; never call it full verification.

## The four gates, mapped to the lifecycle

**G1 Scope (end of P0).** Authorization, scope, out-of-scope, live-writes NO,
tier, budget. Liveness gate L0 run on the in-scope targets (mind/LIVENESS.md).
Ask only questions that change the outcome; a skipped question stays open.

**G2 Map (end of P2).** Every unit enumerated in the coverage ledger with a
status. Dead units excluded with a reason. Every acceptance item ("all
value-moving functions get three lenses") mapped to the units and the check
that will prove it.

**G3 Prove (end of P6/P7).** For each candidate: exploit proof on a fork or
harness, liveness proof with ≥2 methods, and a fresh reviewer that tried to
kill it. A bug-fix claim needs a failing test first, then a passing one.

**G4 Deliver (P8/P9).** Freeze the report and PoCs. Re-run every PoC on the
frozen version. Re-check every number in the text against PoC output. Run
`validate-findings.cjs` and `humanize_check.py`. Then state: target version,
what was covered, what was not, what was reused, and the tier actually achieved.

## Three different methods (pick what fits; they must really differ)

- Re-run the PoC from a clean checkout on the pinned block.
- Re-derive the bug by hand from source, line by line, without the PoC.
- Trace the call path from a public entry point to the sink.
- Diff the deployed bytecode or the release tag against what you read.
- Write a second, independent test that hits the same root cause another way.
- Check the invariant with a fuzzer (`modules/fizz`).
- Search precedent for the same class and confirm this is not a known/accepted issue.
- Read the team's docs, comments and tests for intended behavior and compare.

Reading the same file twice is one method, not two.

## Running a gate

For each gate record: round number, tier, the scope version, the exact target
version (commit/address/block), methods used, evidence, coverage, findings,
and the decision.

- Every reviewer finding gets one status: `confirmed`, `refuted-with-evidence`,
  `unresolved`, `duplicate`, or `out-of-scope`.
- **Three review rounds per gate, total:** the first, then at most two
  repair-and-recheck rounds. Restarting the session does not reset the count.
- **READY** only when required checks, coverage, review and approvals are met.
  **REPAIR** for a fixable gap with rounds left. **BLOCKED** for a missing
  permission or tool, exhausted rounds, or material uncertainty with no safe
  way through. On BLOCKED, stop the dependent work and tell the user exactly
  what would unblock it.

Zero findings is a valid result only with full coverage and evidence. No
defect quotas, no forced disagreement.

## Resuming a run

Reload scope, decisions, the ledger, open findings, gate counters and the target
version. If the target moved (new commit, new implementation behind the proxy),
everything that depended on the old version is unverified until re-checked.
Write a short state record; never carry forward a claim that a forgotten check
still counts.
