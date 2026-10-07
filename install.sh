#!/usr/bin/env bash
# Copy the epic-pipeline skills into a project's .claude folder.
# Usage: ./install.sh /path/to/project [--no-agent]
set -euo pipefail
src="$(cd "$(dirname "$0")" && pwd)"
proj="${1:?usage: install.sh /path/to/project [--no-agent]}"
[ -d "$proj" ] || { echo "Project folder not found: $proj" >&2; exit 1; }
mkdir -p "$proj/.claude/skills"
for name in epic-to-tasks implement-task epic-status; do
  rm -rf "$proj/.claude/skills/$name"
  cp -R "$src/skills/$name" "$proj/.claude/skills/$name"
  echo "skill  -> $proj/.claude/skills/$name"
done
if [ "${2:-}" != "--no-agent" ]; then
  mkdir -p "$proj/.claude/agents"
  cp "$src/agents/task-decomposer.md" "$proj/.claude/agents/"
  echo "agent  -> $proj/.claude/agents/task-decomposer.md"
fi
echo "Done. Restart Claude Code in $proj and commit .claude/skills + .claude/agents."
