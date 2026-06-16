# US-02-03: Oscillator on device strip

## Type

Feature

## Milestone

Milestone 02 — Track & device strip

## User story

As a **user**, I see an **oscillator** on the device strip for my selected track and can **change its frequency** so Play sounds different.

## Goal

First real instrument control — parameter change in UI → C++ → audible on Play.

## Background

- [device_model.md](../../docs/architecture/device_model.md)
- [audio_graph.md](../../docs/architecture/audio_graph.md)
- AGENT.md §2.1, §2.6

## UX flow

1. Select track with oscillator device (auto-added on track create).
2. Device strip shows oscillator card with **frequency** control (slider).
3. User drags slider → value updates in UI.
4. User taps **Play** → hears tone at new frequency.
5. User taps **Stop** → silence.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Slider usable with thumb; value label readable; no desktop-only hover |

## Scope

- `addDeviceToTrack` / default oscillator on new track
- `setDeviceParameter(deviceId, "frequency", value)`
- `TestOscillator` uses frequency from project state
- Serialization of `parameters.frequency` in `project.json` (juce::JSON)

## Out of scope

- Multiple devices per track (M08+)
- Sampler (M06)

## Acceptance criteria

- [x] Oscillator visible on strip for selected track
- [x] Frequency slider dispatches bridge command
- [x] Play at 440 Hz vs ~260 Hz is clearly different by ear
- [x] C++ owns parameter; Flutter is projection only
- [x] `project.json` round-trip preserves frequency
- [x] No audio-thread JSON or bridge calls

## Demo script (on-device, ~45s)

1. Add track → select → set frequency low → Play → hear low tone.
2. Stop → raise frequency → Play → hear higher tone.

## Tests required

- [x] C++ parameter + serialization tests
- [x] Flutter bridge tests
- [x] Manual on device

## User-visible result

**Wow:** the strip actually controls sound — first “I’m making music” moment.

## Realtime/performance notes

Frequency read from snapshot on audio thread; no locks in callback.

## Depends on

US-02-02, US-01-01

## Status

**Done**
