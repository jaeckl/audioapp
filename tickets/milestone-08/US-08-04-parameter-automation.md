# US-08-04: Parameter automation

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **user**, I can add **simple automation** to a device parameter (e.g. filter cutoff) so the sound changes over playback.

## Goal

Automation data in project model + evaluation on playback — survives save/load.

## Background

- AGENT.md §8 Automation
- [project_model.md](../../docs/architecture/project_model.md)

## UX flow

1. Select device parameter (e.g. Filter cutoff) → **Automate** (or add automation lane).
2. MVP: step or few breakpoints over 4–8 bars (simple UI — not full curve editor).
3. Play → parameter moves during playback.
4. Save/load → automation restored.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Simple breakpoint list or lane tap OK for MVP; must be demonstrable in 60s |

## Scope

- Automation targets by stable parameter ID
- Lane or clip holding `{ beat, value }[]`
- Evaluation on control thread before audio block (or RT-safe snapshot)
- juce::JSON serialization

## Out of scope

- Bezier curve editor
- Tempo maps

## Acceptance criteria

- [ ] User can assign automation to one parameter
- [ ] Playback applies automation values over time
- [ ] Audible change (e.g. filter opens)
- [ ] Save/load round-trip
- [ ] C++ evaluation unit tests
- [ ] Architecture doc updated

## Demo script (on-device, ~60s)

1. Filter with cutoff automation ramp → Play → hear sweep.

## Tests required

- [ ] C++ automation evaluation tests
- [ ] Serialization tests
- [ ] Manual on device

## User-visible result

Sound evolves during playback — step toward a real DAW.

## Depends on

US-08-03


## Companion stories

- [UX/UI](US-08-04-ux-ui.md)
- [Interaction](US-08-04-interaction.md)

## Status

**Todo**
