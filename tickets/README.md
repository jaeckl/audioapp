# Tickets

Work is planned as **user stories** — one shippable vertical slice per story (or a tight sequence within a milestone). Template: [AGENT.md](../AGENT.md) §14.

## Roadmap

[docs/milestones/roadmap.md](../docs/milestones/roadmap.md)

## Naming

| Pattern | Example |
|---------|---------|
| User story ID | `US-06-02` |
| File | `US-06-02-import-sample-system-picker.md` |
| Folder | `tickets/milestone-06/` |

## Story counts (current)

| Milestone | Stories | Status |
|-----------|---------|--------|
| M00 | 3 | Done |
| M01 | 1 | Done |
| M02 | 3 | Done |
| M03 | 3 | Done |
| M04 | 3 | Done |
| M05 | 2 | Done |
| M06 | 4 | Next |
| M07 | 2 | Planned |
| M08 | 4 | Planned |
| M09 | 2 | Planned |

## Definition of done

Per AGENT.md §17 + §2.8:

- Acceptance criteria and **demo script** pass on Android device
- Full slice: UX (dialogs, feedback, errors) + engine + bridge + tests
- `juce::JSON` / system pickers where applicable
- No follow-up ticket to finish the same user-facing feature

## PO decisions (M06–M09)

| Topic | Decision |
|-------|----------|
| M06 library | Bundled starter pack **+** user import (SAF) |
| M07 trim UI | **Waveform + trim handles** required |
| M08 effects | **One story per effect** (Gain → Pan → Filter) |
| M09 export | **System save dialog** (like M05) |
