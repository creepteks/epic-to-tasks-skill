---
name: epic-status
description: Show and update progress of an epic's task set produced by epic-to-tasks. Lists tasks by status and wave, shows what is unblocked next, and lets the lead mark tasks done/blocked or regenerate the README summary. Use when the user asks "where are we on epic X", "what's next", or "mark T03 done".
argument-hint: <docs/tasks/<EPIC-ID>/> [done <T-ID>...] [block <T-ID> "<reason>"] [reopen <T-ID>]
---

# Epic status

Input: `$ARGUMENTS` — a task directory produced by `epic-to-tasks`, optionally followed by
commands.

## Behaviour

1. Read `tasks.json` and every `T*.md` frontmatter in the directory. If they disagree, the task file wins;
   rewrite `tasks.json` to match and mention the fix.
2. Apply commands, if any:
   - `done <ID>` — set `status: done` in the task file frontmatter and `tasks.json`. Only the lead does this;
     if the task has no `## Implementation report`, warn before proceeding.
   - `block <ID> "<reason>"` — set `status: blocked`, append the reason under a `## Blocked` section.
   - `reopen <ID>` — set `status: todo`.
3. Compute: counts per status; **ready** tasks (status `todo` and all `depends_on` are `done`); **blocked
   chain** (what each blocked/unfinished task is holding up).
4. Print a compact table (ID, title, size, status, depends_on, editor_steps) sorted by wave, then a
   "Ready now" list with the exact `claude -p "/implement-task <file>"` command for each, and a
   "Waiting on" list.
5. Refresh the `## Status` section at the top of the directory's `README.md` (create it if missing) with the
   same table and a last-updated date. Leave the rest of the README untouched.

Keep output terse; this is a dashboard, not a report.
