# US-04-02: Edit notes in piano roll

## Type

Feature

## Milestone

Milestone 04 — Mobile MIDI editing

## User story

As a **user**, I can add, move, resize, and delete notes with grid snapping in the piano roll and hear the changes when I play back.

## Goal

Note mutations as engine commands; playback reflects edits.

## Background

- [project_model.md](../../docs/architecture/project_model.md)

## Scope

- Commands: `updateMidiClipNotes` (or granular note ops)
- Gestures: tap add, drag move, resize handles, delete
- Grid snapping
- Safe apply to engine; playback uses updated notes

## Out of scope

- Velocity editing
- Advanced quantization, swing, MIDI CC, MPE

## Acceptance criteria

- [ ] Add note at grid position
- [ ] Move note (pitch/time)
- [ ] Resize note length
- [ ] Delete note
- [ ] Playback reflects edits after safe state update
- [ ] C++ tests for note mutation + serialization
- [ ] Flutter tests for gesture → command dispatch

## Tests required

- [ ] C++ unit tests
- [ ] Widget tests
- [ ] Manual melody/rhythm smoke on device

## User-visible result

User writes a simple melody or rhythm on mobile and hears it.

## Depends on

US-04-01

## Status

**Todo**
