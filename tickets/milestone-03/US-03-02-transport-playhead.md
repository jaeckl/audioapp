# US-03-02: Transport playhead

## Type

Feature

## Milestone

Milestone 03 — MIDI clip playback

## User story

As a **user**, I see the **playhead move** across the timeline while playing at fixed BPM so I know where I am in the song.

## Goal

Transport + playhead UI synced to engine at fixed BPM — throttled, smooth enough for mobile.

## Background

- AGENT.md §5.4 Fixed BPM
- [realtime_audio_rules.md](../../docs/architecture/realtime_audio_rules.md)

## UX flow

1. User taps **Play** → playhead advances left-to-right (beat grid).
2. Playhead position updates during playback (coalesced, not every sample).
3. User taps **Stop** → playhead stops; optional reset policy documented.
4. BPM shown in UI matches engine (default 120).

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Playhead visible on phone width; no jank from excessive rebuilds |

## Scope

- C++ `advancePlayhead`, `playheadBeats` in snapshot
- Fixed BPM (no tempo map)
- Flutter playhead indicator on arrangement
- Throttled snapshot/event updates during play

## Out of scope

- Tempo automation
- Audio clip playhead sync (no audio clips yet)

## Acceptance criteria

- [x] Playhead moves while playing
- [x] Stops when transport stops
- [x] BPM fixed and consistent with scheduling
- [x] No platform-channel traffic from audio callback
- [x] Flutter does not rebuild entire tree every frame

## Demo script (on-device, ~30s)

1. Add track + clip → Play → watch playhead move for several beats → Stop.

## Tests required

- [x] C++ playhead advance unit tests
- [x] Manual on device

## User-visible result

Timeline feels alive during playback.

## Depends on

US-02-03, US-03-01


## Companion stories

- [UX/UI](US-03-02-ux-ui.md)
- [Interaction](US-03-02-interaction.md)

## Status

**Done**
