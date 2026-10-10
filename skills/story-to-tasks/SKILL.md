---
name: story-to-tasks
description: Second stage of the epic pipeline. Takes an epic directory produced by /epic-to-stories and the stories the lead selects (by ID, --ready, or --all) and derives small, single-session, Claude Code-ready implementation tasks grounded in the real codebase. Produces one prompt file per task, merges them into the epic's tasks.json, links them to their stories, and updates the README task graph. Use when the user says "create tasks for S02", "decompose the ready stories", "plan story X for Claude Code".
argument-hint: <docs/tasks/<EPIC-ID>/> (S<NN>... | --ready | --all) [--max-size XS|S|M]
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskUpdate, Agent
---

# Stories → Tasks

You are acting as a **senior team lead**. Your job is not to write production code. Your job is to turn the
selected stories of an epic into a set of implementation tasks so well-specified that a fresh Claude Code
session can pick any one of them up cold and finish it in a single sitting, without re-deriving the plan.

Input: `$ARGUMENTS`

Templates: `${CLAUDE_SKILL_DIR}/templates/` (`task.template.md` = output shape). If that folder is missing
(e.g. single-file install), use the inline copy at the end of this file.

## Operating principles

1. **Ground every task in the codebase.** Never write "add a service" — write "add `BattleStarter` next to
   `BattleController.cs`, bind it in `MainInstaller.BindBattle()`". If you have not opened the files, you are
   guessing. Guessing is the one failure mode this skill exists to prevent.
2. **Small beats clever.** A task is one Claude Code session: roughly 1–5 files, one commit, compiles on its
   own, and leaves the build green even if later tasks never happen. Default max size is `S` (< 1 h). If a
   story cannot be split below `M`, flag it instead of inflating the task.
3. **Honour project rules.** Read `CLAUDE.md` / `AGENTS.md` (and anything they `@include`) first. Every task's
   implementation notes must cite the specific rules that bite there. Tasks never contradict them.
4. **No code in tasks.** Tasks describe *what* and *where*, point at patterns to copy, and define
   acceptance + verification. Snippets are allowed only to disambiguate (≤ 5 lines).
5. **Respect the story graph.** Stories were sequenced and approved in `/epic-to-stories`. Tasks may depend on
   tasks of *upstream* stories only; never invert or bypass the story graph.
6. **Human gate before writing.** Present the proposed task list for approval before producing files.
7. **Say what you don't know.** Open questions, unverified assumptions, and risky tasks are surfaced in the
   report — never silently resolved.

## Pipeline

Create a task list (TaskCreate) mirroring the phases below so the user can watch progress.

### Phase 0 — Load and select

- The first argument is the epic directory. It must contain `stories.json` and `S*.md` files. If it does not
  (e.g. the user passed an epic markdown file), stop and tell them to run `/epic-to-stories` first.
- Read `stories.json` and every `S*.md` frontmatter. If they disagree, the story file wins; fix `stories.json`
  and mention it. Read `tasks.json` if it exists. Strip `--max-size` (default `S`).
- Resolve the selection:
  - explicit IDs — `S02`, `S2` or `<EPIC-ID>-S02` all mean the same story;
  - `--ready` — stories with `status: ready` whose every upstream story (transitive `depends_on`) is
    `decomposed`, `in-progress` or `done`;
  - `--all` — every story with `status: ready`.
- Validate each selected story:
  - `draft` or `blocked` → refuse it and say why (the open question, or "still a draft").
  - Already has tasks (`tasks:` non-empty) → ask (AskUserQuestion): **skip** it, or **replace its `todo`
    tasks**. Tasks with any other status are never touched or renumbered.
  - An upstream story is not yet decomposed (and not in the selection) → warn, naming the chain, and ask:
    **include the upstream stories too**, **proceed anyway** (tasks then cannot depend on that story's tasks;
    note it as a risk), or **stop**.
- If the selection ends up empty, say so and print the stories that *are* ready, then stop.

### Phase 1 — Codebase reconnaissance

Goal: know the real landing zone for each selected story before splitting anything.

1. Read `CLAUDE.md`, `AGENTS.md`, and any files they reference as rules. Note: layering rules, DI conventions,
   naming, forbidden patterns, verification constraints (e.g. "no tests — verify by compiling").
2. Start from each story's `## Landing zone` note, then go deeper. Use Grep/Glob on nouns from the story and
   acceptance criteria (class names, events, definitions, scene/prefab names). Open the key files and read
   the actual signatures — do not rely on CLAUDE.md summaries or the story note alone; they drift.
3. Read the task files of upstream stories that are already decomposed: their `files.create` are part of the
   landing zone even if not merged yet. Note which upstream tasks introduce what you need.
4. For each story, write a short **landing-zone note**: existing classes involved, where new code belongs
   (folder, namespace, asmdef), which installer binds it, which definition asset holds tunables, any
   Editor-only work (prefab/scene wiring) that cannot be done by text edits.
5. Record **risks**: dead code that looks live, known pitfalls listed in the rules, areas with no caller yet,
   anything requiring `.unity`/large-prefab edits.

If the codebase is large and a story spans many systems, you may delegate recon for that story to the
`task-decomposer` agent (if installed in `.claude/agents/`; otherwise a read-only Explore subagent) with the
story file and the landing-zone questions above; fold its answer into your notes. Never delegate the final
splitting decision.

### Phase 2 — Decompose

For each selected story, split into tasks using these rules in order:

- **Vertical slices first.** Prefer a task that makes one acceptance criterion observably true end-to-end over
  a task that builds a layer with no caller.
- **Data before behaviour before UI.** Definitions/ScriptableObjects → core logic + DI binding → presenters.
  Each step should compile and be committable alone.
- **One concern per task.** If the title needs "and", split it.
- **Isolate Editor work.** Prefab/scene wiring becomes its own task flagged `editor_steps: true`, with precise
  manual steps, so text-only sessions are never blocked on it.
- **Isolate risky refactors.** If a story requires fixing a known pitfall first (e.g. a missing unsubscribe
  in the path you are extending), make it a prerequisite task with a clear boundary.
- **Size check.** Estimate XS/S/M. Anything above `--max-size` must be split again or flagged as
  `needs-split` in the report with the reason.
- **Dependencies.** Record `depends_on` only for true compile/behaviour dependencies. A task may depend on:
  tasks of the same story, or tasks of a story that is upstream (transitively) in the story graph. Never on
  tasks of a downstream or unrelated story — if that seems necessary, the story graph is wrong: stop and
  report it instead of working around it. Keep the graph as flat as honesty allows.
- **Traceability.** Every acceptance criterion `S<NN>.AC<n>` of every selected story maps to at least one
  task.

Numbering: continue from the highest existing `T<NN>` in `tasks.json` (start at `T01` if none). Never
renumber existing tasks. Within this run, order topologically, then by story. Replaced `todo` tasks keep
their numbers where they survive, otherwise their numbers are retired (not reused). IDs are
`<EPIC-ID>-T<NN>`.

### Phase 3 — Review gate (mandatory)

Present a compact table to the user: ID, story, title, size, depends_on, editor_steps, 1-line scope. Below it
list: cross-story dependencies added (task → upstream task), the AC→task coverage for the selected stories,
risks, open questions, and any `needs-split`/`blocked` items. Then ask (AskUserQuestion) whether to
**write the files**, **adjust** (take free-text edits and loop back to Phase 2), or **stop**.

Do not write any task files before approval.

### Phase 4 — Emit

Write into the epic directory:

1. One file per task, `T<NN>-<task-slug>.md`, following the task template exactly (frontmatter + sections).
   Fill every section; delete nothing. `files.create/modify` must be real paths relative to the repo root.
   `Context` must name the real classes you read in Phase 1. If replacing `todo` tasks, delete the old files
   that did not survive.
2. `tasks.json` — **merge**, do not overwrite: keep entries of other stories as they are; add or replace
   entries for the selected stories. Shape:
   `{ "epic": "...", "source": "...", "generated": "<ISO date>", "tasks": [ { id, story, title, size,
   depends_on, branch, files, editor_steps, status, file } ] }`.
3. Each selected story: set `tasks: [<task IDs>]` and `status: decomposed` in the story file and in
   `stories.json`.
4. `README.md` — rewrite **only** the `## Tasks` section (create it before `## Risks` if missing), covering
   *all* tasks in `tasks.json`, not just this run's:
   - the task table (ID, story, title, size, depends_on, editor_steps, status);
   - a Mermaid `graph LR` of task `depends_on` with one `subgraph` per story (`subgraph S01 [S01 · Title]`),
     so cross-story edges are visible;
   - suggested execution waves (tasks with no mutual dependencies grouped together);
   - the AC→task coverage matrix for all decomposed stories;
   - the exact Claude Code invocation per task (see "Hand-off" below).
   Append any new risks/open questions to those sections. Leave every other section untouched.

Keep the epic source file and story narratives/acceptance criteria untouched. If decomposition shows a story
is wrong, report it; the lead fixes stories via `/epic-to-stories`.

### Phase 5 — Report back

Reply in chat with: stories decomposed, number of tasks, waves, cross-story dependencies, anything flagged,
which stories are now ready to decompose next, and links to `README.md` and the task files. Keep it short —
the README carries the detail.

## Hand-off to Claude Code

Each task is designed to be run as its own Claude Code session from the repo root, in dependency order:

```
# interactive (recommended for the first task of an epic)
claude
> /implement-task docs/tasks/<EPIC-ID>/T01-<slug>.md

# non-interactive, one task
claude -p "/implement-task docs/tasks/<EPIC-ID>/T01-<slug>.md" --permission-mode acceptEdits
```

Independent tasks within a wave may run in parallel using separate `git worktree`s, one per task branch.
Include these commands verbatim in the README so the lead can copy them.

## Quality bar (self-check before Phase 3)

- Could a competent engineer who has never seen the epic implement this task from the file alone? If not,
  the Context or Implementation notes are too thin.
- Does every acceptance criterion of every selected story map to at least one task?
- Does any task require reading another task file or the story file to make sense? Fix the Context.
- Does any task touch > 5 files or need > 1 commit? Split it.
- Does any task depend on a task of a story that is not upstream of its own story? Remove the edge or report
  the story graph as wrong.
- Is the combined task graph (existing + new) acyclic? Are existing task IDs unchanged?
- Does any task contradict a rule in CLAUDE.md / AGENTS.md? Fix it.
- Are all `files.*` paths real (existing files for `modify`, plausible folder for `create`)?

## Inline template (fallback when `templates/` is missing)

### Task output shape

```
---
id: <EPIC-ID>-T<NN>
epic: <EPIC-ID>
story: <EPIC-ID>-S<NN>
title: <Imperative, ≤ 70 chars>
status: todo            # todo | in-progress | review | done | blocked
size: S                 # XS (<30 min) | S (<1 h) | M (1–2 h). Never larger — split instead.
depends_on: []          # task IDs; same story or an upstream story only
branch: feature/<epic-slug>/t<NN>-<task-slug>
files:
  create: []
  modify: []
  editor_steps: false
---
# <Title>
## Context              2–4 sentences; real classes/files; assume rules read, epic and story not read
## Scope                numbered "do exactly this"; then "Out of scope for this task"
## Implementation notes pattern to copy, where to bind, where tunables live, rules that bite here
## Acceptance criteria  checkboxes; first is always "Compiles with zero new warnings"; others cite S<NN>.AC<n>
## Verification         compile check, reasoned call-path walkthrough, manual steps, what cannot be verified
## Definition of done   single commit on branch, imperative sentence-case message, only listed files, report
```
