---
name: wrap-up
description: End-of-session doc hygiene check. Reviews the current conversation against AGENTS.md, docs/*.md, and docs/roadmap.md to catch anything stale, missing, or worth recording — new rules/conventions decided, surprising non-obvious facts learned, and future plans discussed but not yet written down. Proposes edits, gets explicit approval, then applies them and reports what changed. Use whenever the user runs /wrap-up, says "wrap up", "wrap this session up", "let's wrap up", "before we finish, update the docs", or asks to close out/document a session before ending it.
---

# Wrap up a session

This project keeps two kinds of durable written record: `AGENTS.md` (conventions/architecture
pointers, read by every future agent) and `docs/*.md` (deeper reference — architecture, game
rules, and `docs/roadmap.md` for future work). This skill reconciles both against what actually
happened in the current conversation, so decisions made in chat don't evaporate when the session
ends.

This skill only looks at **this conversation** — not git history or uncommitted diffs. Git already
records what changed; this skill exists to capture the *reasoning and decisions* that git commits
don't, and that would otherwise be lost when the context window closes.

## Step 1 — Mine the conversation

Read back over the session and pull out, specifically:

- **Rules or conventions decided or clarified** (e.g. "always do X this way," a correction to how
  something should be built, a convention the user confirmed).
- **Surprising, non-obvious facts** — things you (the agent) learned that a future agent reading
  only the codebase would *not* discover on their own: a subtle invariant, a reason something is
  shaped the way it is, a gotcha, a "we tried X and it didn't work because Y."
- **Future plans or ideas mentioned** that aren't already captured in `docs/roadmap.md` or
  `znotes/plans/` — even offhand ones ("we should eventually...", "next time let's...").
- **Anything already in `AGENTS.md` or `docs/*.md` that this conversation showed to be stale,
  wrong, or contradicted** — e.g. a doc describes a pattern the session just changed.

Skip anything that's just a restatement of what the code already makes obvious — that's the bar
for the whole skill (see Step 3).

## Step 2 — Check current doc state

Read `AGENTS.md`, `docs/architecture.md`, `docs/go_fish_rules.md`, `docs/crazy_eights_rules.md`,
and `docs/roadmap.md` (if it doesn't exist yet, note that it would need to be created). Note:

- `AGENTS.md`'s current line count — it has a hard 200-line ceiling. If an addition would push it
  over, something else in the file needs to tighten or move out (e.g. detail that belongs in a
  `docs/*.md` file instead, with `AGENTS.md` just pointing to it) rather than blowing the limit.
- Never touch `CLAUDE.md` — it only ever contains the `@AGENTS.md` include line. All actual content
  goes in `AGENTS.md` or `docs/`.

## Step 3 — Decide what's actually worth writing down

Apply this bar to every candidate item from Step 1 before proposing it:

- **Would a future agent get this wrong or miss it by reading only the code?** If the code already
  makes it obvious (naming, structure, an existing comment), it does not belong in a doc — see the
  project's own magic-numbers-style philosophy: only extract/record what genuinely isn't clear from
  context.
- **Is it something that will come up again?** A one-off detail specific to this session's task
  isn't worth a permanent doc entry; a convention or gotcha that will bite the next person doing
  similar work is.
- **Where does it belong?**
  - A convention/rule → `AGENTS.md` (short, in the existing "Conventions" style) if it's
    project-wide and commonly relevant; otherwise the relevant `docs/*.md` file.
  - A non-obvious architectural fact or rules gotcha → the relevant `docs/*.md` file
    (`architecture.md`, `go_fish_rules.md`, `crazy_eights_rules.md`).
  - A future idea/plan not yet in progress → `docs/roadmap.md` (create it if missing, using a
    simple dated bullet list grouped by theme; amend in place if it already exists — don't
    duplicate an idea that's already listed, extend it instead).

Anything that doesn't clear this bar still gets reported to the user in Step 4 as a "learned but
not written down" item — it's worth surfacing even when it's not worth permanently documenting.

## Step 4 — Propose, explain, and stop

Before editing anything, present the user with:

1. A bulleted list of every proposed change, one bullet per file, each bullet naming the file and
   the specific addition/edit/removal.
2. For each bullet, a short reason it's needed — tie it back to what happened in the conversation
   (e.g. "AGENTS.md doesn't mention X, but we agreed this session that X is now required").
3. Anything learned this session that did **not** clear the Step 3 bar for permanent documentation
   — list it separately so the user still sees it even though it won't be written anywhere.
4. A 1–3 sentence summary of the wrap-up as a whole.

Then **stop and wait for explicit approval**. Do not edit any file before the user confirms. If the
user asks for changes to the proposal, revise and re-present before applying anything.

## Step 5 — Apply and confirm

Once approved, make the edits exactly as approved (adjust for any feedback first). Re-check
`AGENTS.md`'s line count after editing to confirm it's still ≤200 lines. Then report back:

- The same bulleted list from Step 4, updated to reflect what was actually written (in case
  anything changed based on feedback).
- The 1–3 sentence summary.

## Notes

- If the conversation genuinely produced nothing worth documenting, say so plainly in Step 4 rather
  than manufacturing filler bullets to have something to show.
- Don't fold in unrelated cleanup (e.g. fixing an unrelated stale doc line you happen to notice)
  without flagging it as a separate, clearly-labeled bullet — the user should be able to tell what
  came from this session's conversation versus incidental drive-by findings.
