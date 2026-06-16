# Tickets

Work is planned as **user stories** — one shippable vertical slice per story (or a tight sequence within a milestone). Template: [AGENT.md](../AGENT.md) §14.

## Roadmap

[docs/milestones/roadmap.md](../docs/milestones/roadmap.md)

## Naming

| Pattern | Example |
|---------|---------|
| User story ID | `US-06-02` |
| Feature file | `US-06-02-import-sample-system-picker.md` |
| UX/UI companion | `US-06-02-ux-ui.md` |
| Interaction companion | `US-06-02-interaction.md` |
| Folder | `tickets/milestone-06/` |

Every user-facing feature has **three** linked tickets. See [COMPANION_STORIES.md](COMPANION_STORIES.md) and AGENT.md §14.1.

Regenerate companions after manifest changes:

```bash
python tools/gen_companion_tickets.py
```

## Story counts (current)

| Milestone | Stories | Status |
|-----------|---------|--------|
| M00 | 3 | Done |
| M01 | 1 | Done |
| M02 | 3 | Done |
| M03 | 3 | Done |
| M04 | 3 | Done |
| M05 | 2 | Done |
| M06 | 5 | **Next** |
| M07 | 2 | Planned |
| M08 | 4 | Planned |
| M09 | 2 | Planned |

**Companion sub-stories:** each user-facing feature also has `US-XX-YY-ux-ui.md` and `US-XX-YY-interaction.md` (50 companions for 25 features). See [COMPANION_STORIES.md](COMPANION_STORIES.md).

## Definition of done

Per AGENT.md §17 + §2.8:

- Acceptance criteria and **demo script** pass on Android device
- Full slice: UX (dialogs, feedback, errors) + engine + bridge + tests
- `juce::JSON` / system pickers where applicable
- No follow-up ticket to finish the same user-facing feature

## PO decisions (M06–M09)

| Topic | Decision |
|-------|----------|
| M06 library | Bundled starter pack **+** user import; **audio clips on timeline** (insert, waveform, playhead audition) |
| M07 trim UI | **Waveform + trim handles** required |
| M08 effects | **One story per effect** (Gain → Pan → Filter) |
| M09 export | **System save dialog** (like M05) |
