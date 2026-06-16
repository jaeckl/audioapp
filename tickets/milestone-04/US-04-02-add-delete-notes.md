# US-04-02: Add and delete notes

## Type

Feature

## Milestone

Milestone 04 — Mobile MIDI editing

## User story

As a **user**, I can **add and delete notes** in the piano roll so I can build a pattern quickly on mobile.

## Goal

Tap empty grid → note appears; tap note → delete. Engine updated via `setMidiClipNotes`.

## Background

- Bridge: `setMidiClipNotes` (juce::JSON args)
- AGENT.md §2.6

## UX flow

1. Open piano roll (US-04-01).
2. **Add:** tap empty cell → note at snapped grid position (default length).
3. **Delete:** tap existing note → removed.
4. Close editor → arrangement unchanged except note data.
5. Play → hears new pattern.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Tap targets ≥ 44dp; accidental delete mitigated (single tap delete OK for MVP) |

## Scope

- Gestures → `setMidiClipNotes` with full note list
- C++ replaces clip notes atomically
- Grid snap on add (beat grid from project BPM)
- Default velocity

## Out of scope

- Move/resize (US-04-03)
- Velocity editor per note

## Acceptance criteria

- [x] Add note at grid cell
- [x] Delete note by tap
- [x] Playback reflects changes after command
- [x] C++ tests note mutation + juce::JSON serialization
- [x] Flutter tests dispatch commands

## Demo script (on-device, ~45s)

1. Open roll → add 4 kicks on quarter notes → Play → hear rhythm.
2. Delete one → Play → rhythm changed.

## Tests required

- [x] `midi_clip_notes_test.cpp`
- [x] Flutter tests
- [x] Manual on device

## User-visible result

Sketch beats/melody directly on phone.

## Depends on

US-04-01


## Companion stories

- [UX/UI](US-04-02-ux-ui.md)
- [Interaction](US-04-02-interaction.md)

## Status

**Done**
