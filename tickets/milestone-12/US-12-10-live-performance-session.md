# US-12-10: Extract LivePerformanceSession

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want live note input, capture, and live instrument preview separated from arrangement playback so that play-mode logic does not duplicate device knowledge in `ProjectEngine_live.cpp`.

## Goal

`LivePerformanceSession` owns `LivePerformanceMixer`, capture buffer, record arm, and `buildLiveInstrumentForTrack` via device registry.

## Background

- `ProjectEngine_live.cpp` — `noteOn`, `noteOff`, `commitCapture`, `readLiveMix`, pitch/mod wheels
- `buildLiveInstrumentForTrack` duplicates per-type field copies — must use `IDeviceType::buildLiveInstrument`
- Capture converts to MIDI clip via `ClipRepository` (US-12-05)

## Scope

- [ ] Extract live performance into `LivePerformanceSession`
- [ ] `buildLiveInstrumentForTrack` → registry dispatch
- [ ] `ProjectEngine` forwards live API; session holds reference to selected track + device chain
- [ ] Capture → `ClipRepository::createMidiClip` + `setNotes`
- [ ] Delete device-type switches from `_live.cpp`

## Out of scope

- New play surfaces (M10 play UI stories)
- MPE

## Acceptance criteria

- [ ] Live note preview audible for sampler/synth/oscillator tracks
- [ ] Capture commit creates MIDI clip with recorded notes
- [ ] `subtractive_synth_test` live section passes
- [ ] No `device.type ==` in live module

## Demo script (developer, ~10 min)

1. Run `subtractive_synth_test` live mix section.
2. Manual: play mode note → hear sound (optional on device).

## Tests required

- [ ] `subtractive_synth_test.cpp` live section
- [ ] Add `live_performance_test.cpp` for capture timing if feasible

## Depends on

US-12-02, US-12-05

## Status

Todo
