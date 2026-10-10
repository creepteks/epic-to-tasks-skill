# Changelog

## 2.0.0 — 2026-10-10
- **Breaking:** `epic-to-tasks` is split into two stages.
  - New `/epic-to-stories`: generates or refines user stories (acceptance criteria with `AC` IDs, sizes) and
    a story dependency graph with waves and a Mermaid diagram. Writes `S<NN>-*.md`, `stories.json` and the
    epic README. Has its own review gate.
  - `/epic-to-tasks` renamed to `/story-to-tasks`: decomposes only the selected stories (`S<NN>…`,
    `--ready`, `--all`), warns when upstream stories are not yet decomposed, merges into `tasks.json`
    without renumbering, and allows task dependencies on upstream stories' tasks only.
- New `story.template.md`; the epic template's `## Stories` section is now optional and moved to
  `epic-to-stories`.
- Task frontmatter `story:` is now the full story ID (`<EPIC-ID>-S<NN>`); acceptance criteria cite
  `S<NN>.AC<n>`.
- `/epic-status` shows stories and tasks, derives story status from tasks, lists stories ready to decompose,
  and accepts story IDs for `block`/`reopen`. 1.x task-only directories still work.
- `task-decomposer` takes a story file, maps coverage by AC ID, and supports a landing-zone-only mode.
- Installers install the four skills and remove a stale `epic-to-tasks` folder.

## 1.1.0 — 2026-10-07
- Extracted from the BlackBorderShips `.claude-plugins/epic-pipeline` plugin (v1.1.0) into a standalone repo.
- Skills are now installed per project as plain `.claude/skills/` folders, not as a plugin:
  slash commands are `/epic-to-tasks`, `/implement-task`, `/epic-status` (no `epic-pipeline:` prefix).
- Templates moved into `skills/epic-to-tasks/templates/`.
- `task-decomposer` agent is optional; `epic-to-tasks` falls back to a read-only Explore subagent.
