# US-12-07: Extract ModulationGraph service

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want LFO and modulation edge state in one module so that modulation CRUD and playback snapshot rebuild are not scattered through `ProjectEngine`.

## Goal

`ModulationGraph` owns `lfos_`, `modEdges_`, `lfoPlayback_[]`, `modEdgePlayback_[]`, and `rebuildLfoPlaybackLocked()`.

## Background

- Methods: `createLfo`, `removeLfo`, `updateLfoParam`, `assignModulation`, `removeModulation`
- Serialization: lfos + modEdges in `toProjectFileData` / load
- Arrangement mixer reads `lfoPlaybackCount_`, `modEdgePlayback_` atomics — interface must stay

## Scope

- [x] Extract modulation state + rebuild into `ModulationGraph`
- [x] `ProjectEngine` forwards LFO/mod API
- [x] Snapshot + project file include modulation via graph getters
- [x] Cascade delete: removing LFO removes its edges (behavior unchanged)

## Out of scope

- New LFO waveforms
- Modulation UI changes
- Per-sample modulation beyond current `DeviceChain` behavior

## Acceptance criteria

- [x] `lfo_modulation_test.cpp` passes
- [x] Save/load preserves LFOs and edges
- [x] Audio-thread LFO buffer layout unchanged for `ArrangementMixer`

## Demo script (developer, ~5 min)

1. Run `lfo_modulation_test`.
2. Assign gain modulation in app — still audible (manual optional).

## Tests required

- [x] `lfo_modulation_test.cpp`
- [x] Serialization section of same test

## Depends on

US-12-00

## Status

Done
