# Feature Brief: Milestone 16 — Modulation & Automation Test Coverage

## Goal

Close critical gaps in modulation and automation test coverage for both the C++ audio
engine and the Flutter UI, ensuring all modulation/automation paths are exercised
end-to-end before the next release.

## Scope

- **Engine (C++):** 14 new test files covering stacked LFOs, effect-device modulation,
  common-param modulation, percussion modulation, ADSR envelope modulator, LFO polarity,
  LFO sync-to-BPM, combined modulation+automation on gain/pan, and effect-device
  automation.
- **Flutter (Dart):** 4 new test files covering bridge method tests for LFO/modulation
  CRUD, widget tests for modulation UI components, JSON round-trip parsing for
  LfoSnapshot/ModulationEdgeSnapshot, and modulation persistence save/load.

## Non-goals

- No modification to engine production code (tests only)
- No e2e/integration tests (integration_test/ remains empty; Flutter tests use mocked bridge)
- No new engine features or API changes
- No performance benchmarks

## Test infrastructure

- Engine tests: `EngineHost::renderOffline()` + audio analysis helpers (rms, peak,
  highFrequencyEnergy, filterSweepDetected) — all patterns already proven in
  `modulation_e2e_test.cpp`, `automation_filter_sweep_test.cpp`, etc.
- Flutter tests: mocked `MethodChannel` on `com.audioapp.daw/engine` — pattern proven in
  `engine_bridge_test.dart`.
- Test IDs: `US-16-01` through `US-16-18`, each mapping to one test file.