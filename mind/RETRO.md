# RETRO — get sharper after every hunt

P10 of the lifecycle. Run after every hunt that produced a report, a rejection,
or a dead end. Ten minutes, written down, or it did not happen.

## Write `retro.md` in the run folder

1. **What shipped.** Findings by verdict, with target version.
2. **What was wrong.** Every candidate that died, and *why it died*: not live
   (deprecated, unused, not deployed, test code), known issue, out of scope,
   blocked by another layer, no real profit, bad severity. The "why" matters
   more than the count.
3. **What the triager said.** Accepted, downgraded, duplicate, closed as
   informational, invalid. Quote the reason.
4. **What cost the most time for the least.** The lens, module or rabbit hole.
5. **One rule to add.** A specific check that would have caught the mistake
   earlier ("run step0_liveness_repo.sh before reading any file under
   `periphery/`"). Not a vague lesson.

## Feed it back

- Append the one rule to `~/kynagos-audits/LESSONS.md` (outside the skill, so
  updates to the skill do not wipe it). Read LESSONS.md at P0 of every run.
- If the same lesson shows up in three retros, propose a change to SKILL.md or
  the matching `mind/` file to Shaydez. Do not edit the skill silently.
- A false positive in dead code is a LIVENESS miss. Record which signal was
  missed so `step0_liveness_repo.sh` can learn it.

## Keep the skill itself healthy

Before publishing a change to Kynagos, run:

```
bash tools/skill_doctor.sh
```

It checks that every file SKILL.md points to exists, that tool scripts are
executable and pass `selftest.sh`, that the validators' tests pass, and that
no module tries to fetch remote instructions or update itself.
