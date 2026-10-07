# epic-pipeline skills

Source of truth for three Claude Code skills that turn an epic + stories into small, single-session
implementation tasks and then drive them to done.

```
docs/epics/<ID>.md ──▶ /epic-to-tasks ──▶ docs/tasks/<ID>/ (README, tasks.json, T<NN>-*.md)
                                             │
                        /implement-task <T-file>  (one Claude Code session per task)
                                             │
                        /epic-status docs/tasks/<ID> [done|block|reopen <T-ID>]
```

## Layout

| Path | Installs to (in a project) |
| --- | --- |
| `skills/epic-to-tasks/SKILL.md` + `templates/` | `<project>/.claude/skills/epic-to-tasks/` |
| `skills/implement-task/SKILL.md` | `<project>/.claude/skills/implement-task/` |
| `skills/epic-status/SKILL.md` | `<project>/.claude/skills/epic-status/` |
| `agents/task-decomposer.md` (optional recon subagent) | `<project>/.claude/agents/task-decomposer.md` |

The templates live inside the `epic-to-tasks` skill folder so the skill is self-contained
(`${CLAUDE_SKILL_DIR}/templates/`). `epic-to-tasks` also carries inline copies, so it still works if only
`SKILL.md` is copied. Copy `templates/epic.template.md` to `docs/epics/` in the project to start an epic.

## Install into a project (manual)

Copy the folders:

```
<project>/.claude/skills/epic-to-tasks/     ← skills/epic-to-tasks/   (incl. templates/)
<project>/.claude/skills/implement-task/    ← skills/implement-task/
<project>/.claude/skills/epic-status/       ← skills/epic-status/
<project>/.claude/agents/task-decomposer.md ← agents/task-decomposer.md
```

Or use the helper script (overwrites existing copies of these three skills only):

```powershell
.\install.ps1 -Project D:\Projects\SomeGame
```
```bash
./install.sh /path/to/some-game
```

Commit the copied `.claude/skills/` and `.claude/agents/` in the project so teammates get them.
Verify in Claude Code: `/epic-to-tasks`, `/implement-task`, `/epic-status` appear in the slash menu.

User-level instead of per-project: copy to `~/.claude/skills/` and `~/.claude/agents/`.

Claude Desktop / Cowork: account skills are single-file. Zip one skill folder as `<name>.skill`
(containing `<name>/SKILL.md`) and click **Save skill**, or ask Claude to save the SKILL.md to your account.

## Updating

1. Edit files here, commit, and tag (`git tag v1.2.0`). Note the change in `CHANGELOG.md`.
2. Re-run the install into each project that should get the update and commit there.
   Projects pin whatever version they copied; `git diff` in the project shows what changed.

Keep the task-file frontmatter keys stable — `tasks.json`, `implement-task` and `epic-status` all read them.
Project-specific rules belong in each project's `CLAUDE.md` / `AGENTS.md`, not in these skills.
