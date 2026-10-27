# Lenses — how Kynagos reads code more than once

A single read finds what the reader expects. Each pass below wears one adversary's eyes and asks
only that adversary's questions. Every critical unit gets at least three lenses; value-moving code
gets all seven. Record the lenses used per unit in the coverage ledger.

## 1. Thief — "How do I leave with more than I brought?"
- Where does value leave the system? List every transfer, mint, burn, withdraw, claim, redeem.
- For each exit: what proves I am entitled? Can I inflate that proof (balance, shares, snapshot,
  signature, merkle leaf, oracle price) for one block, one call, or one rounding step?
- Can I pay in one unit and be paid in another (decimals, fee-on-transfer, rebasing, wrapped)?
- Can I borrow the proof (flash loan, donation, callback) and return it after being credited?

## 2. Griefer — "What breaks for everyone if I spend a little?"
- Can I freeze funds, brick a function, block a queue, force a revert in someone else's path?
- Unbounded loops, dust positions, forced ETH, tokens that revert on transfer, blacklist tokens,
  first-depositor states, self-destruct leftovers, gas-griefing callbacks.
- Grief is real impact but is not EXTRACT. Rate it as such.

## 3. Insider — "What can a role do, staying inside its powers?"
- Owner, admin, keeper, oracle, relayer, guardian, multisig signer, strategy manager.
- What does each role gain by acting against users without breaking any rule?
- Can a role change parameters under live positions (oracle, fees, migrator, implementation)?
- Can an unprivileged actor become or impersonate a role (init, proxy, msg.sender via forwarder)?
- Label the result: trust/centralisation finding or permissionless exploit.

## 4. Neighbor — "I control something this code trusts."
- A token, an oracle, a pool, a bridge message, a callback receiver, an integrating vault, a hook.
- What does the code assume about my return values, my revert behaviour, my reentrancy, my
  decimals, my supply, my timing?
- What if I return a lie that passes every check?

## 5. Time-traveler — "What if I change the order?"
- Reentrancy (single, cross-function, cross-contract, read-only).
- Same-block sequences, front-running, back-running, sandwiching the protocol's own swaps.
- Two-phase flows (request → finalize), epochs, vesting, unlocks, snapshots, cooldowns.
- Upgrades and migrations: what state exists half-way through?
- Check-then-act: satisfy a check, then change its meaning before settlement.

## 6. Accountant — "Do the books always balance?"
- Write the conservation law: sum of claims == assets (+/- fees). Find every write that changes
  one side without the other.
- Rounding direction on every division; who wins each rounding; what N repeated calls drift to.
- Recorded balance vs actual balance; principal vs NAV vs cash; shares vs assets.
- Two contracts with their own copy of the same number: can they disagree?

## 7. Lawyer — "What does the rule say, and what does it actually check?"
- (Schneier, A Hacker's Mind) Every check encodes an intent. Write the intent in one line, then
  write what the code literally enforces. The gap between them is a loophole.
- Inputs the rule never imagined: zero, max, self, the contract itself, an empty array, a duplicate
  entry, an address with no code.
- Rules that are enforced on one path but not its sibling (deposit vs merge, mint vs mintFor).

## Pass protocol
1. Pick the unit from the ledger with the most value at stake and the fewest lenses so far.
2. Hunter gets: the unit, its callers and callees, the threat model, and ONE lens. Nothing else.
3. Hunter writes candidates as `WITNESS: <falsifiable assert>` + reach path + precondition list.
4. Coverage critic reads the ledger after each round and names the gap. Next round aims there.
5. Every "would be bad if X" note becomes a Ragnarok contradiction card in P4.
