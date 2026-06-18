# US-12-01: IDeviceType interface + DeviceRegistry

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want a registry that maps device type strings to handler objects so that `ProjectEngine` stops hard-coding device type lists in multiple methods.

## Goal

`DeviceRegistry` resolves `"simple_oscillator"` → `OscillatorDeviceType` and provides a single lookup used by insert, parameter, serialization, and playback-build paths.

## Background

- [ADR-0007](../../docs/adr/ADR-0007-project-engine-decomposition.md)
- Today: string literals scattered in `addDeviceToTrack`, `setDeviceParameter`, `rebuildTrackPlaybackLocked`, `buildLiveInstrumentForTrack`
- Registry is **control-thread only**; audio thread unchanged

## Scope

- [ ] Add `engine_juce/include/audioapp/devices/IDeviceType.hpp` — interface (see refactor plan)
- [ ] Add `DeviceRegistry` — `registerType`, `find(typeId)`, `knownTypes()`
- [ ] Register four built-in types (implementations may stub param/JSON until US-12-02)
- [ ] `addDeviceToTrack` uses registry for type validation + factory (delegate to type's `createDefault`)
- [ ] Unit test: unknown type rejected; known type creates instance with correct `typeId`

## Out of scope

- Removing flat `Device` struct (US-12-03)
- Full parameter dispatch (US-12-04)
- Playback snapshot changes (US-12-08)

## Acceptance criteria

- [ ] `DeviceRegistry` is the only place that enumerates supported device type strings
- [ ] `addDeviceToTrack(..., "unknown")` returns empty / false
- [ ] Existing device insert behavior unchanged for four built-in types
- [ ] All existing C++ + Flutter tests pass

## Demo script (developer, ~5 min)

1. Run new `device_registry_test`.
2. Run `device_chain_test` — unchanged output.

## Tests required

- [ ] `device_registry_test.cpp` — lookup, factory, unknown type
- [ ] Existing engine tests green

## Realtime/performance notes

Registry used on control thread only. No audio callback impact.

## Documentation updates

- `project_engine_refactor.md` — link to `IDeviceType.hpp` once created

## Depends on

US-12-00

## Status

Todo
