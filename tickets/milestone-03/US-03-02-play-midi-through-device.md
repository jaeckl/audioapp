# US-03-02: Play MIDI through device

## Type

Feature

## Milestone

Milestone 03 — MIDI clip playback

## User story

As a **user**, I press Play and hear the MIDI clip’s notes through the track’s oscillator at fixed BPM, including when the clip region is looped.

## Goal

MIDI scheduling + playhead + device chain produces audible pattern.

## Background

- [audio_graph.md](../../docs/architecture/audio_graph.md)
- [realtime_audio_rules.md](../../docs/architecture/realtime_audio_rules.md)

## Scope

- Transport playhead at fixed BPM
- MIDI clip note scheduling into device chain
- Looping when clip region extended in arrangement
- Playhead display (throttled updates to Flutter)

## Out of scope

- Note editing UI (M04)
- Sampler (M06)

## Acceptance criteria

- [ ] Play schedules notes at correct times for BPM
- [ ] Oscillator produces sound from MIDI note on events
- [ ] Extending clip loop region repeats pattern
- [ ] C++ MIDI scheduling tests
- [ ] Silence when stopped
- [ ] Playhead visible in UI

## Tests required

- [ ] C++ MIDI scheduling unit tests
- [ ] Offline render test for known note pattern
- [ ] Manual device smoke

## User-visible result

User hears their clip play through the instrument strip.

## Realtime/performance notes

- Preallocated MIDI event buffers per block
- No allocation in scheduler hot path

## Depends on

US-03-01

## Status

**Todo**
