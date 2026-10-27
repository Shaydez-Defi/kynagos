# VOICE — PoCs, reports and DMs that read like a human wrote them

Load in P6 (prove), P8 (report) and P9 (disclose). Everything that leaves the
audit folder under Shaydez's name must sound like one careful researcher who
found a bug and checked it twice. Not like a model filling a template.

Triage teams see hundreds of AI-written submissions. Machine-sounding text gets
skimmed, doubted, or closed as spam before anyone runs the PoC. A plain,
specific, slightly terse report gets read.

## The test

Before anything ships, ask: **would a senior auditor send this exact text from
their own account?** If a sentence could appear in any report about any bug,
cut it or replace it with a fact about this one.

Then run the linter and fix every `FIX` line by rewriting, not by synonym swap:

```
python3 modules/bughunt/tools/humanize_check.py report.md dm.txt test/Exploit.t.sol
```

The linter catches patterns. It does not make text human. Read it once out loud.

## Reports

- **Lead with the bug in one sentence.** Who can do what, to whose money, how
  much. "Anyone can drain the reward pool by calling `claim()` twice in one block."
- **Numbers, not adjectives.** "41,200 of the pool's 41,250 USDC on a fork at
  block 19,000,000", not "a significant portion of funds".
- **Short and uneven.** Mix short sentences with longer ones. Real people do not
  write five sentences of equal length in a row.
- **One idea per paragraph.** Three to five sentences, often fewer.
- **Say what you checked and what you did not.** "I did not test the Arbitrum
  deployment." Honest limits read as competence.
- **State the liveness proof in a line.** "Reproduced against the implementation
  currently behind the proxy at 0x…, block N." (mind/LIVENESS.md)
- **Light formatting.** Severity, title, and the standard sections from the
  Kensho Part 8 template. Bold the severity and nothing else most of the time.
  No headings inside a 200-word section. No tables unless comparing numbers.
- **First person, sparingly.** "I", not "we", not "the researcher". Do not
  narrate your process ("First I examined…").
- **The fix is concrete.** A diff or the exact line to change, not "consider
  implementing robust validation".
- **End when the content ends.** No summary paragraph, no "In conclusion", no
  "Let me know if you have any questions".

Banned (also enforced by the linter): delve, tapestry, landscape, realm,
comprehensive, robust, seamless, holistic, leverage, utilize, crucial,
paramount, pivotal, "it's important to note", "in conclusion", "furthermore",
"moreover", "it's not just X, it's Y", "this isn't about X", "here's the
thing", "the reality is", "underscores", "raises the question", "serves as a
testament", "I hope this message finds you well", "please do not hesitate",
"game-changer", "cutting-edge", any emoji, em dashes used as a crutch.

### Before → after

> This comprehensive analysis delves into a critical vulnerability in the
> protocol's reward distribution mechanism. It's important to note that this
> issue could potentially lead to significant loss of user funds.

> `claim()` updates `lastClaimed` after paying out, so a second call in the same
> block pays again. On a mainnet fork at block 19,000,000 a fresh account
> drained 41,200 of 41,250 USDC in one transaction. Moving the update above the
> transfer fixes it (diff below).

## PoCs

A PoC is read by an engineer who wants to run one command and see the number.

- **One command, pinned.** `forge test --mt test_doubleClaim -vv --fork-url $RPC --fork-block-number 19000000`.
- **Real names.** `attacker`, `alice`, `pool`, `usdc`. Not `user1`, `contract2`,
  `myVar`.
- **Assert the impact in numbers.** `assertEq(usdc.balanceOf(attacker), 41_200e6);`
  A PoC that only "doesn't revert" proves nothing.
- **Comments say why, not what.** One short comment where the trick happens
  (`// second claim in the same block: lastClaimed not yet updated`). No
  `// Step 1: deploy`, `// Step 2: approve` narration on every line.
- **No decoration.** No `console.log("===== 🚀 EXPLOIT =====")` banners, no ASCII
  art, no emoji. Log the before/after balances, nothing else.
- **Smallest setup that works.** Delete unused imports, helpers and actors. If
  a line can go without breaking the assert, it goes.
- **Match the target's style.** Same Solidity version, same test framework,
  same naming conventions the team already uses.
- **It must run.** Never hand over a PoC you did not run on the frozen version.

## Disclosure DMs (P9)

- Two to four short sentences for the first message. Who you are in five words,
  that you found a security issue in X, that you'd like a private channel, and
  that you're not asking for anything in return to share it.
- No severity theatrics, no deadlines, no threats, no "urgent" in caps.
- No pasted report in the first DM unless they asked for it.
- Write like you'd text a developer you respect. Sign as Shaydez.

> Hi, I'm Shaydez, an independent security researcher. I found an issue in the
> rewards contract that lets one account drain the pool, and I've confirmed it on
> a fork. Is there a private channel where I can send details and a PoC?

## Final pass (every outgoing file)

1. `humanize_check.py` shows no `FIX` lines.
2. Every number in the text matches the PoC output on the frozen version.
3. Every sentence is specific to this bug. Generic ones are gone.
4. Read aloud once. Anything you would not say to a person, rewrite.
