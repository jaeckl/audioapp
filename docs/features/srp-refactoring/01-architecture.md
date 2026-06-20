# Architecture Contract: SRP Refactoring

## Overview

This refactoring decomposes three monolithic code modules in the JUCE engine into
Single-Responsibility-Principle units without changing behavior, thread safety,
or data formats.

---

## 2.1 User-Visible Goal

The codebase continues to work identically. No behavior changes. No new features.
The refactoring only moves code between files and breaks monolithic constructs
into SRP-compliant modules.

---

## 2.2 Non-Goals

- No new device types.
- No new DSP algorithms.
- No rewrite of the double-buffered snapshot architecture.
- No changes to Flutter/Dart code.
- No changes to the audio-thread hot path contracts (function signatures may
  evolve by gaining a cleaner dispatch, but the runtime result is bit-identical).
- No performance regression on the audio thread.

---

## 2.3 Existing Code to Reuse (NOT to Duplicate)

- The `IDeviceType` interface as the registration mechanism — it already maps
  `typeId` → `createDefault()` / `buildPlaybackNode()`.
- `DeviceTypeIds.hpp` for device type string constants.
- All existing `*Params` structs in `DeviceChain.hpp` — do not duplicate fields.
- All existing DSP generator free functions — they remain where they are.
- `LfoEngine.cpp` — already correctly factored; just fix the header export.
- `AutomationPlayback.hpp` / `AutomationTypes.hpp` — already clean.

---

## 2.4 Architecture Decision

**Gradual extraction, no big-bang rewrite.** Each work package produces a working,
compilable, tested state. The `DeviceState` monolithic struct is decomposed over
multiple packages but its JSON wire format stays backward-compatible (existing
`.audioapproj` files continue to load).

The refactoring follows this principle:

- Extract the **serialization concern** from `ProjectJson.cpp` into per-device
  serializer functions.
- Extract the **audio process concern** from `DeviceChain.cpp` into per-device
  `process()` overloads.
- Extract the **bridge JSON concern** from `ProjectJson.cpp` into a new
  `BridgeUtil.hpp/cpp`.
- Extract the **argument parsing concern** from `ProjectJson.cpp` into
  `BridgeArgParser.hpp/cpp`.
- The `LfoEngine.cpp` already has the math — just fix the header so
  `ProjectJson.hpp` doesn't expose it.

---

## 2.5 Module Boundaries

```
engine_juce/include/audioapp/
  ProjectJson.hpp                    → KEEP but slim down (project-level only)
  BridgeUtil.hpp (NEW)               → bridge JSON helpers + arg parsers

engine_juce/include/audioapp/devices/serialization/  (NEW directory)
  OscillatorSerializer.hpp (NEW)
  SamplerSerializer.hpp (NEW)
  SubtractiveSynthSerializer.hpp (NEW)
  KickGeneratorSerializer.hpp (NEW)
  SnareGeneratorSerializer.hpp (NEW)
  ClapGeneratorSerializer.hpp (NEW)
  CymbalGeneratorSerializer.hpp (NEW)
  CrashGeneratorSerializer.hpp (NEW)
  GateSerializer.hpp (NEW)
  CompressorSerializer.hpp (NEW)
  ExpanderSerializer.hpp (NEW)
  LimiterSerializer.hpp (NEW)
  TrackGainSerializer.hpp (NEW)
  BassSynthSerializer.hpp (NEW)

engine_juce/src/
  OscillatorProcess.cpp (NEW)
  SamplerProcess.cpp (NEW)
  SubtractiveSynthProcess.cpp (NEW)
  BassSynthProcess.cpp (NEW)
  KickGeneratorProcess.cpp (NEW)
  SnareGeneratorProcess.cpp (NEW)
  ClapGeneratorProcess.cpp (NEW)
  CymbalGeneratorProcess.cpp (NEW)
  CrashGeneratorProcess.cpp (NEW)
  GateProcess.cpp (NEW)
  CompressorProcess.cpp (NEW)
  ExpanderProcess.cpp (NEW)
  LimiterProcess.cpp (NEW)
  TrackGainProcess.cpp (NEW)
  BridgeUtil.cpp (NEW)
```

---

## 2.6 Threading/Safety Boundaries

Everything that currently lives on the **control thread** stays on the control
thread. Everything on the **audio thread** stays on the audio thread.

The refactoring does **not** change thread assignments. It only changes which
**file** contains which code.

### Realtime-Safety Invariants (MUST NOT be violated)

| Function | Current File | Thread | Move Allowed? |
|----------|-------------|--------|---------------|
| `deviceToVar` | `ProjectJson.cpp` | control | YES — to per-device serializers |
| `deviceFromVar` | `ProjectJson.cpp` | control | YES |
| `parseMidiNotesFromArgs` | `ProjectJson.cpp` | control | YES — to BridgeUtil |
| `jsonGetStringArg` | `ProjectJson.cpp` | control | YES — to BridgeUtil |
| `buildBridgeOkWithSnapshot` | `ProjectJson.cpp` | control | YES — to BridgeUtil |
| `lfoEvaluate` | `LfoEngine.cpp` (decl in ProjectJson.hpp) | audio + control | NO — leave in LfoEngine.cpp |
| `modulatorEvaluateSynced` | `LfoEngine.cpp` | audio + control | NO |
| `applyModulation(Params&...)` | `DeviceChain.cpp` (anon ns) | audio | YES — to per-device process files (still noexcept) |
| `processDeviceChain` | `DeviceChain.cpp` | audio | YES — delegates to per-kind functions |
| Instrument DSP generators | individual .cpp files | audio | NO — leave in place |

---

## 2.7 Realtime Safety Verification for Each Move

**WP1 (serialization extraction):** All serialization functions allocate
`juce::DynamicObject`, use strings, use `juce::JSON`. These are already
control-thread-only operations called from `BridgeHost::handleCommand` →
`EngineHost::getProjectSnapshotJson()` → `snapshotToJson()` → `deviceToVar()`.
Moving to per-device files does not change the calling context. **SAFE.**

**WP2 (process extraction):** The code being moved is inside `processDeviceChain()`
which is already declared `noexcept` and runs on the audio thread. The
anonymous-namespace `applyModulation` functions are called within the audio
callback. Moving them to per-device headers (still `noexcept`, still in .cpp
with no heap/strings/locks) preserves realtime safety.
**SAFE** provided per-device Process files have no string/alloc/lock usage.

**WP3 (bridge helpers):** All bridge helper functions call `juce::JSON`, allocate
`DynamicObject`, return `std::string`. They are called from
`BridgeHost::handleCommand` which runs on the platform thread. **SAFE.**

**WP4 (LFO math header fix):** The LFO math lives in `LfoEngine.cpp` but its
declarations are in `ProjectJson.hpp`. Moving the declarations to `LfoTypes.hpp`
fixes an incorrect include dependency without changing thread safety. **SAFE.**

---

## 2.8 Error Model

No error model changes. Existing patterns:
- Serialization: return `false` / empty `DeviceState` / defaults on missing
  fields (already lenient).
- Bridge: return `{"ok":false,"error":"code"}` for failures.
- Audio thread: no errors (all validation done before snapshot build).

---

## 2.9 Persistence Model

The JSON format (`project.json` inside `.audioapproj`) stays **byte-identical**
for the same project state. The `deviceToVar` serialization produces the same
keys and values for the same `DeviceState` inputs. Refactoring must not change
JSON output.

**Testing**: All existing `project_serialization_test.cpp` tests must pass
unchanged.

---

## 2.10 UI/State Sync Model

The Flutter side reads `ProjectSnapshot` JSON via `getProjectSnapshot`. The
snapshot format (keys, nesting) must not change. The `snapshotToVar` function
in `ProjectJson.cpp` aggregates per-track device data via `deviceToVar` which
is extracted in WP1.

`cd app_flutter && flutter test` must pass — the Dart side parses JSON
snapshots; changes to C++ serialization must not break the JSON contract.
