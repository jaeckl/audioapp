# US-03-03: MIDI clip playback

## Type

Feature

## Milestone

Milestone 03 — MIDI clip playback

## User story

As a **user**, I press **Play** and hear the **notes in my MIDI clip** through the track’s oscillator at the project BPM, including when the clip loops.

## Goal

MIDI scheduling from clip data → device chain → speaker. Real JUCE/AAudio path.

## Background

- [audio_graph.md](../../docs/architecture/audio_graph.md)
- [MidiClipPlayback](../../engine_juce/include/audioapp/MidiClipPlayback.hpp)

## UX flow

1. User has track + MIDI clip with at least one note.
2. Tap **Play** → hears note(s) at correct pitch/time for BPM.
3. If clip region loops in arrangement, pattern repeats.
4. Tap **Stop** → immediate silence.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Audible on device speaker/headphones; no silent “success” without sound |

## Scope

- `activeMidiPitchAtBeat`, scheduler in audio path
- Clip `notes[]` from C++ model
- Looping when arrangement clip length > musical content
- Oscillator responds to scheduled MIDI pitch

## Out of scope

- Piano roll editing (M04)
- Sampler (M06)
- Velocity-sensitive complex synth

## Acceptance criteria

- [x] Notes fire at correct beats for 120 BPM (or project BPM)
- [x] Pitch matches clip note data
- [x] Loop region repeats pattern
- [x] C++ MIDI scheduling tests pass
- [x] Silence when stopped
- [x] No heap alloc in scheduler hot path

## Demo script (on-device, ~45s)

1. Create clip with 3–4-note pattern → Play → hear melody/rhythm.
2. Stop → change frequency on strip → Play → same rhythm, different timbre.

## Tests required

- [x] `midi_clip_playback_test.cpp`
- [ ] Offline golden render (future hardening)
- [x] Manual on device

## User-visible result

**Wow:** arrangement plays back — not just a test beep.

## Realtime/performance notes

Preallocated scheduling; no JSON/logging on audio thread.

## Depends on

US-03-01, US-03-02


## Companion stories

- [UX/UI](US-03-03-ux-ui.md)
- [Interaction](US-03-03-interaction.md)

## Status

**Done**
