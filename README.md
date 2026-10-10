# epic-pipeline skills

Source of truth for four Claude Code skills that turn an epic into reviewed, sequenced user stories, then —
story by story, when the lead asks — into small, single-session implementation tasks, and drive them to done.

```
docs/epics/<ID>.md ──▶ /epic-to-stories ──▶ docs/tasks/<ID>/ (README, stories.json, S<NN>-*.md)
                                               │  story dependency graph + waves; lead picks stories
                        /story-to-tasks docs/tasks/<ID> S01 S03 | --ready | --all
                                               │  ──▶ adds T<NN>-*.md, tasks.json; links tasks to stories
                        /implement-task <T-file>  (one Claude Code session per task)
                                               │
                        /epic-status docs/tasks/<ID> [done|block|reopen <ID>]
```

- **Stories first.** `/epic-to-stories` generates stories from the epic's Goal/Scope, or refines the ones the
  PM wrote, with acceptance criteria (`AC1…`), sizes, a `depends_on` graph, waves and a Mermaid diagram. The
  lead approves them before anything is written.
- **Tasks on demand.** `/story-to-tasks` decomposes only the stories you name (or `--ready`: stories whose
  upstream stories are already decomposed). Re-running it for more stories merges into the same `tasks.json`;
  task IDs are never renumbered. Tasks may depend on tasks of upstream stories, never downstream ones.
- **One dashboard.** `/epic-status` shows stories and tasks, what is ready to decompose and what is ready to
  implement. Story status follows its tasks (`decomposed → in-progress → done`).

## Layout

| Path | Installs to (in a project) |
| --- | --- |
| `skills/epic-to-stories/SKILL.md` + `templates/` | `<project>/.claude/skills/epic-to-stories/` |
| `skills/story-to-tasks/SKILL.md` + `templates/` | `<project>/.claude/skills/story-to-tasks/` |
| `skills/implement-task/SKILL.md` | `<project>/.claude/skills/implement-task/` |
| `skills/epic-status/SKILL.md` | `<project>/.claude/skills/epic-status/` |
| `agents/task-decomposer.md` (optional recon subagent) | `<project>/.claude/agents/task-decomposer.md` |

Templates live inside each skill folder so the skills are self-contained (`${CLAUDE_SKILL_DIR}/templates/`):
`epic.template.md` and `story.template.md` in `epic-to-stories`, `task.template.md` in `story-to-tasks`. Both
skills also carry inline copies, so they still work if only `SKILL.md` is copied. Copy
`templates/epic.template.md` to `docs/epics/` in the project to start an epic.

## Install into a project (manual)

Copy the folders:

```
<project>/.claude/skills/epic-to-stories/   ← skills/epic-to-stories/  (incl. templates/)
<project>/.claude/skills/story-to-tasks/    ← skills/story-to-tasks/   (incl. templates/)
<project>/.claude/skills/implement-task/    ← skills/implement-task/
<project>/.claude/skills/epic-status/       ← skills/epic-status/
<project>/.claude/agents/task-decomposer.md ← agents/task-decomposer.md
```

Or use the helper script (overwrites existing copies of these four skills only, and removes a stale 1.x
`epic-to-tasks` skill folder):

```powershell
.\install.ps1 -Project D:\Projects\SomeGame
```
```bash
./install.sh /path/to/some-game
```

Commit the copied `.claude/skills/` and `.claude/agents/` in the project so teammates get them.
Verify in Claude Code: `/epic-to-stories`, `/story-to-tasks`, `/implement-task`, `/epic-status` appear in the
slash menu.

User-level instead of per-project: copy to `~/.claude/skills/` and `~/.claude/agents/`.

Claude Desktop / Cowork: account skills are single-file. Zip one skill folder as `<name>.skill`
(containing `<name>/SKILL.md`) and click **Save skill**, or ask Claude to save the SKILL.md to your account.

## Upgrading from 1.x

- `/epic-to-tasks` is gone. Run `/epic-to-stories <epic.md>` first, then `/story-to-tasks <dir> --ready`.
- Re-run the installer; it deletes the old `.claude/skills/epic-to-tasks/` folder. If you copy manually,
  delete it yourself.
- Existing 1.x task directories (tasks only, no `stories.json`) still work with `/implement-task` and
  `/epic-status`, which falls back to a task-only dashboard.

## Updating

1. Edit files here, commit, and tag (`git tag v2.0.0`). Note the change in `CHANGELOG.md`.
2. Re-run the install into each project that should get the update and commit there.
   Projects pin whatever version they copied; `git diff` in the project shows what changed.

Keep the story- and task-file frontmatter keys stable — `stories.json`, `tasks.json`, `story-to-tasks`,
`implement-task` and `epic-status` all read them. Keep the README section headings the skills write
(`## Status`, `## Tasks`, …) stable too: each skill rewrites only its own section.
Project-specific rules belong in each project's `CLAUDE.md` / `AGENTS.md`, not in these skills.
