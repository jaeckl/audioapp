# US-10-01: Device chain variant refactor

## Type

Refactor

## Milestone

Milestone 10 — Device chain architecture

## User story

As a **developer**, I want each device type to own its parameter struct and process/modulation logic so that adding new device types (reverb, delay, filter, etc.) doesn't require editing `DeviceNodePlayback`'s flat struct, the modulation if-else chain in `processDeviceChain`, or the per-device copy logic in `rebuildTrackPlaybackLocked`.

## Goal

Replace the monolithic `DeviceNodePlayback` struct (50 fields, many unused per device type) with a `std::variant<OscillatorParams, SamplerParams, SubtractiveSynthParams, TrackGainParams>`, and refactor modulation + processing into per-type overloads dispatched by `std::visit`. Zero runtime cost (variant size = largest member, visit compiles to jump table). All 6 C++ tests pass, Flutter 51/51 pass.

## Background

- `DeviceNodePlayback` has grown by accretion: 50 fields, only 3-10 used per device kind
- The modulation if-else (lines 102-173 in `DeviceChain.cpp`) must be updated for every new parameter
- The `rebuildTrackPlaybackLocked` if-else chain (lines 1392-1452 in `ProjectEngine.cpp`) enumerates every field separately per device type
- `std::variant` + `std::visit` give zero-cost per-type dispatch on the audio thread (no virtual, no heap)

## Scope

- [x] Extract per-device params structs (`OscillatorParams`, `SamplerParams`, `TrackGainParams`, `SubtractiveSynthParams` already exists)
- [x] Define `using DeviceVariantParams = std::variant<...>`
- [x] Refactor `DeviceNodePlayback` to hold `DeviceVariantParams` instead of flat fields
- [x] Refactor `processDeviceChain` modulation block into per-type `applyModulation` overloads + visitor
- [x] Refactor `processDeviceChain` processing `switch` into per-type `processDevice` functions + visitor
- [x] Update `rebuildTrackPlaybackLocked` to construct per-type variant members
- [x] Update `device_chain_test.cpp`, `subtractive_synth_test.cpp` to use new struct
- [x] All C++ tests pass, all Flutter tests pass
- [ ] Build + deploy to phone

## Out of scope

- Changing the Flutter bridge or project model (control-thread `Device`/`DeviceState` not affected — this is a playback-only refactor)
- Adding new device types (that's a future US)
- Performance optimization beyond maintaining equivalence

## Acceptance criteria

- [ ] `DeviceNodePlayback` no longer has flat fields that are only relevant to specific device types
- [ ] Each device type's params are in a named struct
- [ ] `applyModulation<OscillatorParams>`, `applyModulation<SamplerParams>`, etc. handle modulation per type
- [ ] `process(OscillatorParams, ...)`, `process(SamplerParams, ...)`, etc. replace the giant `switch`
- [ ] All existing C++ tests pass unchanged (same input → same output)
- [ ] All Flutter tests pass
- [ ] No runtime regression on device

## Demo script

Developer-only: run `device_chain_test` and `subtractive_synth_test`.

## Tests required

- [x] `device_chain_test.cpp` — already tests oscillator+gain, sampler, pan
- [x] `subtractive_synth_test.cpp` — already tests subtractive synth chain
- [ ] `lfo_modulation_test.cpp` — already tests modulation

## Realtime/performance notes

- `std::variant` is stack-allocated, same as current flat struct
- `std::visit` compiles to a jump table on the discriminant (same as current `switch` on `kind`)
- Negative: `std::visit` with captures may inhibit some inlining compared to raw switch. If profiling shows regression, can hot-path with manual `switch (index())`.

## Documentation updates

- `docs/architecture/audio_graph.md` if it describes `DeviceNodePlayback`

## Depends on

None

## Status

Todo