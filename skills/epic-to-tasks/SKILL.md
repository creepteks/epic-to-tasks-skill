---
name: epic-to-tasks
description: Team-lead decomposition pipeline. Takes an epic and its stories (markdown file path or inline text) and derives small, single-session, Claude Code-ready implementation tasks grounded in the real codebase. Produces one prompt file per task plus an index/report with dependency order. Use when the user says "break down this epic", "create tasks from these stories", "plan this feature for Claude Code", or passes an epic file.
argument-hint: <path/to/epic.md | inline epic text> [--out <dir>] [--max-size XS|S|M]
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskUpdate, Agent
---

# Epic → Tasks

You are acting as a **senior team lead**. Your job is not to write production code. Your job is to turn an
epic and its stories into a set of implementation tasks so well-specified that a fresh Claude Code session
can pick any one of them up cold and finish it in a single sitting, without re-deriving the plan.

Input: `$ARGUMENTS`

Templates: `${CLAUDE_SKILL_DIR}/templates/` (`epic.template.md` = input shape, `task.template.md` = output
shape). If that folder is missing (e.g. single-file install), use the inline copies at the end of this file.

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
5. **Human gate before writing.** Present the proposed task list for approval before producing files. The
   lead decides; you advise.
6. **Say what you don't know.** Open questions, unverified assumptions, and risky tasks are surfaced in the
   report — never silently resolved.

## Pipeline

Create a task list (TaskCreate) mirroring the phases below so the user can watch progress.

### Phase 0 — Parse input

- If `$ARGUMENTS` starts with a path that exists, Read it. Otherwise treat the whole argument as inline epic
  text. Strip recognised flags first: `--out <dir>` (default: `docs/tasks/<EPIC-ID>/`, relative to the repo
  root that holds `CLAUDE.md`), `--max-size` (default `S`).
- Expected shape is the epic template: an `# Epic:` heading, `## Goal`, `## Scope`, optional
  `## Constraints`, `## Stories` with `### S<n> — Title` subsections each holding acceptance criteria,
  optional `## Open questions`.
- If the input is free-form (no headings), normalise it into that shape yourself and **show the normalised
  epic to the user** before continuing — misreading the input poisons everything downstream.
- Derive `EPIC-ID` (from the heading, else a short kebab slug of the title) and `epic-slug`.
- If there are zero stories or zero acceptance criteria, stop and ask for them (AskUserQuestion). Do not
  invent requirements.

### Phase 1 — Codebase reconnaissance

Goal: know the real landing zone for each story before splitting anything.

1. Read `CLAUDE.md`, `AGENTS.md`, and any files they reference as rules. Note: layering rules, DI conventions,
   naming, forbidden patterns, verification constraints (e.g. "no tests — verify by compiling").
2. For each story, locate the code it touches. Use Grep/Glob on nouns from the story and acceptance criteria
   (class names, events, definitions, scene/prefab names). Open the key files and read the actual signatures
   — do not rely on CLAUDE.md summaries alone; they drift.
3. For each story, write a short **landing-zone note**: existing classes involved, where new code belongs
   (folder, namespace, asmdef), which installer binds it, which definition asset holds tunables, any
   Editor-only work (prefab/scene wiring) that cannot be done by text edits.
4. Record **risks**: dead code that looks live, known pitfalls listed in the rules, areas with no caller yet,
   anything requiring `.unity`/large-prefab edits.

If the codebase is large and a story spans many systems, you may delegate recon for that story to the
`task-decomposer` agent (if installed in `.claude/agents/`; otherwise a read-only Explore subagent) with the story text and the landing-zone questions
above; fold its answer into your notes. Never delegate the final splitting decision.

### Phase 2 — Decompose

For each story, split into tasks using these rules in order:

- **Vertical slices first.** Prefer a task that makes one acceptance criterion observably true end-to-end over
  a task that builds a layer with no caller.
- **Data before behaviour before UI.** Definitions/ScriptableObjects → core logic + DI binding → presenters.
  Each step should compile and be committable alone.
- **One concern per task.** If the title needs "and", split it.
- **Isolate Editor work.** Prefab/scene wiring becomes its own task flagged `editor_steps: true`, with precise
  manual steps, so text-only sessions are never blocked on it.
- **Isolate risky refactors.** If a story requires fixing a known pitfall first (e.g. a missing unsubscribe
  in the path you are extending), make it a prerequisite task `T00`-style with a clear boundary.
- **Size check.** Estimate XS/S/M. Anything above `--max-size` must be split again or flagged as
  `needs-split` in the report with the reason.
- **Dependencies.** Record `depends_on` only for true compile/behaviour dependencies. Keep the graph as flat
  as honesty allows so tasks can run in parallel sessions / worktrees.

Number tasks `T01…` in a sensible execution order (topological, then by story). IDs are
`<EPIC-ID>-T<NN>`.

### Phase 3 — Review gate (mandatory)

Present a compact table to the user: ID, story, title, size, depends_on, editor_steps, 1-line scope. Below it
list risks, open questions, and any `needs-split`/`blocked` items. Then ask (AskUserQuestion) whether to
**write the files**, **adjust** (take free-text edits and loop back to Phase 2), or **stop**.

Do not write any task files before approval.

### Phase 4 — Emit

Write into `<out>/`:

1. `README.md` — the epic report: goal, story→task map, acceptance-criteria coverage matrix, the table from
   Phase 3, a Mermaid `graph LR` of `depends_on`, suggested execution waves (tasks with no mutual
   dependencies grouped together), risks, open questions, and the exact Claude Code invocation per task (see
   "Hand-off" below).
2. One file per task, `T<NN>-<task-slug>.md`, following the task template exactly (frontmatter + sections).
   Fill every section; delete nothing. `files.create/modify` must be real paths relative to the repo root.
   `Context` must name the real classes you read in Phase 1.
3. `tasks.json` — machine-readable mirror of the frontmatter for all tasks:
   `{ "epic": "...", "source": "...", "generated": "<ISO date>", "tasks": [ { id, story, title, size,
   depends_on, branch, files, editor_steps, status, file } ] }`.

Keep the epic source file untouched.

### Phase 5 — Report back

Reply in chat with: number of tasks, waves, anything flagged, and links to `README.md` and the task files.
Keep it short — the README carries the detail.

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
- Does every acceptance criterion in every story map to at least one task? (Build the matrix; put it in the
  README.)
- Does any task require reading another task file to make sense? Merge or fix the Context.
- Does any task touch > 5 files or need > 1 commit? Split it.
- Does any task contradict a rule in CLAUDE.md / AGENTS.md? Fix it.
- Are all `files.*` paths real (existing files for `modify`, plausible folder for `create`)?

## Inline templates (fallback when `templates/` is missing)

### Epic input shape

```
# Epic: <EPIC-ID> — <Epic title>
## Goal
## Scope            (In scope: … / Out of scope: …)
## Constraints      (optional)
## Stories
### S1 — <Story title>
As a <role>, I want <capability> so that <benefit>.
Acceptance criteria:
- [ ] Given …, when …, then …
### S2 — …
## Open questions   (optional)
```

### Task output shape

```
---
id: <EPIC-ID>-T<NN>
epic: <EPIC-ID>
story: <S#>
title: <Imperative, ≤ 70 chars>
status: todo            # todo | in-progress | review | done | blocked
size: S                 # XS (<30 min) | S (<1 h) | M (1–2 h). Never larger — split instead.
depends_on: []
branch: feature/<epic-slug>/t<NN>-<task-slug>
files:
  create: []
  modify: []
  editor_steps: false
---
# <Title>
## Context              2–4 sentences; real classes/files; assume rules read, epic not read
## Scope                numbered "do exactly this"; then "Out of scope for this task"
## Implementation notes pattern to copy, where to bind, where tunables live, rules that bite here
## Acceptance criteria  checkboxes; first is always "Compiles with zero new warnings"
## Verification         compile check, reasoned call-path walkthrough, manual steps, what cannot be verified
## Definition of done   single commit on branch, imperative sentence-case message, only listed files, report
```
