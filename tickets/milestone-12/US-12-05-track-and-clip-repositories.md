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

- [x] `TrackRepository` — track CRUD, selection, auto-insert `track_gain` on new track
- [x] `ClipRepository` — MIDI + sample clip CRUD, move between tracks, duplicate
- [x] `TrackModel.hpp` — shared `Track`, `MidiClip`, `SampleClip` types
- [x] `ProjectEngine` public method signatures unchanged
- [x] `recomputeIdCountersLocked` delegates track/device + clip counters to repositories

## Out of scope

- Piano roll / Flutter UI
- New clip types
- Device chain reorder (US-08-10 backlog)

## Acceptance criteria

- [x] Track/clip behavior identical — same IDs, same clip bounds rules
- [x] `commitCapture` (live) still creates MIDI clip correctly (integration with US-12-10)
- [x] Existing clip-related tests pass

## Demo script (developer, ~5 min)

1. Run tests touching clips if any; run Flutter widget test for add MIDI clip.

## Tests required

- [x] C++ `track_clip_repository_test.cpp` — move, duplicate, delete, length
- [x] Flutter `widget_test` — add MIDI clip flow

## Depends on

US-12-03

## Status

Done
