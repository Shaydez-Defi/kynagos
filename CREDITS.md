# Credits and licenses

Kynagos (SKILL.md, mind/LENSES.md, mind/SCHNEIER.md, mind/LIVENESS.md, mind/VOICE.md,
mind/RETRO.md, the lifecycle and depth rules, the liveness and humanize tools, and tools/skill_doctor.sh)
is written by Shaydez. It orchestrates the open-source modules below, which are included under their own licenses.
Their copyright notices must stay with them; the full license texts are in `licenses/`.

| Module | Upstream | Copyright | License |
| :--- | :--- | :--- | :--- |
| modules/pipeline | github.com/cloudflare/security-audit-skill | Cloudflare, Inc. | MIT |
| modules/xray, modules/solidity-auditor, modules/fizz | github.com/pashov/skills | AI Skills Contributors (Pashov Audit Group) | MIT |
| modules/ragnarok | github.com/Godwin-web3/ragnarok | GodwinXbt | MIT |
| modules/kensho | github.com/cryptoduke01/kensho | Duke (@dukedotsol) | CC BY 4.0 — attribution required |
| modules/bughunt | github.com/devIykee/iykes-evm-bughunt-skill | Iyke / deviykee (researcher identity in templates changed to Shaydez) | MIT |
| mind/GATES.md (adapted, rewritten for audits) | github.com/Da7-Tech/SureForge | Da7-Tech | MIT |
| modules/precedent | github.com/marchev/claudit (companion skill; MCP server installed separately) | Martin Marchev | MIT |

Changes made: module `name:` fields renamed to `kynagos-*`; researcher identity in the bughunt
templates changed to Shaydez; upstream version checks disabled by the orchestrator. In 1.1: the pipeline findings schema,
validator and tests gained a required `liveness` block on confirmed findings; the bughunt tools gained
the step0 liveness scripts and humanize_check.py, and its selftest covers them.

mind/SCHNEIER.md paraphrases ideas from Bruce Schneier's public essays and books in original words,
with sources listed. It is not endorsed by him.
