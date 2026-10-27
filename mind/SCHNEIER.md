# How Bruce Schneier Thinks — a Reasoning Method for Code, Protocol and DeFi Audits

Distilled from Schneier's public essays, papers and book material (sources in §9, all opened on 2026-10-25).
Everything is paraphrased. The few short phrases in quotation marks are attributed inline.
Where an idea comes from a secondary source (reviewer notes, interviews) rather than his own text, the source line says so.

How to use this file: §1 and §7 shape how the agent thinks. §2–§5 are the procedures it runs. §6 lists the traps to avoid. §8 is the compact block to paste into a system prompt or SKILL.md.

---

## 1. Core mindset — principles

Each item covers: **Idea** → **Why it works** → **Auditor move** → **Source**.

### 1.1 Think about how it fails, not how it works
- **Idea:** Builders ask "how do I make this work?" Security analysts ask "how can this be *made* to fail, and who gains when it does?" His first example is an ant-farm company that will mail live ants to any address you write on a card. The useful observation is not that you can get ants by post. It is that the company will send them to anyone you name.
- **Why it works:** Developers test the paths they meant to build. Attackers use the paths the system allows but nobody intended. You only see those if you deliberately take the opponent's point of view.
- **Auditor move:** For every function, write down who can call it, with what inputs, in what order and in what state. Then ask what the most harmful thing is that the code *allows*, as opposed to what the docs say it does. Treat each "the user will only…" in the docs as an untested assumption.
- **Source:** "The Security Mindset" (2008).

### 1.2 Keep the letter, break the spirit
- **Idea:** One of his explicit self-tests: could I satisfy every stated rule and still defeat what the rule was for?
- **Why it works:** Most real exploits are not crashes. They are valid sequences of allowed actions that produce an outcome the designer never wanted. Checks pass because they check the letter.
- **Auditor move:** For each `require`/invariant, write down the property it is *meant* to protect (solvency, fair share price, one vote per token). Then look for inputs that pass the check and still violate that property: rounding, same-block sequences, flash-borrowed balances, donations, self-transfers, zero amounts, reentrancy through callbacks.
- **Source:** "The Security Mindset" (2008); *A Hacker's Mind* definition of a hack (§4).

### 1.3 Your failure to break it proves nothing (Schneier's Law)
- **Idea:** Anyone can design a system they personally cannot break. That says nothing about whether others can. The burden of proof is on the designer, and what counts is a track record of breaking things plus long outside review. The question he puts to designers is roughly "show me what you've broken".
- **Why it works:** Designers share the blind spots of their own design, and confidence grows fastest when skill is lowest. He links this to Dunning-Kruger.
- **Auditor move:** Never accept "we couldn't find an attack" as evidence, and that includes your own earlier passes. Treat new, home-made mechanisms (custom math, a new AMM curve, bespoke signature schemes, hand-rolled access control, novel oracle designs) as high-risk by default. Prefer constructions that have been battle-tested and analysed in public. Give a new mechanism a separate adversarial pass, with a fresh context if possible.
- **Source:** "Schneier's Law" blog post (2011), quoting his 1998 Crypto-Gram text.

### 1.4 Secure against whom, and for how long?
- **Idea:** "Secure" means nothing until you name the attacker (skill, access, money, risk tolerance) and the time horizon.
- **Why it works:** Different attackers prune different branches of the attack tree. A bored student won't bribe anyone. Organised crime will. An attacker who is willing to lose money changes everything.
- **Auditor move:** Define attacker profiles up front. Useful DeFi set: unprivileged user with flash-loan capital; MEV searcher/block builder who can reorder and sandwich; a whale or large LP; a malicious or compromised admin/multisig/keeper; a governance attacker who buys or borrows votes; an oracle or bridge operator; a malicious token or hook contract you integrate with. Mark every finding with the profiles that can carry it out.
- **Source:** "Attack Trees" (1999); *Beyond Fear* ch. 5 notes (attackers differ by motive, objective, expertise, access, resources, risk aversion).

### 1.5 Security is a system; attack the system, not the component
- **Idea:** Schneier describes his career as one generalisation after another. Strong crypto was beaten through the computer it ran on, secure computers through the network, secure networks through people. The weakest link is usually *outside* the part everyone is staring at.
- **Why it works:** Attackers go around strong parts. In the PGP attack tree, breaking the cipher is the *least* attractive route. Keyloggers and stolen passphrases are far cheaper.
- **Auditor move:** Don't just audit the contract in scope. Map the deployment around it: proxies and their admins, initializers, oracles, keepers and bots, bridges, front-end and RPC, upgrade path, multisig signers, external tokens and their hooks, off-chain signers, deploy scripts and constructor arguments. Ask where the seams are. Value moving between two well-guarded components is where the guards are not.
- **Source:** CSO interview "The Evolution of a Cryptographer" (2003); "Attack Trees" (1999); *Beyond Fear* ch. 4 notes on "seams".

### 1.6 The weakest link sets the security level
- **Idea:** Defenders have to cover every point. The attacker picks one. Making a strong part stronger (a longer key) does little if a weak part exists. He compares this to driving one huge stake into the ground and hoping the enemy runs into it, when what you need is a low palisade all the way round.
- **Why it works:** Security is a minimum over all paths, not an average. In tree terms: an OR node costs as little as its cheapest child.
- **Auditor move:** Rank attack paths by *cheapest total cost*, not by how interesting they are. Don't spend audit time polishing a robust core while a one-line `onlyOwner` setter, an unchecked oracle, or an unprotected `initialize` stays unexamined. Survey the whole surface briefly first, then go deep where it is cheapest to attack.
- **Source:** "The Process of Security" (2000), "Secure the Weakest Link"; "Attack Trees" (1999); *Beyond Fear* ch. 8 notes.

### 1.7 Complexity is the worst enemy of security
- **Idea:** More options, features, interfaces and interactions mean more to analyse, and analysis is the only way to judge security. Testing can show a feature works. It cannot show that nothing bad is possible.
- **Why it works:** Security is a property of everything the system *prevents*, and you can't sample your way to a guarantee about what doesn't happen. Interactions between systems also count, not just each system alone.
- **Auditor move:** Count the surface: external entry points, roles, modes and flags, token types supported, cross-contract calls, callback hooks. Give each extra interaction its own review. Treat composability (vault → strategy → AMM → oracle → lending market) as multiplying risk. Recommend removing features and options as a real fix. Unit tests passing is not evidence of security; ask for invariants and adversarial fuzzing instead.
- **Source:** "A Plea for Simplicity" (1999); "The Process of Security" (2000), "Embrace Simplicity".

### 1.8 Security is a process, not a product
- **Idea:** No product makes you secure. Security comes from an ongoing cycle of prevention, detection and response, plus watching the watchers. Later he refined this: tactically it is people, process *and* technology, in different proportions.
- **Why it works:** Every product has flaws. A process notices when they are exploited and limits the damage.
- **Auditor move:** An audit report is a moment in time, not a seal of approval. Always assess the protocol's detection and response capacity as well: monitoring, pause/guardian paths, rate limits, timelocks, upgrade and incident playbooks, bug bounty, who can act in 5 minutes vs 5 days. Report any "no way to stop the bleeding" as a finding in its own right.
- **Source:** "The Process of Security" (2000); "The Future of Incident Response" (2014).

### 1.9 Detection and response cover what prevention misses
- **Idea:** Prevention is expensive and never perfect. A safe's rating only *buys time* for an alarm and a guard to arrive. Detection is useless without response. Response comes in several forms: reaction against the attacker, mitigation, recovery, forensics, counterattack. Audit after the fact is often the cheapest security there is, *if* the system can be audited.
- **Why it works:** Exploits happen in one transaction, but losses usually build up over many blocks or many calls. Time to notice and act is what decides the size of the loss.
- **Auditor move:** For each critical asset, ask how long prevention buys and who can act inside that window. Check that the protocol emits events which allow reconstruction, that guardian pause can't itself be front-run or griefed, that recovery (withdraw-only mode, migration) exists, and that forensics and recovery don't conflict (e.g., upgrading wipes evidence state).
- **Source:** *Beyond Fear* ch. 11–12 (secondary notes, Granneman); "The Future of Incident Response" (2014).

### 1.10 Design to fail well (resilience over brittleness)
- **Idea:** Every system fails. What matters is *how*. Brittle systems fail completely and catastrophically. Resilient ones degrade gracefully, contain the damage, and fail into a safe state: an ATM that breaks shuts down, it doesn't pour out cash. Secrets that are global and hard to change are brittle. So are homogeneous systems (one bug breaks every instance) and systems that drop to insecure behaviour when something fails. He calls a system's resilience its single most important security property.
- **Why it works:** Your failure analysis is where the attacker starts. A system that fails open turns any glitch into an exploit.
- **Auditor move:** For every external dependency, ask what happens when it fails, lies, stalls or reverts: oracle stale/zero/huge, sequencer down, token pauses or blacklists, bridge halts, keeper stops, a callback reverts. Does the code revert (fail closed), carry on using stale values (fail open), or brick withdrawals (fail badly for users)? Look for single points of total loss: one admin key, one oracle, one signer, one global invariant whose breach drains every pool. Recommend compartmentalisation (per-market isolation, caps, rate limits) so one failure can't cascade.
- **Source:** "The Process of Security" (2000), "Fail Securely"; *Beyond Fear* ch. 9 (Springer chapter abstract; Granneman notes); "The CrowdStrike Outage and Market-Driven Brittleness" (2024, with Raghavan); CSO 2003 interview on "brittle".

### 1.11 Class breaks: when one bug breaks every instance
- **Idea:** Standardisation and automation give attackers leverage. Once a flaw is found in a shared component, every copy breaks at once, and automation scales the attack.
- **Why it works:** Forked code, shared libraries and factory-deployed clones carry the same bug everywhere.
- **Auditor move:** When you find a bug in a shared library, base contract, factory template or popular fork, check every instance and every protocol that inherits it. Flag homogeneity risk (all markets behind one oracle adapter, all vaults on one strategy template).
- **Source:** *Beyond Fear* ch. 7 and 9 (secondary notes).

### 1.12 Every security system depends on trusted people; limit and split that trust
- **Idea:** Even automated systems have trusted people: whoever installs, maintains, configures and upgrades them. Make it safe to trust them by choosing trustworthy people, compartmentalising (give each only the access the job needs) and overlapping duties so people check each other. Two keys held by two people; ticket sellers separate from ticket takers. Watch out for transitive trust, which is brittle.
- **Why it works:** Insiders and compromised keys get around all external defences.
- **Auditor move:** List every privileged role and exactly what it can move or change. Check for least privilege, separation of duties (proposer ≠ executor ≠ guardian), timelocks so others can watch, and limits on what even a fully compromised role can take. Write down the trust assumption for each role explicitly. Follow transitive trust: whatever your contract trusts, also trusts what *that* trusts.
- **Source:** *Beyond Fear* ch. 10 (secondary notes); "The Process of Security" (2000), "Limit Privilege", "Watch the Watchers".

### 1.13 Security failures are often economic: follow the incentives
- **Idea:** Many systems fail not for technical reasons but because the party that could fix the problem doesn't bear the cost when it happens: an externality. The fix is to give the risk to whoever is best placed to reduce it. He argues information security is mainly an economics problem, not a technology problem.
- **Why it works:** People optimise for the costs they actually carry. A design that relies on someone acting against their own interest will be defected against.
- **Auditor move:** For every actor (LPs, borrowers, liquidators, keepers, oracle reporters, governance voters, admins, integrators, MEV searchers), ask what they gain or lose under each action. Look for profitable deviations: liquidations that pay to delay, keepers paid regardless of correctness, governance able to vote itself the treasury, protocols that push losses onto LPs while fees go elsewhere. A finding can be purely economic, with no code bug at all.
- **Source:** "Information Security and Externalities" (2007); Anderson & Schneier, "Economics of Information Security" (IEEE S&P 2005); "Eliminating Externalities in Financial Security" (2009) via search excerpt; *Beyond Fear* ch. 3 notes on agendas and externalities.

### 1.14 Each player has an agenda, and each proxy has its own
- **Idea:** Every security decision involves several players, each with their own view of risk and their own non-security goals. People who act on others' behalf bring their own agendas. Systems are sometimes "secured" for the owner's benefit, not the user's.
- **Why it works:** Who wrote a control and whom it serves predicts how it will be bent.
- **Auditor move:** For each control, ask whose interest it protects. A fee switch, upgrade key or "emergency" withdrawal that protects the team, not depositors, is a risk to users and should be reported that way.
- **Source:** *Beyond Fear* ch. 3 notes (players, agendas, proxies).

### 1.15 Cryptography is the easy part
- **Idea:** Good algorithms already exist. Failures come from implementation, key management, protocol misuse and human interfaces. Strong and weak crypto look the same on the shelf. Crypto bolted on afterwards doesn't work.
- **Why it works:** Attackers go around the math, through replay, malleability, bad randomness, key handling and missing domain separation.
- **Auditor move:** For signatures and hashes, check how they're used, not just which algorithm: replay across chains/contracts/forks (chainId, nonce, verifying contract, deadline), `ecrecover` returning zero, signature malleability, abi.encodePacked collisions, on-chain "randomness", commit-reveal timing, permit front-running. Never accept "it uses keccak/ECDSA" as an argument.
- **Source:** "Why Cryptography Is Harder Than It Looks" (1997); "Attack Trees" (1999) PGP example.

### 1.16 Attackers cheat
- **Idea:** Attackers don't follow the rules the defender imagined. They come through the wall, not the door. They use technology newer than the system. Defenders must guard everything; the attacker needs one flaw.
- **Why it works:** Threat models fail at their edges: the attacker who brings a flash loan, a malicious token, a contract that pretends to be a wallet, or a validator.
- **Auditor move:** At the end of each pass, ask what an attacker would do *outside* the model you just used: different token behaviour, a contract caller, the same block, the same transaction, a different chain, cross-function or read-only reentrancy, donation, griefing at a cost to themselves.
- **Source:** "Why Cryptography Is Harder Than It Looks" (1997); *Beyond Fear* ch. 6 notes.

---

## 2. Beyond Fear five-step process, adapted to code audits

In *Beyond Fear* (2003), Schneier evaluates any security measure with five questions, followed by an overall judgement: is it worth it? The questions don't hand you the answer. They're a way to judge a proposed answer. Below, each step is restated for an audit. Run it **twice**: once on the protocol as a whole ("is this design secure enough for what it holds?") and once on each security mechanism or proposed fix ("does this control or patch actually help?").

| Step | Schneier's question (paraphrased) | Audit version | Concrete outputs |
|---|---|---|---|
| 1 | What are you protecting? Define scope; securing a plane differs from securing aviation. | **Assets and scope.** What value and what properties are at stake? | List: token balances by contract; LP shares; collateral; protocol-owned liquidity; fee streams; governance power; admin/upgrade rights; oracle integrity; liveness (ability to withdraw); user approvals granted to the protocol. Mark where each lives and who can move it. |
| 2 | What are the risks to them? Who would attack, how, why, and what if they succeed? | **Threat model.** Attackers × goals × consequences. | Attacker profiles (§1.4); attack goals (each becomes an attack-tree root, §3); worst-case loss per goal; the protocol's own stated trust assumptions, written out. |
| 3 | How well does the countermeasure reduce those risks, including how it interacts with everything around it and how it fails? | **Control effectiveness.** For each check/guard/invariant: does it stop the attack it's meant for, in every path and state? | Map each attack-tree leaf to the controls that block it. For each control: bypasses, edge cases (0, max, first deposit, last withdrawal), behaviour when dependencies fail, and whether it enforces the letter or the intent. |
| 4 | What new risks does the countermeasure create? Unintended effects; the new problems must be smaller than the old. | **Second-order risk.** What can the defence itself be used for? | Pause that freezes users' exit; blacklist that can be griefed; slippage check that enables DoS; timelock that delays emergency fixes; reentrancy guard that blocks legitimate composability; upgradeability that adds an admin-key attack path; oracle circuit breaker that can be tripped on purpose. |
| 5 | What does it cost and what does it trade away (money, convenience, freedom)? | **Trade-offs.** Gas, UX, decentralisation, liveness, upgrade flexibility, composability. | For each recommended fix, the cost and what it gives up, so the team can decide. Skip fixes whose cost is higher than the risk they remove. |
| ⇒ | Is the benefit (step 3) worth the new risk (4) plus the cost (5)? | **Verdict per control and per fix.** | Keep / strengthen / replace / remove. Report controls that cost something and protect nothing as security theater (§6). |

Notes to apply:
- Schneier stresses that security trade-offs are subjective and depend on each player's agenda. Write down whose risk tolerance a fix serves (users vs team vs LPs).
- Step 3 is "frequently ignored", in his words. Most audit value is here: actually trace whether the guard covers every path to the asset.
- Step 4 is where defence mechanisms become new attack surface. Always check what an attacker can do *with* your fix.

---

## 3. Attack trees: how to build and use them

### 3.1 The method (from "Attack Trees", Dr. Dobb's, 1999)
1. **One tree per attacker goal.** The goal is the root. A system has several goals (read the message, forge a signature, alter a message…), and trees can share subtrees.
2. **Decompose.** Each child is a way to reach its parent. **OR** nodes are alternatives. **AND** nodes are steps that must *all* succeed.
3. **Iterate and recruit.** Brainstorm every attack against each node and recurse. Then hand the tree to someone else to add what you missed, and repeat, possibly over months. Expect to have forgotten something.
4. **Give the leaves values.** Boolean (possible/impossible, needs special equipment, legal/illegal, intrusive) or continuous (cost, probability, skill, detectability).
5. **Propagate up.** OR node = best (e.g., cheapest) child. AND node = combination (e.g., sum of costs; all must be possible).
6. **Query the tree.** Cheapest attack; cheapest without special equipment; cheapest low-risk attack; all attacks under budget X. Attacks cheaper than the value of the asset are the ones that matter.
7. **Pair it with attacker profiles.** The attacker's traits decide which branches are live (illegal attacks, willingness to lose money or be caught).
8. **Run what-ifs.** Apply a countermeasure, recompute, and see whether the root value really moved, or whether the cheapest path just shifted elsewhere (as in his safe example, where raising the bribe cost moved the cheapest attack to a different branch).
9. **Reuse.** A finished tree for a component (an ERC-4626 vault, a TWAP oracle, a Governor) becomes a subtree in larger systems. You only need its root value.
10. **Read off the assumptions.** The tree's leaves marked "impossible" *are* the system's security assumptions. List them explicitly.

His main lesson from building them: the parts people worry about (key length) usually aren't where the system is weak. The tree shows the whole system.

### 3.2 Agent procedure
- Write trees as nested outlines (as he did for PGP), not diagrams.
- Mark each node `[OR]`/`[AND]` and each leaf with: preconditions, attacker profile, capital needed (incl. flash-loanable), cost/gas, detection likelihood, and the code location that blocks or allows it.
- Use `BLOCKED by <file:line control>`, `OPEN`, or `UNKNOWN → needs PoC`.
- Every `OPEN` path whose cost is lower than the value at risk becomes a candidate finding. Every `UNKNOWN` becomes a fuzz/PoC task.
- Re-run the tree after each proposed fix (step 8) and check whether the cheapest path just moved.

### 3.3 Short DeFi example: lending market

```
ROOT: Drain more collateral than deposited from LendingPool          [OR]
├─ 1. Borrow against inflated collateral value                       [OR]
│   ├─ 1.1 Manipulate spot price oracle                              [AND]
│   │   ├─ 1.1.1 Pool uses spot AMM price (not TWAP/Chainlink)       → check Oracle.getPrice()
│   │   ├─ 1.1.2 Obtain capital to move price                         → flash loan: cost ≈ fee + slippage
│   │   └─ 1.1.3 Borrow + exit in same tx before price reverts        → is there a same-block guard?
│   ├─ 1.2 Inflate collateral token's share price (ERC-4626 donation) [AND]
│   │   ├─ 1.2.1 Collateral is a vault share priced via totalAssets()
│   │   └─ 1.2.2 Donate assets directly to vault to raise rate
│   └─ 1.3 Oracle stale/zero/decimals mismatch accepted               → staleness + bounds checks?
├─ 2. Avoid repaying / liquidation                                    [OR]
│   ├─ 2.1 Make liquidation revert (blacklisted token, reverting hook, gas grief)
│   ├─ 2.2 Liquidation unprofitable for keepers (bonus < gas+slippage at small positions) → dust bad debt
│   └─ 2.3 Self-liquidate at a profit via bonus > penalty
├─ 3. Accounting error                                                [OR]
│   ├─ 3.1 Rounding in borrower's favour on borrow/repay shares
│   ├─ 3.2 First-depositor share inflation in empty market
│   └─ 3.3 Reentrancy via token callback before debt is recorded      [AND: ERC-777/hooks supported, state updated after transfer]
└─ 4. Abuse privileged path                                           [OR]
    ├─ 4.1 Compromised admin lists malicious collateral / sets LTV 100%  [AND: key compromise; no timelock]
    ├─ 4.2 Unprotected initialize() on implementation/proxy
    └─ 4.3 Governance takeover (see §4) → set oracle to attacker contract
```
Queries to run: cheapest path for an unprivileged flash-loan attacker (usually 1.1 or 1.2); cheapest path needing no capital (3.x, 4.2); paths not visible on-chain before execution (detectability, §1.9). Then for each fix (e.g., "switch to TWAP"), recompute: does the cheapest path move to 1.2 or 2.2?

---

## 4. *A Hacker's Mind*: hacks, loopholes, protocol logic and governance

### 4.1 Core ideas (paraphrased)
- **Definition.** A hack is something a system *permits* but its designers didn't intend or foresee. It follows the rules while subverting their goal, usually to the hacker's benefit and at someone else's expense. Cheating breaks rules. Hacking exploits what the rules leave out or contradict.
- **Every rule system can be hacked.** Rule sets are always incomplete, inconsistent or ambiguous, and they go out of date as the world changes. Wherever there are rules and people who want an edge, there are hacks. His example is the 1975 six-wheeled Formula 1 car: the rulebook simply said nothing about the number of wheels.
- **Lifecycle.** A hack is found, used, spreads, gets noticed by whoever governs the system, and is then either **patched** (banned or made impossible) or **normalised** (absorbed as the new rule). Hacking is also how systems evolve.
- **The powerful hack best.** Those with money and expertise find more hacks, use them better, and are more likely to get them normalised because they can influence the rule-makers.
- **Who adjudicates.** A single governing body (F1, a vendor) can patch quickly. Without one, slower mechanisms like courts decide. Patch speed matters. Computer systems patch in weeks, social systems in years.
- **AI as hacker.** AIs will find hacks in rule systems (tax code, regulations, code) at a speed and scale our patching processes aren't built for.

### 4.2 Applied to protocol logic
Treat the protocol's rules (docs, invariants, tokenomics, governance constitution) as a rulebook and look for *six-wheeled cars*:
1. **Find what the rules don't say.** List what the spec doesn't constrain: number of positions per address, same-block open/close, zero-value actions, self-referential actions (deposit to self, vote for own proposal, liquidate self), contracts as users, tokens with non-standard behaviour (fee-on-transfer, rebasing, hooks, multiple addresses, 0 decimals/high decimals), ordering between functions, cross-chain replay. Each one is a candidate hack.
2. **Check intent vs letter for each reward.** For each thing the protocol rewards (liquidity mining, points, fee rebates, liquidation bonus, voting weight, referral), ask what the cheapest way to *earn* it is without providing the intended service: wash trading, self-referral, flash-staked snapshots, recursive deposit/borrow loops, Sybil splitting, JIT liquidity that collects fees without bearing risk.
3. **Look for contradictions.** Hunt for two rules that conflict (e.g., the pause rule vs the "withdrawals always possible" promise; the cap rule vs the rebasing balance). The gap between conflicting rules is where hacks live.
4. **Watch for rules that age.** Parameters set for current market conditions (LTVs, caps, oracle heartbeats, fee tiers) become hacks when conditions change. Check behaviour at extremes and after long idle periods.
5. **Think about scale and automation.** Assume the attacker is a bot that can try every ordering and every pool at once. A hack that's "unprofitable by hand" may pay off when automated across N markets (class break, §1.11).

### 4.3 Applied to governance
- **Governance is a rule system and gets hacked like one.** Borrowed or flash-loaned voting power without snapshot protection; buying votes through bribe markets; low-quorum timing (proposals during holidays or right after a token unlock); proposal bundling (hiding a malicious action in a large benign batch); delegation tricks; making a proposal un-executable through griefing; emergency powers ("ox walking" or filibuster equivalents) used to block legitimate changes.
- **Ask who can turn a hack into the rules.** If one actor can capture governance, they can *normalise* their hack by voting it into the rules, the move Schneier says the powerful make. Check whether any coalition below X% of supply can change oracle, collateral, fees or treasury destination, and how long the timelock gives others to react or leave.
- **Adjudication and patch speed.** Who can declare a behaviour an exploit vs a feature, and how fast can they patch it (guardian, timelock, upgrade)? A slow patch path combined with an automatable hack is a high-severity combination.

---

## 5. *Liars and Outliers*: incentives, defectors, trust — applied to tokenomics and privileged roles

### 5.1 Core model (paraphrased)
- **Every cooperative system contains parasites.** Each participant keeps choosing between cooperating (group interest) and defecting (self-interest at the group's expense). The core metaphor is the Prisoner's Dilemma. Too many defectors and the system collapses, often catastrophically.
- **Four societal pressures limit defection:** **moral** (internal), **reputational** (what others think and how they'll treat you), **institutional** (formal rules: laws, contracts, bylaws), and **security systems** (technology that constrains or detects behaviour). The first two are informal and don't scale. The last two scale to strangers, and security systems can make defection impossible rather than just costly.
- **Defection never reaches zero.** The aim is to keep it tolerable, not eliminate it.
- **Technology raises the damage one defector can do.** A few overfishing fishermen are survivable until one of them has a driftnet. Scale changes the maths.
- **Not all defectors are bad.** Defection is measured against the norm, and some defectors push for necessary change. Too much pressure causes stagnation.
- **Two kinds of trust** (refined in "AI and Trust", 2023): *interpersonal* trust (in someone's intentions; based on morals and reputation) and *social* trust (in predictable behaviour, enforced by laws and technology). Social trust scales to strangers but has to be rigid and blind to context. People confuse the two, and services exploit that confusion.

### 5.2 Applied to tokenomics
- **Write the dilemma down.** For each mechanism, list the cooperate and defect actions and their payoffs: LP stays vs pulls before a known loss; voter votes for long-term health vs for their own bribe; keeper reports truthfully vs the profitable lie; staker stays vs front-runs a slash; liquidator liquidates now vs waits for a bigger bonus.
- **Is defection ever the dominant strategy?** If it pays more than cooperating at any reachable state (bank-run dynamics, first-withdrawer-wins, emissions dumped before a cliff), assume it *will* happen. The rational defector is your attacker.
- **Name which pressure holds each actor in line.** Moral and reputational pressure is weak or absent for pseudonymous on-chain actors. If a mechanism only works because "LPs won't do that" or "the team wouldn't", it has no real enforcement. Push the enforcement into security systems (code-level constraints) or institutional pressure (bonds, slashing, legal entity, timelocks) where the stakes justify it.
- **Check that enforcement scales with the damage one actor can do.** Flash loans, recursive leverage and composability are the driftnet. A defection that is harmless at retail size can drain the system at flash-loan size. Size penalties (slashing, bonds, fees) against the *maximum* single-actor gain, not the typical one.
- **Leave room for legitimate outliers.** Over-tight controls (allowlists, aggressive blacklists, censorable pause) block the users the system exists for, and are a trust risk in their own right.

### 5.3 Applied to privileged roles
- **Every admin, multisig, oracle reporter, keeper, sequencer, bridge validator and upgrader is a trusted party.** For each, ask which of the four pressures holds them in check:
  - *Moral/reputational:* is the team doxxed and does reputation cost them anything? (Weak and doesn't scale; treat as zero for adversarial analysis.)
  - *Institutional:* legal entity, contracts, governance able to remove them, bonding/slashing.
  - *Security systems:* timelock, threshold signatures, role separation, caps on what any role can move per period, immutable invariants the role can't override, on-chain monitoring.
- **Don't mistake interpersonal trust for social trust.** "We trust the team" is interpersonal trust. A user base of strangers needs *social* trust: behaviour that is predictable and constrained by code and rules. Report any place where user safety depends on the team's intentions rather than enforced limits, and name the worst-case action each role can take today.
- **Plan for the role turning hostile.** Assume the key is stolen, coerced or turned (Schneier's pilot example: trusted people do sometimes defect). Compute the maximum loss if each role acts maliciously, and how much warning users get (timelock length vs withdrawal time).

---

## 6. Anti-patterns he warns about

| Anti-pattern | What it is (paraphrased) | Audit symptom | Correction |
|---|---|---|---|
| **Security theater** | Measures that make people *feel* safer without making them safer: photo-ID checks that verify nothing, guards with unloaded guns. Security is both a feeling and a reality, and the two can diverge. | Checks that look protective but guard nothing: `require(msg.sender == tx.origin)` sold as anti-bot; a pause no one monitors; a "multisig" with signers on one device; a timelock admin that can bypass the timelock; audits as marketing badges; KYC on a front-end while contracts stay open. | Run Beyond Fear step 3: trace whether the control blocks a real attack-tree path. If not, call it theater and say what would actually work. |
| **Movie-plot threats** | Defending against vivid, specific scenarios (the *last* attack) instead of the broad threat. It only helps if you guess the next plot correctly, and it pushes attackers to the undefended target. Better: general capabilities (intelligence, investigation, emergency response) that work whatever the plot. | Fixing exactly the last famous exploit (one reentrancy guard on one function; blocklisting one known attacker address; one hardcoded check for one token) while sibling paths stay open. Long lists of named exploits with no root-cause analysis. | Generalise every finding to its *class* and root cause. Favour plot-independent defences: invariants, caps and rate limits, monitoring + pause, isolation, recovery paths. |
| **Checklist thinking** | Security comes from the process of failing and fixing, not from a specific checklist. Compliance checklists reward *features delivered when everything works*, which is "exactly backward". | "Passes Slither, has NatSpec, uses OpenZeppelin, follows SWC list" presented as proof of safety. Audit scope limited to listed contracts. | Use checklists only to seed attack trees. Judge by adversarial analysis of *this* system's goals and failure modes. |
| **Cryptography (or any primitive) as magic** | Treating strong crypto as making the system secure. Algorithms are the easy part. Implementation, key management, protocol use and humans are where it breaks. In PGP, breaking the cipher is the least attractive attack. | "Uses ECDSA/Merkle proofs/ZK so it's secure." "Audited by X so it's safe." "Upgradeable via Gnosis Safe so admin risk is solved." | Attack around the primitive: replay, malleability, domain separation, leaf/node confusion in Merkle trees, verifier-key management, who holds the keys. |
| **Secrecy as security** | Depending on hidden details. Secrets that are global and hard to change are brittle, and secret knowledge is always in the bad guys' hands. | Unverified contracts, closed-source off-chain components, "the attacker won't know the private mempool route / admin address". | Assume the attacker has full knowledge of code and config (bytecode is public). Rely only on secrets that are small, local and easy to rotate (keys). |
| **Overreacting to the feeling of security** | Knee-jerk responses to the latest news that impose cost without reducing risk. | Emergency patches that add new admin powers or pausability without the step-4 (new risks) analysis. | Run all five steps on every proposed fix. |
| **Ignoring the human in the loop** | Every system has trusted people, and social engineering works. | No analysis of signer opsec, front-end/DNS takeover, phishing approvals, deployer key handling. | Include operational and human attack branches in the tree. |
| **Brittleness for efficiency** | Markets reward lean, deeply integrated systems with no redundancy. That pays only while everything works, and when they fail they fail badly. | Single oracle, single bridge, single keeper, single sequencer assumptions; no fallback; one upgrade bricks everything. | Recommend redundancy, fallback, isolation and tested failure modes. |

---

## 7. What makes him efficient: habits an agent can copy

1. **Ask "who benefits?" and "who pays?" first.** He keeps reducing problems to incentives and externalities before looking at mechanics. Run this before reading code line by line: it tells you where the attacker's motive is.
2. **Simplify to the essential system.** He breaks complex situations into a few questions (five steps) or a tree. Start each audit with a one-page model: assets, actors, trust boundaries, value flows. Simplicity is also his top recommendation.
3. **Look at the whole system, then the cheapest path.** He moved from crypto to networks to people to economics to society because the real weaknesses kept sitting one level above where he'd been looking. Zoom out at least one level beyond the scope you were given.
4. **Rank by cost to the attacker.** Attack trees with propagated costs tell him where to spend effort. Don't spend effort on expensive attacks while cheap ones exist.
5. **Think about failure as a design input.** For him "how does it fail?" comes first, not as an afterthought. For every component, write down its failure mode and whether it fails open or closed.
6. **Generalise from examples.** He collects odd real-world cases (ants by mail, rabbits thrown over Soviet fences to wear down alarms, six-wheeled cars) and pulls a pattern out of each. Turn every bug into a *class*, then search for the class across the codebase.
7. **Distrust your own confidence.** Schneier's Law applies to the auditor too. Get a second adversarial pass, preferably with a different framing or a fresh agent context. Absence of findings is not evidence.
8. **Keep the attacker's options open.** He keeps asking what the attacker would do *instead*: cheat, go around, wait, attack the response team (his example: a bomb threat to empty a security operations center). After every defence you check, ask "and around it?"
9. **Calibrate risk; ignore hype.** He separates feeling from reality and rare-but-vivid from common-but-dull. Severity should come from likelihood × impact for named attackers, not from how dramatic the exploit story is.
10. **Value detection and response.** He never treats prevention as enough. Always include "how would they notice, and what could they do?" in the assessment.
11. **Make the assumptions explicit.** The tree's "impossible" leaves and the list of trusted parties *are* the security argument. Write them down so they can be challenged.
12. **Explain plainly.** He's known for explaining security in non-specialist language. A finding the team can't understand won't get fixed. State the attack as a short story: who, what they do, what they get, what it costs them.

---

## 8. Prompt core: imperative rules (paste into the agent's system prompt / SKILL.md)

> **Think like Schneier while you audit.**
> 1. **Name the assets and the attackers before reading code.** For each asset, record who could want it (unprivileged flash-loan user, MEV/builder, whale, malicious token/hook, compromised admin, governance attacker, oracle/bridge operator) and what they could get.
> 2. **Build an attack tree per attacker goal.** Use OR/AND nodes, decompose until each leaf maps to code, and mark each leaf BLOCKED (file:line), OPEN, or UNKNOWN→PoC.
> 3. **Rank paths by cheapest total cost to the attacker.** Go deep on the cheapest viable paths first; the system is only as strong as its cheapest path.
> 4. **For every check, write down what it is *for*, then try to satisfy the letter while breaking the intent.** Try zero, max, first/last, same block, same transaction, self-referential, contract callers, non-standard tokens.
> 5. **Look for what the rules don't say.** List every unconstrained dimension in the spec (counts, ordering, token behaviour, caller type, chain) and treat each as a candidate hack.
> 6. **Follow the incentives.** For every actor, compute payoffs for cooperating vs defecting at every reachable state; if defection ever wins, assume it happens, including at flash-loan scale.
> 7. **List every trusted party and its worst case.** For each privileged role, state its maximum damage if it turns hostile, the pressure that restrains it (code limits, timelock, threshold, bond), and the warning users get.
> 8. **Ask how each dependency fails.** For every oracle, token, bridge, keeper, sequencer and callback: stale, zero, extreme, reverting, paused, malicious. Report fail-open and single-point-of-total-loss designs.
> 9. **Look past the component in scope.** Check proxies, initializers, upgrade paths, deploy config, integrations, off-chain signers and the seams between well-guarded parts.
> 10. **Judge every control and every fix with the five steps.** What does it protect, against what, how well (all paths, all states, when it fails), what new risk does it create, what does it cost, and is it worth it?
> 11. **Call out security theater and movie-plot fixes.** If a control blocks no real attack path, say so; generalise each finding to its root-cause class and search the codebase for siblings.
> 12. **Never accept a primitive, a library, a checklist or a past audit as proof.** Attack how it is used: replay, domain separation, malleability, key custody, misuse.
> 13. **Assess detection and response.** Check whether an attack in progress would be visible, who can pause or limit it and how fast, and whether funds stay recoverable. Missing response capacity is a finding.
> 14. **Distrust your own "no findings".** Run a second adversarial pass with a different framing; new or home-made mechanisms get extra scrutiny because their designers could not break them either.
> 15. **Write each finding as a short attack story:** attacker, preconditions, steps, gain, cost, detectability, and the simplest fix, preferring removal of complexity over adding mechanisms.

---

## 9. Sources (all opened on 2026-10-25 unless marked)

**Primary: Schneier's own text (fetched and read)**
- The Security Mindset (Wired/blog, 2008): https://www.schneier.com/blog/archives/2008/03/the_security_mi_1.html
- Attack Trees (Dr. Dobb's Journal, Dec 1999): https://www.schneier.com/academic/archives/1999/12/attack_trees.html
- "Schneier's Law" (blog, 2011; quotes 1998 and 2006 originals): https://www.schneier.com/blog/archives/2011/04/schneiers_law.html
- Terrorists Don't Do Movie Plots (Wired, 2005): https://www.schneier.com/essays/archives/2005/09/terrorists_dont_do_m.html
- Beyond Security Theater (New Internationalist, 2009): https://www.schneier.com/essays/archives/2009/11/beyond_security_thea.html
- A Plea for Simplicity (Information Security, 1999): https://www.schneier.com/essays/archives/1999/11/a_plea_for_simplicit.html
- The Process of Security (Information Security, 2000): https://www.schneier.com/essays/archives/2000/04/the_process_of_secur.html
- Why Cryptography Is Harder Than It Looks (1997): https://www.schneier.com/essays/archives/1997/01/why_cryptography_is.html
- Information Security and Externalities (ENISA Quarterly, 2007): https://www.schneier.com/essays/archives/2007/01/information_security_1.html
- Economics of Information Security (Anderson & Schneier, IEEE S&P 2005, abstract page): https://www.schneier.com/academic/archives/2005/01/economics_of_informa.html
- The Future of Incident Response (blog, 2014): https://www.schneier.com/blog/archives/2014/11/the_future_of_i.html
- The CrowdStrike Outage and Market-Driven Brittleness (Raghavan & Schneier, Lawfare, 2024): https://www.schneier.com/essays/archives/2024/07/the-crowdstrike-outage-and-market-driven-brittleness.html
- AI and Trust (Belfer Center, 2023): https://www.schneier.com/essays/archives/2023/12/ai-and-trust.html
- Liars and Outliers: The Big Idea (blog/Whatever, 2012): https://www.schneier.com/blog/archives/2012/03/liars_and_outli_5.html
- Book Bite: A Hacker's Mind (Next Big Idea Club, 2023): https://www.schneier.com/talks/archives/2023/03/book-bite-a-hackers-mind.html

**Book pages and interviews (fetched)**
- Beyond Fear book page: https://www.schneier.com/books/beyond-fear/
- A Hacker's Mind book page: https://www.schneier.com/books/a-hackers-mind/
- Liars and Outliers book page: https://www.schneier.com/books/liars-and-outliers/
- Secrets & Lies book page: https://www.schneier.com/books/secrets-and-lies/
- Applied Cryptography book page: https://www.schneier.com/books/applied-cryptography/
- Data and Goliath book page: https://www.schneier.com/books/data-and-goliath/
- Click Here to Kill Everybody book page: https://www.schneier.com/books/click-here/
- Hacking to Harm and Heal Democracy (Ash Center interview, 2023): https://www.schneier.com/news/archives/2023/01/hacking-to-harm-and-heal-democracy.html
- Bruce Schneier: The Evolution of a Cryptographer (CSO interview, 2003): https://www.schneier.com/news/archives/2003/09/bruce_schneier_the_e.html

**Secondary summaries (fetched; used for *Beyond Fear* chapter content)**
- Harvard Cybersecurity Wiki, Beyond Fear (quotes the five-step passage at length): https://cyber.harvard.edu/cybersecurity/Beyond_Fear
- Scott Granneman, chapter notes on Beyond Fear: https://www.granneman.com/personal/commonplacebook/security/bruceschneiersbeyondfear

**Seen only as search excerpts (not fetched; supporting, not relied on alone)**
- Springer chapter abstract "Brittleness Makes for Bad Security": https://link.springer.com/chapter/10.1007/0-387-21712-6_9
- Eliminating Externalities in Financial Security (blog, 2009): https://www.schneier.com/blog/archives/2009/09/eliminating_the.html
- Co3 Systems → Resilient Systems (blog, 2015, resilience quote): https://www.schneier.com/blog/archives/2015/02/co3_systems_cha.html

**Gaps, stated plainly**
- I didn't read the full text of *Applied Cryptography*, *Secrets and Lies*, *Data and Goliath* or *Click Here to Kill Everybody*. Only their official book pages were opened (the Secrets & Lies preface URL I tried returned 404). The principles credited to those books here come from his essays, which overlap heavily: process over product, crypto as the easy part, externalities, brittleness.
- *Beyond Fear* chapter-level details (§1.9–1.12) rely on a reader's chapter notes plus the Springer abstract, not the book itself. The five-step wording is verified against the long excerpt on the Harvard wiki.
- *A Hacker's Mind* and *Liars and Outliers* content comes from Schneier's own summaries (Book Bite, Big Idea essay, interviews), not the full books.
- The DeFi applications throughout are my adaptation. They are not Schneier's claims.
