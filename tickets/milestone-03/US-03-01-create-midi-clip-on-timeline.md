# US-03-01: Create MIDI clip on timeline

## Type

Feature

## Milestone

Milestone 03 — MIDI clip playback

## User story

As a **user**, I can **create a MIDI clip** on the selected track and see it on the timeline at a chosen position and length.

## Goal

Clip entity in C++ with stable ID and visual block on arrangement.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- AGENT.md §6.2

## UX flow

1. Select track.
2. Tap **Add clip** (or equivalent) on timeline.
3. Clip appears at default start/length (e.g. bar 1, 4 beats).
4. Clip block shows horizontal extent on timeline.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Clip block tappable; visible on phone-width timeline |

## Scope

- `createMidiClip(trackId, startBeat, lengthBeats)`
- Arrangement clip rendering
- Seed with default note(s) or empty (document; US-03-03 needs ≥1 note for demo)

## Out of scope

- Piano roll (M04)
- Audio clips

## Acceptance criteria

- [x] Create clip on selected track
- [x] Correct position/length on timeline
- [x] Stable clip ID in C++
- [x] juce::JSON serialization round-trip for clip metadata
- [x] Flutter widget test

## Demo script (on-device, ~30s)

1. Add track → add clip → see block on timeline.

## Tests required

- [x] C++ unit tests
- [x] Widget tests
- [x] Manual on device

## User-visible result

Timeline shows a MIDI region — arrangement is real.

## Depends on

US-02-02


## Companion stories

- [UX/UI](US-03-01-ux-ui.md)
- [Interaction](US-03-01-interaction.md)

## Status

**Done**
