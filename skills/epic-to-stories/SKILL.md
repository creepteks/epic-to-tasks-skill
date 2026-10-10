---
name: epic-to-stories
description: First stage of the epic pipeline. Takes an epic (markdown file path or inline text) and produces a reviewed set of user stories with acceptance criteria and a story dependency graph, grounded in a light pass over the real codebase. Generates stories when the epic has none, or refines the ones it has. Produces one file per story plus stories.json and an epic README with the story graph and waves. Does not create tasks — run /story-to-tasks afterwards. Use when the user says "break down this epic", "write stories for this epic", "plan this feature", or passes an epic file.
argument-hint: <path/to/epic.md | inline epic text> [--out <dir>]
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskUpdate, Agent
---

# Epic → Stories

You are acting as a **senior team lead working with the product manager**. Your job is to turn an epic into a
set of user stories that are each independently valuable, testable and sequenced — the unit the team plans
and prioritises. You do **not** create implementation tasks here; the lead orders those per story later with
`/story-to-tasks`.

Input: `$ARGUMENTS`

Templates: `${CLAUDE_SKILL_DIR}/templates/` (`epic.template.md` = input shape, `story.template.md` = output
shape). If that folder is missing (e.g. single-file install), use the inline copies at the end of this file.

## Operating principles

1. **Value first.** Every story delivers something a user, operator or developer can observe. Purely technical
   groundwork is allowed only as an explicit *enabler* story that at least two other stories depend on.
2. **INVEST.** Independent, Negotiable, Valuable, Estimable, Small, Testable. If a story fails one of these,
   split, merge or rewrite it.
3. **Grounded, but light.** Look at the codebase enough to size stories, find shared foundations and real
   ordering constraints. Deep recon belongs to `/story-to-tasks`.
4. **No invented scope.** Stories stay inside the epic's Scope. Anything missing or ambiguous goes under Open
   questions, never into a story as an assumption.
5. **Human gate before writing.** Present the stories and their graph for approval before producing files.
6. **Say what you don't know.** Open questions, unverified assumptions and risky stories are surfaced in the
   report.

## Pipeline

Create a task list (TaskCreate) mirroring the phases below so the user can watch progress.

### Phase 0 — Parse input

- If `$ARGUMENTS` starts with a path that exists, Read it. Otherwise treat the whole argument as inline epic
  text. Strip recognised flags first: `--out <dir>` (default: `docs/tasks/<EPIC-ID>/`, relative to the repo
  root that holds `CLAUDE.md`).
- Expected shape is the epic template: an `# Epic:` heading, `## Goal`, `## Scope`, optional
  `## Constraints`, optional `## Stories` with `### S<n> — Title` subsections, optional `## Open questions`.
- If the input is free-form (no headings), normalise it into that shape yourself and **show the normalised
  epic to the user** before continuing — misreading the input poisons everything downstream.
- Derive `EPIC-ID` (from the heading, else a short kebab slug of the title) and `epic-slug`.
- Mode: **refine** if the epic lists stories, **generate** if it does not. If there is no Goal or no Scope,
  stop and ask for them (AskUserQuestion). Do not invent requirements.
- If `<out>/stories.json` already exists, read it. Stories with status beyond `ready` (`decomposed`,
  `in-progress`, `done`) are frozen: keep their IDs and content, and only add or revise `draft`/`ready`
  stories around them. Tell the user this up front.

### Phase 1 — Light reconnaissance

1. Read `CLAUDE.md`, `AGENTS.md`, and any files they reference as rules. Note layering rules, conventions and
   constraints that change how work must be sliced or ordered.
2. For each capability in the Scope (or each existing story), Grep/Glob for its nouns and identify the
   systems it lands in. Open key files only far enough to confirm they exist and roughly what they do.
3. Write a short **landing-zone note** per story-sized area: systems involved, whether the code exists or is
   new, shared foundations several areas need, Editor-only work.
4. Record **risks**: missing foundations, known pitfalls in the rules, areas with no caller yet.

For a large epic you may delegate recon of one area to the `task-decomposer` agent (if installed in
`.claude/agents/`; otherwise a read-only Explore subagent) in **landing-zone-only** mode — ask it for the
`Landing zone` and `Risks and unknowns` sections only. Never delegate the story split.

### Phase 2 — Draft or refine stories

- **Generate mode:** derive stories from Goal and Scope. One story per independently observable capability.
- **Refine mode:** keep the PM's intent and order; sharpen wording, split oversized stories, merge fragments,
  fill missing acceptance criteria only when they follow directly from the story text (otherwise add an open
  question). Keep the original `S<n>` numbering where a story survives unchanged in meaning; note renumbering
  in the report.
- Each story gets:
  - a narrative: `As a <role>, I want <capability> so that <benefit>.`
  - acceptance criteria in Given/When/Then form with stable IDs `AC1`, `AC2`, … (referenced later as
    `S<NN>.AC<n>`);
  - a size: `S` (≈ 1–3 tasks), `M` (≈ 3–6), `L` (≈ 6–10). `XL` is not allowed — split it.
- **Enabler stories.** If two or more stories need the same foundation (shared data model, service, asset
  pipeline), extract it as its own story with a developer-facing narrative.
- Every in-scope item of the epic must be covered by at least one story; every out-of-scope item by none.

### Phase 3 — Story dependency graph

- Record `depends_on` only for real prerequisites: story B needs a capability, data or API that story A
  introduces. Preference or convenience is not a dependency. Keep the graph as flat as honesty allows so
  stories can be built in parallel.
- The graph must be acyclic. If you find a cycle, split one of the stories or extract an enabler.
- Compute **waves**: wave 1 = stories with no dependencies; wave n = stories whose dependencies are all in
  earlier waves.
- A story that cannot be specified until an open question is answered gets `status: blocked` with the
  question named. Otherwise new stories start as `ready` (or `draft` if the lead asked for a draft pass).

Number stories `S01…` in a sensible order (topological, then by value). IDs are `<EPIC-ID>-S<NN>`.

### Phase 4 — Review gate (mandatory)

Present to the user:

1. A compact table: ID, title, size, depends_on, wave, status, one-line value statement.
2. The Mermaid story graph (same as will be written to the README).
3. Scope coverage: each in-scope item → story IDs.
4. Risks, open questions, blocked stories, and any renumbering vs. the source epic.

Then ask (AskUserQuestion) whether to **write the files**, **adjust** (take free-text edits and loop back to
Phase 2), or **stop**. Do not write any files before approval.

### Phase 5 — Emit

Write into `<out>/` (if it already holds files from a previous run, confirm before overwriting and never
modify frozen stories):

1. One file per story, `S<NN>-<story-slug>.md`, following the story template exactly. Fill every section;
   leave `tasks: []`.
2. `stories.json` — machine-readable mirror of the story frontmatter:
   `{ "epic": "...", "source": "...", "generated": "<ISO date>", "stories": [ { id, title, size, status,
   depends_on, wave, tasks, file } ] }`.
3. `README.md` — the epic report, with these sections in order:
   - `## Status` (leave empty with a note: "Run /epic-status to fill this in."),
   - `## Goal`,
   - `## Stories` — the Phase 4 table,
   - `## Story graph` — Mermaid `graph LR` of story `depends_on`, nodes labelled `S01[S01 · Title]`,
   - `## Story waves`,
   - `## Acceptance criteria` — every `S<NN>.AC<n>` listed under its story,
   - `## Tasks` — placeholder: "No tasks yet. Run `/story-to-tasks <out> --ready` or name stories, e.g.
     `/story-to-tasks <out> S01 S02`.",
   - `## Risks`, `## Open questions`.

   `/story-to-tasks` later rewrites only the `## Tasks` section; `/epic-status` only `## Status`. Keep these
   headings exactly.

Keep the epic source file untouched.

### Phase 6 — Report back

Reply in chat with: number of stories, waves, anything blocked or flagged, the stories ready to decompose now
(wave 1, status `ready`), the exact next command, and links to `README.md` and the story files. Keep it short.

## Quality bar (self-check before Phase 4)

- Does each story deliver something observable on its own once its dependencies are done?
- Is every acceptance criterion testable by someone who has not read the epic?
- Is every in-scope item covered, and nothing out-of-scope included?
- Is every `depends_on` edge a real prerequisite? Is the graph acyclic and as flat as possible?
- Is any story `XL`, or likely to need more than ~10 tasks? Split it.
- Does any story contradict a rule in CLAUDE.md / AGENTS.md? Fix it.

## Inline templates (fallback when `templates/` is missing)

### Epic input shape

```
# Epic: <EPIC-ID> — <Epic title>
## Goal
## Scope            (In scope: … / Out of scope: …)
## Constraints      (optional)
## Stories          (optional — leave empty to have stories generated)
### S1 — <Story title>
As a <role>, I want <capability> so that <benefit>.
Acceptance criteria:
- [ ] Given …, when …, then …
## Open questions   (optional)
```

### Story output shape

```
---
id: <EPIC-ID>-S<NN>
epic: <EPIC-ID>
title: <≤ 70 chars>
status: ready           # draft | ready | decomposed | in-progress | done | blocked
size: M                 # S | M | L. Never XL — split instead.
depends_on: []          # story IDs
wave: 1
tasks: []               # filled by /story-to-tasks
---
# <Title>
## Narrative            As a <role>, I want <capability> so that <benefit>.
## Acceptance criteria  - [ ] AC1 — Given …, when …, then …
## Landing zone         systems, existing vs new code, shared foundations, Editor work (from recon)
## Dependencies         why each depends_on edge exists
## Notes
## Open questions
```
