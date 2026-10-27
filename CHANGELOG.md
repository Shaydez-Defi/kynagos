# Changelog

## 1.1 — 2026-10-27
- Liveness gate (`mind/LIVENESS.md`): rule 3a "No liveness, no CONFIRMED". Hunters must prove the
  code is in scope, current, reachable, and not deprecated, removed, unused, undeployed, test or
  mock code before hunting it, and again before confirming a finding.
- New tools: `step0_liveness_repo.sh`, `step0_liveness_onchain.sh` (EIP-1967 resolution and
  bytecode match), `humanize_check.py`. All covered by `selftest.sh`.
- `report-schema.json` / `validate-findings.cjs`: confirmed findings require a `liveness` block with
  `target_version` and at least two different proof methods. New test; 66/66 passing.
- Gates and tiers (`mind/GATES.md`, adapted from SureForge, MIT): Light / Standard / Full,
  READY / REPAIR / BLOCKED, independent review with different methods, three rounds max, silence is
  never approval, no sampling as coverage, no laundering of old evidence.
- Human voice (`mind/VOICE.md`) for PoCs, reports and disclosure DMs; rule 9 "Sound human".
- P10 Retro (`mind/RETRO.md`) with a LESSONS.md loop, and `tools/skill_doctor.sh`.
- Script permissions fixed for module scripts that were not executable.

## 1.0
- Initial release: orchestrator, Schneier mind, seven lenses, lifecycle P0–P9, bundled modules.
