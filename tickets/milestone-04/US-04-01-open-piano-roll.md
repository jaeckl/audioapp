# US-04-01: Open piano roll

## Type

Feature

## Milestone

Milestone 04 — Mobile MIDI editing

## User story

As a **user**, I can **tap a MIDI clip** on the timeline and open a **mobile-friendly piano roll** to see its notes.

## Goal

Navigate from arrangement → clip editor without losing context; notes loaded from engine.

## Background

- [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- AGENT.md §6.2

## UX flow

1. User taps MIDI clip block on timeline.
2. Piano roll opens (full-screen or large overlay).
3. Existing notes render at correct pitch/beat grid.
4. User taps **Close** / back → returns to arrangement; clip still visible.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Scrollable grid on phone; edge-to-edge where appropriate; back gesture works |

## Scope

- Clip tap handler in arrangement
- Piano roll widget: pitch rows, beat columns, note blocks
- Read-only display of notes from snapshot (editing in US-04-02/03)
- `clipId` passed to editor

## Out of scope

- Note editing gestures (US-04-02/03)
- Multi-clip editor

## Acceptance criteria

- [x] Tap clip opens piano roll
- [x] Notes match engine data (pitch, start, length)
- [x] Close returns to arrangement
- [x] Widget test: open/close flow
- [x] Layout usable on phone (scroll)

## Demo script (on-device, ~30s)

1. Create clip with notes → tap clip → see notes in roll → close → back to timeline.

## Tests required

- [x] Widget tests
- [x] Manual on device

## User-visible result

Clear path from timeline into musical editing.

## Depends on

US-03-01


## Companion stories

- [UX/UI](US-04-01-ux-ui.md)
- [Interaction](US-04-01-interaction.md)

## Status

**Done**
