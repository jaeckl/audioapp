# Tickets

Work is planned as **user stories** (one vertical slice per story). Each story maps to a milestone and follows the template in [AGENT.md](../AGENT.md) §14.

## Roadmap

See [docs/milestones/roadmap.md](../docs/milestones/roadmap.md) for the full phase/milestone plan.

## Naming

| Pattern | Example |
|---------|---------|
| User story ID | `US-03-02` |
| File | `US-03-02-play-midi-through-device.md` |
| Folder | `tickets/milestone-03/` |

## Status

| Milestone | Stories | Notes |
|-----------|---------|-------|
| M00 | US-00-01, US-00-02 | Bootstrap complete |
| M01 | US-01-01 | Next up — real JUCE audio |
| M02–M09 | See roadmap | Planned |

## Definition of done

Per [AGENT.md](../AGENT.md) §17:

- Acceptance criteria **and** the ticket’s **demo script** pass on Android device
- Full vertical slice: UX (dialogs, feedback, errors) + engine + bridge + tests
- JUCE JSON and system document pickers where applicable (§2.6)
- No follow-up ticket needed to complete the same user-facing story

Audio stories: real JUCE path + realtime safety review.

Persistence stories: save → kill app → load round-trip on device.
