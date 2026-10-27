# Kynagos

Kynagos, by Shaydez, is an adversarial security-audit skill for coding agents (Claude Code, Codex, Cursor and similar).
It thinks like an attacker, proves the code is live before hunting it, reads every critical path
through several lenses, invents impossible states, proves every finding on a fork, kills its own
findings through gated independent review, and writes PoCs and reports that read like a person wrote them.

## What's new in 1.1
- **Liveness gate.** No finding is confirmed unless the vulnerable code is proven live: in scope,
  current, reachable, and not deprecated, unused, undeployed, test or mock code. Two tools check it,
  and `findings.json` rejects a confirmed finding without two different liveness proofs.
- **Gates and tiers.** Light / Standard / Full, READY / REPAIR / BLOCKED, independent review with
  different methods, three review rounds max, silence is never approval (adapted from SureForge).
- **Human voice.** Rules for PoCs, reports and disclosure DMs, plus `humanize_check.py` to catch
  machine-written tells before anything ships.
- **Retro and skill doctor.** A lessons loop after every hunt, and `tools/skill_doctor.sh` to check
  the skill itself before publishing.

## Install
Copy this folder into your agent's skills directory, e.g. `~/.claude/skills/kynagos`.

Optional precedent search (Solodit, needs a free API key from solodit.cyfrin.io):
```
claude mcp add --scope user --transport stdio solodit \
  --env SOLODIT_API_KEY=sk_your_key_here -- npx -y @marchev/claudit@latest
```

Tooling used by the modules: Foundry (`forge`, `cast`, `anvil`), Node.js, Python 3, and optionally
Echidna / Medusa, Heimdall, Mythril.

## Use
```
run kynagos on this codebase
kynagos: hunt this bounty <url>
kynagos x-ray this protocol
kynagos fuzz the vault
```

## Layout
- `SKILL.md` — the orchestrator: rules, modes, lifecycle P0–P9, depth rules.
- `mind/SCHNEIER.md` — how Bruce Schneier thinks, turned into audit rules.
- `mind/LENSES.md` — the seven adversary lenses and the multi-pass protocol.
- `mind/LIVENESS.md` — proving the code is live before hunting or confirming anything.
- `mind/GATES.md` — tiers, gates, independent review and honest delivery.
- `mind/VOICE.md` — PoCs, reports and DMs that read like a human researcher wrote them.
- `mind/RETRO.md` — the lessons loop after every hunt.
- `tools/skill_doctor.sh` — health check for the skill itself.
- `modules/` — pipeline, xray, solidity-auditor, fizz, ragnarok, kensho, bughunt, precedent.
- `CREDITS.md`, `licenses/` — upstream credits; keep them when you share or publish.

Rules: authorized scope only, live code only, fork-only proof, honest severity, private until patched.

Check the skill after any change: `bash tools/skill_doctor.sh`
