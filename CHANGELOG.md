# Changelog

## 1.1.0 — 2026-10-07
- Extracted from the BlackBorderShips `.claude-plugins/epic-pipeline` plugin (v1.1.0) into a standalone repo.
- Skills are now installed per project as plain `.claude/skills/` folders, not as a plugin:
  slash commands are `/epic-to-tasks`, `/implement-task`, `/epic-status` (no `epic-pipeline:` prefix).
- Templates moved into `skills/epic-to-tasks/templates/`.
- `task-decomposer` agent is optional; `epic-to-tasks` falls back to a read-only Explore subagent.
