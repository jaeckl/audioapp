# Architecture

## Module boundaries

```
┌─────────────────────┐     ┌─────────────────────┐
│   engine_juce/       │     │   app_flutter/       │
│   C++ audio engine   │     │   Flutter UI          │
│                      │     │                       │
│  tests/*.cpp         │     │  test/*_test.dart     │
│    (standalone .cpp   │     │    (widget/unit)      │
│     with main())      │     │                       │
└─────────────────────┘     └─────────────────────┘
```

No cross-dependencies between C++ tests and Flutter tests.

## Engine test architecture

Every engine test is a standalone `.cpp` with its own `int main()`:

1. Create `EngineHost`, call `createProject()`
2. Build project state via `Host` API (addTrack, addDeviceToTrack, createLfo, assignModulation, etc.)
3. Render offline: `host.renderOffline(lengthBeats, sampleRate)`
4. Analyze audio output with helper functions: `rms()`, `highFrequencyEnergy()`, `filterSweepDetected()`
5. Return `EXIT_SUCCESS` or `EXIT_FAILURE`

Patterns already proven:
- `modulation_e2e_test.cpp` — 15 tests, reference for stacked LFO, combined mod+auto, cross-track
- `automation_filter_sweep_test.cpp` — automation-only filter sweep
- `subtractive_lfo_filter_test.cpp` — single LFO on subtractive filter
- `autobroken_routing_test.cpp` — cross-track routing + JSON load
- `remove_device_test.cpp` — device removal cleanup
- `lfo_modulation_test.cpp` — LFO CRUD + serialization

## Flutter test architecture

All Flutter tests use mocked `MethodChannel('com.audioapp.daw/engine')`:

1. `setUp`: install mock handler that returns canned snapshots per method
2. Test: call bridge methods or pump widgets, assert on snapshot fields or widget tree
3. `tearDown`: remove mock handler

Pattern proven in `engine_bridge_test.dart`.

## Threading

Engine tests run entirely on the control thread. `renderOffline()` is a synchronous
blocking call that processes the full audio buffer on the calling thread.

Flutter tests run on the Flutter test thread with `TestWidgetsFlutterBinding`.

## Error model

- Engine tests: return `EXIT_FAILURE` with no diagnostic message (existing convention)
- Flutter tests: use `expect()` with descriptive failure messages

## Persistence

- JSON round-trip via `host.getProjectFileJson()` / `parseProjectFileJson()` / `loadProjectFileJson()`
- Flutter snapshot parsing via `ProjectSnapshot.fromMap()` / `LfoSnapshot.fromMap()` / `ModulationEdgeSnapshot.fromMap()`