# US-12-02: Per-device control classes (Oscillator, Sampler, TrackGain, SubtractiveSynth)

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want each built-in device to own its parameter schema, defaults, and validation so that sampler ADSR logic never lives in the same file as oscillator frequency logic.

## Goal

Four `*DeviceType` classes implement `IDeviceType` with typed instance structs (`OscillatorInstance`, `SamplerInstance`, etc.) containing **only** fields relevant to that device.

## Background

- Flat `Device` today duplicates 45+ fields across oscillator, sampler, synth
- Parameter ranges/clamps currently inline in `setDeviceParameter`
- Subtractive synth shares amp ADSR field names with sampler but different semantics — typed classes disambiguate

## Scope

- [x] `OscillatorDeviceType` — `frequencyHz` + shared strip params via wrapper
- [x] `SamplerDeviceType` — ADSR, filter, trim/region, `sampleId`
- [x] `TrackGainDeviceType` — gain only (no pan/bypass on utility gain node per current rules)
- [x] `SubtractiveSynthDeviceType` — full synth param set (maps to existing `SubtractiveSynthParams` for playback)
- [x] Each type: `createDefault`, `setParameter`, `setStringParameter`, modulatable param id list
- [x] Each type: `buildPlaybackNode` fills `DeviceNodePlayback` (may delegate to existing helpers)
- [x] Each type: `buildLiveInstrument` where applicable (oscillator, sampler, synth — not track_gain)

## Out of scope

- Replacing `Device` in `Track` struct (US-12-03) — may use adapter layer temporarily
- JSON schema change (still flat fields in project.json until US-12-03 documents migration)
- New DSP

## Acceptance criteria

- [x] No device type class references another type's fields
- [x] `setParameter("filterCutoff", …)` on oscillator returns false
- [x] Defaults match current `addDeviceToTrack` behavior exactly
- [x] `buildPlaybackNode` output matches pre-refactor `rebuildTrackPlaybackLocked` for each type
- [x] Per-type unit tests for param clamping and playback node shape

## Demo script (developer, ~10 min)

1. Run `oscillator_device_type_test`, `sampler_device_type_test`, etc.
2. Run `subtractive_synth_test` — unchanged.

## Tests required

- [ ] One focused C++ test file per device type (or single `device_types_test.cpp` with sections)
- [ ] Regression: `device_chain_test`, `subtractive_synth_test`

## Realtime/performance notes

Playback build runs on control thread under mutex. Output must remain bitwise-equivalent for fixed inputs.

## Documentation updates

- [device_model.md](../../docs/architecture/device_model.md) — add "M12 implementation" note pointing to `*DeviceType` classes

## Depends on

US-12-01

## Status

Todo
