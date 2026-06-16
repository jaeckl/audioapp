# US-04-03: Move and resize notes (grid snap)

## Type

Feature

## Milestone

Milestone 04 — Mobile MIDI editing

## User story

As a **user**, I can **drag notes** to change pitch/time and **resize** note length with grid snapping so editing feels precise on mobile.

## Goal

Complete piano roll editing — move + resize with snap; playback matches.

## Background

- AGENT.md §2.8 mobile UX quality

## UX flow

1. Open piano roll with existing notes.
2. **Move:** drag note vertically (pitch) and horizontally (time); snaps to grid.
3. **Resize:** drag note end handle; length snaps to grid.
4. Play → updated timing/pitch audible.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Drag gestures reliable; scroll view does not fight vertical drag |

## Scope

- Drag handlers with grid quantize (e.g. 1/16 or 1/8 — document in UI)
- `setMidiClipNotes` after gesture end (not per-frame flood)
- Visual feedback during drag

## Out of scope

- Multi-note selection
- Cut/copy/paste

## Acceptance criteria

- [x] Move note pitch and start beat
- [x] Resize note duration
- [x] Snap to visible grid
- [x] Playback reflects edits
- [x] C++ + Flutter tests for gesture → command

## Demo script (on-device, ~60s)

1. Add melody → drag one note higher → Play → pitch changed.
2. Lengthen a note → Play → sustain heard.

## Tests required

- [x] C++ serialization after edits
- [x] Flutter gesture tests
- [x] Manual on device

## User-visible result

**Wow:** write a simple melody on mobile and hear it.

## Depends on

US-04-02


## Companion stories

- [UX/UI](US-04-03-ux-ui.md)
- [Interaction](US-04-03-interaction.md)

## Status

**Done**
