---
name: complete-plan
description: Mark a znotes/plans/*.md plan as done — verify it, append a completion summary, and move it to znotes/completed_plans/. Use when the user says a plan is finished, asks "did I finish this plan?", or asks to close out/archive a plan.
---

# Complete a plan

This project keeps plan documents in `znotes/plans/` while they're in progress (see
`AGENTS.md`'s "plans live in znotes" convention). Once a plan's work is actually done, it moves to
`znotes/completed_plans/` with a completion record appended — this skill automates that move.

## Steps

1. **Identify the plan.** If the user named it, use that file. If ambiguous or unnamed, infer from
   the current conversation (what was just worked on) or ask which file in `znotes/plans/`.

2. **Verify completion before touching anything.** Read the plan's own "Verification" section (or
   equivalent) and actually run those checks now — don't take completion on faith:
   - Re-run the test commands / rubocop / grep checks the plan specifies.
   - Confirm the files the plan says would change actually changed (`git diff --stat` /
     `git status`).
   - If anything in the plan is still undone or a check fails, tell the user what's missing and
     stop — do not move the file. Ask the user how to proceed. Only continue once everything the
     plan set out to do is genuinely done.

3. **Get a real timestamp.** Run `date "+%Y-%m-%d %H:%M %Z"` — never guess or use a model-internal
   sense of time.

4. **Append a completion section** to the end of the plan file, in this shape:

   ```markdown
   ---

   ## Completed — <timestamp from step 3>

   <2-5 sentences: what was actually implemented, and — importantly — any point where the
   implementation deviated from the original plan and why. If nothing deviated, say so briefly.>

   **Files changed:**
   - `path/to/file` — <what changed there, one clause>
   - ...

   **Verification:** <what you ran in step 2 and the result — e.g. test counts, rubocop clean,
   grep results>.
   ```

   Base the files-changed list and the summary on the actual diff (`git diff`), not just what the
   plan predicted — note any extra files touched or planned files left untouched, and why.

5. **Move the file.** Ensure the destination exists (`mkdir -p znotes/completed_plans`), then move
   the plan there, keeping its filename:
   `mv znotes/plans/<name>.md znotes/completed_plans/<name>.md`
   (`znotes/` is gitignored per `AGENTS.md`, so this is a plain filesystem move, not a `git mv`.)

6. **Confirm** to the user with the new path and a one-line recap of the completion summary.

## Notes

- Don't editorialize beyond the plan's own scope — if you discover unrelated issues while
  verifying (e.g. a pre-existing bug the plan didn't cause), mention them briefly in the summary
  as "found but out of scope," not as part of "what was changed."
- If the plan was abandoned or superseded rather than completed, ask the user whether they still
  want it moved to `completed_plans/` (with a note that it was abandoned) or handled differently —
  don't assume.
