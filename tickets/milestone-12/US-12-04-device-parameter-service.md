# US-12-04: Extract DeviceParameterService — remove setDeviceParameter god method

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want device parameter updates routed through the registry so that `ProjectEngine::setDeviceParameter` is not a 200-line if-else chain.

## Goal

`ProjectEngine::setDeviceParameter` becomes ~10 lines: find slot → `registry.find(type)->setParameter()` → rebuild snapshots.

## Background

- ~69 `device->type` branches in `ProjectEngine.cpp` today
- Shared params (`gain`, `pan`, `bypass`) handled on `DeviceSlot` before delegating type-specific params
- Must trigger same rebuild hooks: `syncActiveFrequencyLocked` for oscillator frequency, `rebuildTrackPlaybackLocked` for all

## Scope

- [ ] `DeviceParameterService` (or methods on registry) — `setFloat(deviceId, paramId, value)`, `setString(...)`
- [ ] Move all param validation/clamping into device type classes (US-12-02)
- [ ] `ProjectEngine::setDeviceParameter` / `setDeviceStringParameter` delegate
- [ ] Delete old if-else body from `ProjectEngine.cpp`
- [ ] Verify modulation assign still targets valid param ids (optional validation hook on `IDeviceType::modulatableParams()`)

## Out of scope

- New parameters
- UI validation messages

## Acceptance criteria

- [ ] `ProjectEngine.cpp` contains zero `parameterId ==` checks for device-specific params
- [ ] Every param path covered by existing Flutter widget tests still works
- [ ] `lfo_modulation_test` passes (modulation CRUD unchanged)
- [ ] Grep: no `device->type ==` in `ProjectEngine.cpp` except possibly live/build paths until US-12-10

## Demo script (developer, ~5 min)

1. Grep confirms dispatch removed from ProjectEngine.
2. Run Flutter `device_level_panel_test`, engine bridge tests.

## Tests required

- [ ] Param routing tests per device (can extend US-12-02 tests)
- [ ] `lfo_modulation_test.cpp`
- [ ] Flutter bridge tests

## Depends on

US-12-03

## Status

Todo
