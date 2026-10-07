---
name: implement-task
description: Implement a single task file produced by epic-to-tasks in a Claude Code session. Reads the task, verifies its assumptions against the current code, implements exactly the stated scope on the task's branch, verifies, commits, and updates the task status + tasks.json. Use when the user passes a docs/tasks/<EPIC>/T<NN>-*.md file or says "implement task T03".
argument-hint: <path/to/T<NN>-<slug>.md> [--no-branch] [--no-commit]
---

# Implement task

Input: `$ARGUMENTS` — a task file written by `epic-to-tasks`. Flags: `--no-branch` (work on the
current branch), `--no-commit` (leave changes staged but uncommitted).

You are the implementer. The planning has been done; your value is precise execution and honest reporting.

## Procedure

1. **Load.** Read the task file. Read `CLAUDE.md` / `AGENTS.md`. Create a task list (TaskCreate) from the
   task's `Scope` steps plus "verify", "commit", "update status".
2. **Preconditions.**
   - Read the sibling `tasks.json`; every ID in `depends_on` must have `status: done`. If not, stop and report
     which prerequisite is missing — do not start.
   - Confirm each path in `files.modify` exists and each `files.create` does not. If reality has drifted
     from the task (file moved, class renamed, pattern changed), **pause and tell the user** with the
     specific discrepancy and your proposed adjustment. Do not silently improvise a new plan.
   - If `editor_steps: true`, acknowledge up front that part of this task is manual Editor work you will
     describe, not perform.
3. **Branch.** Unless `--no-branch`: `git checkout -b <branch>` from the current integration branch (the task
   names it; if not, use the current branch). If the branch already exists, check it out.
4. **Mark in progress.** Set `status: in-progress` in the task frontmatter and in `tasks.json`.
5. **Implement** exactly the `Scope`. Follow `Implementation notes` and every project rule. Do not refactor
   outside scope; if you notice something worth fixing, note it for the report instead. Keep the diff to the
   listed files; if you must touch another file, say so and why.
6. **Verify** per the task's `Verification` section. Where there is no test suite, do the compile check the
   project prescribes and write out the reasoned call-path walkthrough. Be explicit about anything you could
   not verify.
7. **Commit.** Unless `--no-commit`: one commit, message in the project's style (short, imperative, sentence
   case, e.g. `Add BattleStarter and bind it in MainInstaller`). Never commit generated/ignored files or
   secrets.
8. **Close out.** Set `status: review` (or `blocked` with a reason) in the frontmatter and `tasks.json`.
   Append a `## Implementation report` section to the task file containing: files changed, verification
   performed, what was not verified, manual Editor steps still required, follow-ups noticed.
9. **Reply** with a concise summary mirroring the report and the branch name.

## Hard rules

- Never widen scope to "while I'm here" changes.
- Never mark `done` yourself — `done` is set by the lead after review (see `/epic-status`).
- If acceptance criteria cannot all be met within the stated scope, stop, set `blocked`, and explain. A
  blocked task with a clear reason is a good outcome; a half-implemented one is not.
