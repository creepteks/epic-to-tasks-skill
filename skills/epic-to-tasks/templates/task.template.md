---
id: <EPIC-ID>-T<NN>
epic: <EPIC-ID>
story: <S#>
title: <Imperative, ≤ 70 chars, e.g. "Wire Battle.StartBattle to MorningTimeElapsed">
status: todo            # todo | in-progress | review | done | blocked
size: S                 # XS (<30 min) | S (<1 h) | M (1–2 h). Never larger — split instead.
depends_on: []          # e.g. [EPIC-T01, EPIC-T02]
branch: feature/<epic-slug>/t<NN>-<task-slug>
files:
  create: []
  modify: []
  editor_steps: false   # true if manual Unity Editor work is required (prefab/scene wiring)
---

# <Title>

## Context

2–4 sentences. Why this task exists, which story it serves, and what the surrounding system looks like
*today* (name the real classes/files you found during recon). Assume the implementer has read
CLAUDE.md / AGENTS.md but has **not** read the epic.

## Scope

Do exactly this and nothing else:

1. ...
2. ...

Out of scope for this task (handled elsewhere or deliberately deferred):
- ...

## Implementation notes

- Concrete guidance: which existing pattern to copy (`see Foo.cs:Bar()`), which installer method to bind in,
  which definition asset holds the tunable numbers, which event to subscribe/unsubscribe.
- Call out project rules that are easy to violate here (e.g. `[Inject] Init` for MonoBehaviours, no `?.` on
  UnityEngine.Object, every `+=` needs a `-=`).

## Acceptance criteria

- [ ] Compiles with zero new warnings in Unity console / Rider.
- [ ] <Behavioural criterion traced from the story's acceptance criteria>
- [ ] <...>

## Verification

How the implementer proves it works **without** a test suite (this project has none):

1. Compile check.
2. Reasoned walkthrough of the call path: `A → B → C`.
3. Manual Editor steps, if any (list them precisely; the implementer reports them back rather than editing
   `.unity`/large prefabs by text).
4. Anything that could not be verified must be stated explicitly in the final report.

## Definition of done

- Single commit on `<branch>` with an imperative, sentence-case message (e.g. `Add X to Y`).
- All `files.create`/`files.modify` above touched; no unrelated files changed.
- `.meta` files present for any new asset/script.
- Final report lists: what changed, what was verified, what was not, and any follow-up suggestions.
