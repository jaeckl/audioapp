# US-12-05: Extract TrackRepository + ClipRepository

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want track and clip CRUD in dedicated modules so that `ProjectEngine` does not own arrangement editing logic mixed with audio rendering.

## Goal

`TrackRepository` handles tracks + selection; `ClipRepository` handles MIDI/sample clip CRUD, move, duplicate, quantize-on-commit hooks — `ProjectEngine` forwards public API unchanged.

## Background

- Methods today: `addTrack`, `deleteTrack`, `selectTrack`, `createMidiClip`, `setMidiClipNotes`, `createSampleClip`, `moveClip`, `setClipLength`, `deleteClip`, `duplicateClip`
- ID counters (`nextTrackNum_`, `nextClipNum_`, etc.) belong with repositories
- `ensureTrackGainDevicesLocked` moves to track insert policy

## Scope

- [ ] `TrackRepository` — track CRUD, selection, auto-insert `track_gain` on new track
- [ ] `ClipRepository` — MIDI + sample clip CRUD, move between tracks, duplicate
- [ ] `ProjectModel` holds repositories' data or repositories hold `std::vector<Track>` with `DeviceSlot` chains
- [ ] `ProjectEngine` public method signatures unchanged
- [ ] `recomputeIdCountersLocked` lives in repository or `ProjectModel`

## Out of scope

- Piano roll / Flutter UI
- New clip types
- Device chain reorder (US-08-10 backlog)

## Acceptance criteria

- [ ] Track/clip behavior identical — same IDs, same clip bounds rules
- [ ] `commitCapture` (live) still creates MIDI clip correctly (integration with US-12-10)
- [ ] Existing clip-related tests pass

## Demo script (developer, ~5 min)

1. Run tests touching clips if any; run Flutter widget test for add MIDI clip.

## Tests required

- [ ] C++ tests for clip move/duplicate edge cases (add if missing)
- [ ] Flutter `widget_test` — add MIDI clip flow

## Depends on

US-12-01 (device slots on tracks — full integration after US-12-03; may stub flat adapter until then)

## Status

Todo
