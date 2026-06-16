# US-03-01: Create MIDI clip on timeline

## Type

Feature

## Milestone

Milestone 03 — MIDI clip playback

## User story

As a **user**, I can create a MIDI clip on a track and see it on the timeline at a chosen position and length.

## Goal

MIDI clip entity in C++ project model with visual representation in arrangement.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- AGENT.md §6.1–6.2

## Scope

- Command: `createMidiClip` (track id, start beats, length beats)
- Clip region rendering on timeline
- Seed clip with at least one note (for US-03-02) or empty + add in editor later

## Out of scope

- Piano roll editing (M04)
- Audio clips
- Tempo automation

## Acceptance criteria

- [ ] User can create MIDI clip on selected track
- [ ] Clip appears at correct horizontal position/length
- [ ] Clip data stored in C++ with stable clip ID
- [ ] Flutter tests clip creation UI flow
- [ ] C++ serialization round-trip for clip metadata

## Tests required

- [ ] C++ unit tests
- [ ] Widget tests
- [ ] Manual smoke

## User-visible result

MIDI clip visible on arrangement.

## Depends on

US-02-02

## Status

**Todo**
