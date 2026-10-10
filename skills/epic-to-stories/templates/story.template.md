---
id: <EPIC-ID>-S<NN>
epic: <EPIC-ID>
title: <≤ 70 chars, e.g. "Battle starts automatically at dawn">
status: ready           # draft | ready | decomposed | in-progress | done | blocked
size: M                 # S (≈1–3 tasks) | M (≈3–6) | L (≈6–10). Never XL — split instead.
depends_on: []          # story IDs, e.g. [EPIC-S01]
wave: 1                 # 1 = no dependencies; n = all dependencies in earlier waves
tasks: []               # task IDs, filled by /story-to-tasks
---

# <Title>

## Narrative

As a <role>, I want <capability> so that <benefit>.

## Acceptance criteria

Stable IDs — tasks trace back to these as `S<NN>.AC<n>`.

- [ ] AC1 — Given ..., when ..., then ...
- [ ] AC2 — ...

## Landing zone

Light recon from `/epic-to-stories`; `/story-to-tasks` deepens it.

- Systems / classes involved (existing or new).
- Shared foundations this story needs or introduces.
- Editor-only work (prefab / scene / asset wiring), if any.

## Dependencies

One line per `depends_on` entry: what this story needs from it. "None" if empty.

## Notes

Links, mockups, constraints that apply only to this story.

## Open questions

Anything unresolved. If a question blocks this story, set `status: blocked` and name it here.
