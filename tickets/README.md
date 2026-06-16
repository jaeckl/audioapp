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

Per AGENT.md §17: acceptance criteria met, tests added, docs updated, app builds, Android smoke path works. Audio stories require a real JUCE path and realtime safety review.
