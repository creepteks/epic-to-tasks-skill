---
name: epic-status
description: Show and update progress of an epic produced by epic-to-stories and story-to-tasks. Lists stories and tasks by status and wave, shows which stories are ready to decompose and which tasks are unblocked next, and lets the lead mark tasks done/blocked or block/reopen stories, refreshing the README status. Use when the user asks "where are we on epic X", "what's next", or "mark T03 done".
argument-hint: <docs/tasks/<EPIC-ID>/> [done <T-ID>...] [block <T-ID|S-ID> "<reason>"] [reopen <T-ID|S-ID>]
---

# Epic status

Input: `$ARGUMENTS` — an epic directory produced by `epic-to-stories` / `story-to-tasks`, optionally followed
by commands.

## Behaviour

1. **Load.**
   - Read `stories.json` and every `S*.md` frontmatter, if present. If they disagree, the story file wins;
     rewrite `stories.json` to match and mention the fix.
   - Read `tasks.json` and every `T*.md` frontmatter, if present. Same rule: the task file wins.
   - A directory with tasks but no stories is a v1 directory (made by the old `epic-to-tasks`): skip
     everything about stories below and behave as a task-only dashboard.
2. **Apply commands**, if any:
   - `done <T-ID>` — set `status: done` in the task file frontmatter and `tasks.json`. Only the lead does
     this; if the task has no `## Implementation report`, warn before proceeding. Stories cannot be marked
     done directly — they follow their tasks.
   - `block <ID> "<reason>"` — task or story: set `status: blocked`, append the reason under a `## Blocked`
     section of that file.
   - `reopen <ID>` — task: set `status: todo`. Story: set `status: ready` if it has no tasks, else
     `decomposed` (then step 3 re-derives it).
3. **Derive story status** for every story with tasks and not manually `blocked`: `done` when all its tasks
   are `done`; `in-progress` when any task has moved past `todo`; otherwise `decomposed`. Write changes back
   to the story file and `stories.json`. Story status only moves forward this way; `reopen` is the only way
   back.
4. **Compute:**
   - task counts per status; **ready tasks** (status `todo` and all `depends_on` are `done`); **blocked
     chain** (what each blocked/unfinished task is holding up);
   - story counts per status and per wave; **stories ready to decompose** (status `ready` and every upstream
     story is `decomposed`, `in-progress` or `done`); stories waiting on upstream stories.
5. **Print**, terse:
   - a story table (ID, title, size, wave, status, depends_on, tasks done/total) sorted by wave;
   - "Stories ready to decompose" with the exact `/story-to-tasks <dir> S<NN>` command (and one combined
     `/story-to-tasks <dir> --ready` line when there are several);
   - a task table (ID, story, title, size, status, depends_on, editor_steps) sorted by wave;
   - "Ready now" with the exact `claude -p "/implement-task <file>"` command for each ready task;
   - "Waiting on" for tasks and stories.
6. Refresh the `## Status` section at the top of the directory's `README.md` (create it if missing) with the
   story table, the task table and a last-updated date. Leave the rest of the README untouched.

Keep output terse; this is a dashboard, not a report.
