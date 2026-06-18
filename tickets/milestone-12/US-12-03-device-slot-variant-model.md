# US-12-03: DeviceSlot variant model — replace flat Device / DeviceState

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want track device chains to store typed device instances instead of a 45-field superset struct so that the project model reflects actual device data.

## Goal

`DeviceSlot` + `DeviceInstance` variant replace internal `ProjectEngine::Device` and public `DeviceState` flat structs. Serialization produces **identical** `project.json` field output as today.

## Background

- `DeviceState` exported in `ProjectSnapshot` for Flutter UI — external JSON shape must stay stable
- `copyDeviceToState` / `copyStateToDevice` are manual 40+ line copies — deleted by this story
- Bridge reads snapshot JSON — no Dart model change if JSON keys unchanged

## Scope

- [x] Define `DeviceSlot` { id, gain, pan, bypassed, DeviceInstance variant }
- [x] Replace `Track::devices` vector type
- [x] `DeviceState` snapshot DTO built via device type `toSnapshotState()` — same keys as today
- [x] `ProjectJson.cpp` read/write uses registry + device types (not field-by-field on flat struct)
- [x] Delete `ProjectEngine::Device` nested struct and copy helpers
- [x] `loadFromProjectFileData` reconstructs variant instances via type JSON readers

## Out of scope

- `projectFormatVersion` bump (keep v1 unless unavoidable)
- Flutter `DeviceSnapshot` Dart class changes
- Parameter dispatch extraction (US-12-04) — may land same PR if tightly coupled

## Acceptance criteria

- [x] `DeviceState` struct removed or reduced to thin DTO populated by registry
- [x] Save → load → snapshot JSON byte-identical for fixture projects (or semantically equal per `project_serialization_test`)
- [x] Flutter 51/51 tests pass without Dart changes
- [x] No remaining 45-field flat device struct in engine

## Demo script (developer, ~10 min)

1. Run `project_serialization_test`.
2. Load golden project JSON from test fixture; snapshot matches expected keys per device type.

## Tests required

- [x] Extend `project_serialization_test.cpp` — all four device types in one project
- [x] Flutter tests unchanged and green

## Documentation updates

- [project_model.md](../../docs/architecture/project_model.md) — note typed device instances internally

## Depends on

US-12-02

## Status

Done
