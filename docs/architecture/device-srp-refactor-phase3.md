# Device SRP Refactoring — Phase 3: Migrate Snapshot Path to Registry Dispatch

> Remove meters from `DeviceState`, add parallel `deviceMeters` array on `TrackState`, migrate the snapshot JSON serialization to use registry dispatch (removes the old if/else-if chain), and delete the legacy `deviceToVar(DeviceState)` / `deviceFromVar(var)` functions.

---

## A. Canonical Vocabulary

| Concept | Canonical name | Type/file | Notes |
| ------- | -------------- | --------- | ----- |
| Live meter values (NEW) | `DeviceMeterState` | `ProjectEngine.hpp` next to `TrackState` | `deviceId` + two floats. One per dynamics device that has live meters. |
| Parallel meter array (NEW) | `TrackState::deviceMeters` | `ProjectEngine.hpp` line on `TrackState` | `std::vector<DeviceMeterState>`, indexed parallel to `TrackState::devices`. Populated by `applyLiveDeviceMetersLocked`. |
| Meter injection (MODIFIED) | `applyLiveDeviceMetersLocked()` | `ProjectEngine.cpp` | Writes to `TrackState::deviceMeters` instead of `DeviceState` fields. |
| Snapshot-track serializer (NEW) | `trackToVarSnapshot(TrackState, Registry)` | `ProjectJson.cpp` anonymous namespace | Replaces `trackToVar(TrackState)`. Calls `audioapp::deviceToVar(DeviceState, Registry)` then injects live meters from `track.deviceMeters`. |
| Snapshot serializer (MODIFIED) | `snapshotToVar(ProjectSnapshot, Registry)` | `ProjectJson.cpp` anonymous namespace | Now takes a `DeviceRegistry` parameter. Calls `trackToVarSnapshot` instead of `trackToVar`. |
| Snapshot-to-JSON (MODIFIED) | `snapshotToJson(ProjectSnapshot, Registry)` | `ProjectJson.hpp` / `ProjectJson.cpp` | Signature gains `const DeviceRegistry&` parameter. |
| Old device serializer (REMOVED) | `deviceToVar(DeviceState)` | `ProjectJson.cpp` lines 80–264 | Big if/else-if chain. Dead code after Phase 3. |
| Old device deserializer (REMOVED) | `deviceFromVar(var)` | `ProjectJson.cpp` lines 266–429 | Big if/else-if chain. Dead code after Phase 3. |
| Old track serializer (REMOVED) | `trackToVar(TrackState)` | `ProjectJson.cpp` lines 575–605 | Only existed for snapshot path. Dead code. |
| Old track deserializer (REMOVED) | `trackFromVar(var)` | `ProjectJson.cpp` lines 607–634 | Only existed for snapshot path. Already unused after Phase 2 (persistence uses `trackFromVarPersistence`). |
| Strip-snapshot helper (PRESERVED) | `stripSnapshot(slot, typeId)` | Per-`*DeviceType.cpp` files | Creates `DeviceState` with `id`, `type`, `gain`, `pan`, `bypassed`. No longer has meter fields to worry about. |
| Registry-aware overload (PRESERVED) | `audioapp::deviceToVar(DeviceState, Registry)` | `ProjectJson.cpp` line 936 / `ProjectJson.hpp` line 36 | Used by both persistence and snapshot paths. |
| Registry-aware overload (PRESERVED) | `audioapp::deviceFromVar(var, Registry)` | `ProjectJson.cpp` line 943 / `ProjectJson.hpp` line 39 | Used by persistence path. Snapshot doesn't deserialize. |
| Persistence track serializer (PRESERVED) | `trackToVarPersistence(TrackState, Registry)` | `ProjectJson.cpp` anonymous namespace | Created in Phase 2. Unchanged. |
| Persistence track deserializer (PRESERVED) | `trackFromVarPersistence(var, Registry)` | `ProjectJson.cpp` anonymous namespace | Created in Phase 2. Unchanged. |
| Device-level `slotToVar` (PRESERVED) | `IDeviceType::slotToVar(DeviceSlot)` | Per-`*DeviceType.cpp` | Still writes meters as 0.0. Meters are then overwritten by the snapshot track serializer with live values. |
| Bridge entry point (MODIFIED) | `EngineHost::getProjectSnapshotJson()` | `EngineHost_commands.cpp` | Now passes `project_.deviceRegistry()` to `snapshotToJson`. |

---

## B. What Stays the Same (Critical Invariants)

| Invariant | Rationale |
|-----------|-----------|
| Audio thread code (`DeviceChain.cpp`, DSP modules) | Not touched. |
| All instance struct headers (`instances/*Instance.hpp`) | No changes. |
| `DeviceSlot.hpp` and `DeviceSlot` | No meter fields in DeviceSlot — unchanged. |
| `IDeviceType.hpp` | Signature unchanged. |
| `DeviceRegistry.hpp` | No new methods. |
| `IDeviceType::slotToVar` / `varToSlot` implementations | Already write meters as 0.0. That's correct: persistence wants 0.0, snapshot path overwrites with live values. |
| `DeviceInstance` variant | No new variant alternatives. |
| `ProjectFileData` | No changes. |
| `ProjectFileData` / persistence path (`projectFileToJson`/`parseProjectFileJson`) | Phase 2 code is untouched. |
| Persistence track serializers (`trackToVarPersistence`/`trackFromVarPersistence`) | Unchanged. |
| File JSON schema | Unchanged. |
| Snapshot JSON schema — Flutter-facing | **Identical.** Each device JSON still has `"meters": {"gainReductionDb": ..., "inputLevel": ...}` for dynamics devices. The values come from the parallel array instead of `DeviceState` fields. |
| Flutter Dart code (`app_flutter/*`) | **No changes needed.** The `DeviceSnapshot.fromMap` already reads `map['meters']` as a separate sub-object. The `withMergedDeviceMeters` method also reads device JSON. Neither needs updating. |
| `kMaxDeviceMeters`, `DeviceMeterAtomic`, `deviceMeters_[]`, `deviceMeterIds_[]`, `deviceMeterSlotCount_` | Internal engine bookkeeping unchanged. Only the snapshot-export function changes how it reads these. |
| `processDeviceChain` and `DeviceChain.cpp` | No changes. |

---

## C. What Changes

### C.1 `engine_juce/include/audioapp/DeviceState.hpp` — Remove meter fields

Delete lines 129–130 (two fields):

```diff
-    float meterGainReductionDb = 0.0f;
-    float meterInputLevel = 0.0f;
```

**Rationale:** `DeviceState` is now purely about device parameters. Live meter values are runtime-only and live in a parallel array.

### C.2 `engine_juce/include/audioapp/ProjectEngine.hpp` — Add `DeviceMeterState` struct and `deviceMeters` to `TrackState`

Add **before** `struct TrackState`:

```cpp
/// Live meter readouts for dynamics devices (gate, compressor, expander, limiter).
/// Populated by applyLiveDeviceMetersLocked() during snapshot building.
struct DeviceMeterState {
    std::string deviceId;
    float gainReductionDb = 0.0f;
    float inputLevel = 0.0f;
};
```

Add to `TrackState`, **after** `std::vector<DeviceState> devices;`:

```cpp
    /// Parallel meter array indexed by position (same order as devices).
    /// Only populated for snapshot serialization. Not persisted to project files.
    std::vector<DeviceMeterState> deviceMeters;
```

The full `TrackState` becomes:

```cpp
struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceState> devices;
    std::vector<DeviceMeterState> deviceMeters;  // NEW
    std::vector<MidiClipState> midiClips;
    std::vector<SampleClipState> sampleClips;
    std::vector<AutomationClipState> automationClips;
};
```

### C.3 `engine_juce/src/ProjectEngine.cpp` — `applyLiveDeviceMetersLocked()`

**OLD behavior:** Writes to `DeviceState::meterGainReductionDb` and `DeviceState::meterInputLevel`.

**NEW behavior:** Populates `DeviceMeterState` and pushes to `TrackState::deviceMeters`.

```cpp
void ProjectEngine::applyLiveDeviceMetersLocked(ProjectSnapshot& snap) const {
    for (auto& trackState : snap.tracks) {
        for (auto& device : trackState.devices) {
            if (device.type != "gate" && device.type != "compressor" &&
                device.type != "expander" && device.type != "limiter") {
                continue;
            }
            for (int i = 0; i < deviceMeterSlotCount_; ++i) {
                if (deviceMeterIds_[i] != device.id) {
                    continue;
                }
                DeviceMeterState meter;
                meter.deviceId = device.id;
                meter.gainReductionDb =
                    deviceMeters_[i].gainReductionDb.load(std::memory_order_relaxed);
                meter.inputLevel =
                    deviceMeters_[i].inputPeak.load(std::memory_order_relaxed);
                trackState.deviceMeters.push_back(std::move(meter));
                break;
            }
        }
    }
}
```

Note: The type matching logic (`device.type == "gate" || ...`) is preserved. Only the output storage changes.

### C.4 `engine_juce/src/ProjectJson.cpp` — Add `trackToVarSnapshot` (anonymous namespace)

New function, similar structure to the existing `trackToVar` but:

1. Calls `audioapp::deviceToVar(device, registry)` for device serialization (registry dispatch)
2. After serialization, iterates `track.deviceMeters` to find a matching meter and overwrites the `"meters"` sub-object on the device JSON

```cpp
juce::var trackToVarSnapshot(const TrackState& track,
                              const DeviceRegistry& registry) {
    juce::Array<juce::var> devices;
    devices.ensureStorageAllocated(static_cast<int>(track.devices.size()));
    for (size_t i = 0; i < track.devices.size(); ++i) {
        // Step 1: Serialize device params via registry dispatch
        // This produces proper parameters sub-object and writes meters=0.0
        // for dynamics devices (from slotToVar default).
        juce::var deviceVar = audioapp::deviceToVar(track.devices[i], registry);

        // Step 2: Inject live meter values from parallel array
        for (const auto& meter : track.deviceMeters) {
            if (meter.deviceId == track.devices[i].id) {
                if (auto* obj = deviceVar.getDynamicObject()) {
                    auto* metersObj = new juce::DynamicObject();
                    metersObj->setProperty("gainReductionDb",
                        static_cast<double>(meter.gainReductionDb));
                    metersObj->setProperty("inputLevel",
                        static_cast<double>(meter.inputLevel));
                    obj->setProperty("meters", juce::var(metersObj));
                }
                break;
            }
        }

        devices.add(deviceVar);
    }

    juce::Array<juce::var> clips;
    clips.ensureStorageAllocated(static_cast<int>(track.midiClips.size()));
    for (const auto& clip : track.midiClips) {
        clips.add(midiClipToVar(clip));
    }

    juce::Array<juce::var> sampleClips;
    sampleClips.ensureStorageAllocated(static_cast<int>(track.sampleClips.size()));
    for (const auto& clip : track.sampleClips) {
        sampleClips.add(sampleClipToVar(clip));
    }

    auto* object = new juce::DynamicObject();
    object->setProperty("id", toJuceString(track.id));
    object->setProperty("name", toJuceString(track.name));
    object->setProperty("devices", devices);
    object->setProperty("midiClips", clips);
    object->setProperty("sampleClips", sampleClips);
    return juce::var(object);
}
```

### C.5 `engine_juce/src/ProjectJson.cpp` — Update `snapshotToVar` (anonymous namespace)

Add `const DeviceRegistry& registry` parameter. Change `trackToVar(track)` to `trackToVarSnapshot(track, registry)`.

```cpp
juce::var snapshotToVar(const ProjectSnapshot& snapshot,
                         const DeviceRegistry& registry) {
    juce::Array<juce::var> tracks;
    tracks.ensureStorageAllocated(static_cast<int>(snapshot.tracks.size()));
    for (const auto& track : snapshot.tracks) {
        tracks.add(trackToVarSnapshot(track, registry));
    }
    // ... rest identical (samples, master, lfos, modEdges, automations) ...
    return juce::var(object);
}
```

### C.6 `engine_juce/src/ProjectJson.cpp` — Update `snapshotToJson` (namespace audioapp)

```cpp
// OLD:
// std::string snapshotToJson(const ProjectSnapshot& snapshot) {
//     return toStdString(juce::JSON::toString(snapshotToVar(snapshot), false));
// }

// NEW:
std::string snapshotToJson(const ProjectSnapshot& snapshot,
                           const DeviceRegistry& registry) {
    return toStdString(juce::JSON::toString(snapshotToVar(snapshot, registry), false));
}
```

### C.7 `engine_juce/include/audioapp/ProjectJson.hpp` — Update `snapshotToJson` declaration

```cpp
std::string snapshotToJson(const ProjectSnapshot& snapshot,
                           const DeviceRegistry& registry);
```

**Must add `#include "audioapp/devices/DeviceRegistry.hpp"`** if not already present. (Check: the header already includes `ProjectEngine.hpp` which includes `DeviceRegistry.hpp`. So no new include needed.)

### C.8 `engine_juce/src/EngineHost_commands.cpp` — Update `getProjectSnapshotJson()`

```cpp
std::string EngineHost::getProjectSnapshotJson() const {
    return snapshotToJson(project_.snapshot(), project_.deviceRegistry());
}
```

### C.9 `engine_juce/src/ProjectJson.cpp` — Remove old if/else-if chain

After verifying the snapshot path works correctly through the new `trackToVarSnapshot` → `audioapp::deviceToVar(DeviceState, Registry)`, delete:

- Anonymous `deviceToVar(DeviceState)` — lines 80–264 (old if/else-if chain)
- Anonymous `deviceFromVar(var)` — lines 266–429 (old if/else-if chain)
- Anonymous `trackToVar(TrackState)` — lines 575–605
- Anonymous `trackFromVar(var)` — lines 607–634

These are all **dead code** after Phase 3. The persistence path uses `trackToVarPersistence`/`trackFromVarPersistence` (Phase 2). The snapshot path now uses `trackToVarSnapshot` (Phase 3).

Note: `deviceToVar(DeviceState)` in the anonymous namespace (old if/else-if chain, lines 80–264) is a *different function* from `audioapp::deviceToVar(DeviceState, Registry)` at line 936 in the `namespace audioapp` block. Only the anonymous-namespace one is removed.

### C.10 `engine_juce/src/ProjectJson.cpp` — Cleanup function declarations

The forward declarations at lines 793–797 for `trackToVarPersistence`/`trackFromVarPersistence` are still needed (they're defined below the anonymous namespace block, at lines 866/895). Keep those.

---

## D. File Ownership

### Read-only files (must NOT change)

| File | Rationale |
| ---- | --------- |
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | No meter fields in slot. Unchanged. |
| `engine_juce/include/audioapp/devices/IDeviceType.hpp` | Interface is stable. |
| `engine_juce/include/audioapp/devices/DeviceRegistry.hpp` | No new methods. |
| `engine_juce/include/audioapp/DeviceChain.hpp` | `DeviceMeterAtomic`, `kMaxDeviceMeters` unchanged. |
| All `*DeviceType.hpp` / `*DeviceType.cpp` | Phase 1 complete. SlotToVar/varToSlot implementations write 0.0 meters — correct for both persistence and as baseline for snapshot overwrite. |
| All `*Instance.hpp` / `*Instance.cpp` | Instance structs don't have meter fields. |
| All `app_flutter/` Dart files | Flutter reads `meters` sub-object from JSON. Schema unchanged. **Zero Flutter changes.** |

### May change

| File | Owner package | Allowed changes |
| ---- | ------------- | --------------- |
| `engine_juce/include/audioapp/DeviceState.hpp` | P3-P1 | Remove `meterGainReductionDb` and `meterInputLevel` fields. |
| `engine_juce/include/audioapp/ProjectEngine.hpp` | P3-P1 | Add `DeviceMeterState` struct. Add `deviceMeters` field to `TrackState`. |
| `engine_juce/src/ProjectEngine.cpp` | P3-P2 | Rewrite `applyLiveDeviceMetersLocked()` to populate `TrackState::deviceMeters`. |
| `engine_juce/src/ProjectJson.cpp` | P3-P3, P3-P4 | Add `trackToVarSnapshot()`. Update `snapshotToVar()` and `snapshotToJson()` signatures. Remove old if/else-if chain. Remove old `trackToVar`/`trackFromVar`. |
| `engine_juce/include/audioapp/ProjectJson.hpp` | P3-P3 | Update `snapshotToJson` declaration to take `const DeviceRegistry&`. |
| `engine_juce/src/EngineHost_commands.cpp` | P3-P3 | Update `getProjectSnapshotJson()` to pass `project_.deviceRegistry()`. |
| `engine_juce/tests/*.cpp` | P3-P5 | Verify no test uses removed `DeviceState` meter fields or old functions. Update if compilation breaks. |
| `engine_juce/tests/device_slot_serialization_test.cpp` | P3-P5 | The meters sub-object test (`hasMeters`, lines 162–172) should still pass (slotToVar still writes meters). No change expected. |

---

## E. Vertical Work Packages

### Package P3-P1 (Prerequisite): Define new meter types, remove old fields

**Behavior:** `DeviceMeterState` struct exists. `TrackState` has `deviceMeters`. `DeviceState` no longer has meter fields.

**Files changed:**
- `engine_juce/include/audioapp/DeviceState.hpp` — delete 2 lines
- `engine_juce/include/audioapp/ProjectEngine.hpp` — add struct + vector field

**Canonical names used:** `DeviceMeterState`, `TrackState`, `DeviceState`

**Acceptance criteria:**
- `DeviceState` compiles without `meterGainReductionDb` and `meterInputLevel`
- `TrackState` has `std::vector<DeviceMeterState> deviceMeters` member
- All existing tests that use `DeviceState` still compile (no test accesses the meter fields directly — confirmed by grep)

**Parallelization:** Sequential prerequisite. P3-P2 and P3-P3 depend on this.

---

### Package P3-P2 (Parallel-safe after P3-P1): Rewrite `applyLiveDeviceMetersLocked`

**Behavior:** `applyLiveDeviceMetersLocked` writes to `TrackState::deviceMeters` parallel array instead of `DeviceState` fields.

**Files changed:**
- `engine_juce/src/ProjectEngine.cpp`

**Canonical names used:** `DeviceMeterState`, `TrackState::deviceMeters`, `deviceMeters_[]`, `deviceMeterIds_[]`, `deviceMeterSlotCount_`

**Acceptance criteria:**
- After `snapshot()` returns, each `TrackState` with dynamics devices has corresponding entries in `deviceMeters`
- `deviceMeters.size() <= devices.size()` (only dynamics devices get meter entries)
- No compilation errors in `ProjectEngine.cpp`
- Previously compiled callers of `snapshot()` continue to compile

**Parallelization:** Parallel-safe with P3-P3 (different files).

---

### Package P3-P3 (Parallel-safe after P3-P1): New snapshot serialization path

**Behavior:** `trackToVarSnapshot()` exists and uses registry dispatch for device params + meter injection from parallel array. `snapshotToVar`, `snapshotToJson`, and the bridge entry point are updated.

**Files changed:**
- `engine_juce/src/ProjectJson.cpp` — add `trackToVarSnapshot`, update `snapshotToVar` and `snapshotToJson`
- `engine_juce/include/audioapp/ProjectJson.hpp` — update `snapshotToJson` declaration
- `engine_juce/src/EngineHost_commands.cpp` — pass registry to `snapshotToJson`

**Canonical names used:** `trackToVarSnapshot`, `snapshotToVar`, `snapshotToJson`, `TrackState`, `DeviceMeterState`, `DeviceRegistry`

**Acceptance criteria:**
- `trackToVarSnapshot` produces JSON identical to old `trackToVar` + `deviceToVar(DeviceState)` for devices without meters (all non-dynamics types)
- For dynamics devices, JSON has `"meters": {"gainReductionDb": <live>, "inputLevel": <live>}` — same schema as before
- `snapshotToJson(ProjectSnapshot, DeviceRegistry)` compiles and produces identical output to old path (for same input data)
- `EngineHost::getProjectSnapshotJson()` passes `project_.deviceRegistry()` and compiles

**Parallelization:** Parallel-safe with P3-P2 (no file overlap).

---

### Package P3-P4 (Sequential after P3-P2 + P3-P3): Remove old if/else-if chain

**Behavior:** The old `deviceToVar(DeviceState)`, `deviceFromVar(var)`, `trackToVar(TrackState)`, and `trackFromVar(var)` in the anonymous namespace are deleted. All serialization now goes through registry dispatch.

**Files changed:**
- `engine_juce/src/ProjectJson.cpp` — remove ~350 lines of dead code

**Canonical names removed:** Anonymous `deviceToVar(DeviceState)`, anonymous `deviceFromVar(var)`, anonymous `trackToVar(TrackState)`, anonymous `trackFromVar(var)`

**Acceptance criteria:**
- No references to the removed functions remain anywhere in the codebase
- `deviceToVar` (old, 1-arg) is gone; `audioapp::deviceToVar(DeviceState, Registry)` remains
- `deviceFromVar` (old, 1-arg) is gone; `audioapp::deviceFromVar(var, Registry)` remains
- All existing tests pass
- Snapshot JSON output is identical to before (verified by test)
- File JSON output is unchanged (persistence path untouched)

**Parallelization:** Must be sequential after P3-P2 and P3-P3 complete.

---

### Package P3-P5 (Sequential after P3-P4): Verify and update tests

**Behavior:** Run all tests. Fix any compilation or behavior issues. Add new snapshot-path meter test.

**Files changed:**
- `engine_juce/tests/device_slot_serialization_test.cpp` — potentially verify the meters sub-object test still passes (it should, since slotToVar still writes meters as 0.0). No changes expected.
- `engine_juce/tests/project_serialization_test.cpp` — verify snapshot test works. No changes expected.
- Any other test file that fails to compile due to `DeviceState` meter field removal — expected to be none (confirmed by grep).

**New test suggestion (optional but recommended):** Add a test to `device_slot_serialization_test.cpp` or a new test file that:
1. Creates a `ProjectSnapshot` with a dynamics device and known meter values in `deviceMeters`
2. Calls `snapshotToJson()` with a registry
3. Verifies the output JSON contains the expected `"meters"` sub-object with the injected values

**Acceptance criteria:**
- All existing C++ tests pass
- No test file modifications needed (compilation succeeds out of the box)
- Flutter tests pass without changes (schema unchanged)
- The snapshot path with meters produces correct JSON

**Parallelization:** Must be sequential after P3-P4.

---

## F. Parallelism and Dependencies

```
P3-P1 (prerequisite: define types, remove old fields)
  │
  ├──→ P3-P2 (parallel: rewrite applyLiveDeviceMetersLocked)     [ProjectEngine.cpp only]
  │
  └──→ P3-P3 (parallel: new snapshot serialization path)         [ProjectJson.cpp, ProjectJson.hpp, EngineHost_commands.cpp]
         │
         └──→ P3-P4 (sequential: remove old chain)               [ProjectJson.cpp only]
                │
                └──→ P3-P5 (sequential: verify tests)            [test files, if any]
```

| Package | Runs | Files | Dependencies |
| ------- | ---- | ----- | ------------ |
| P3-P1 | First | `DeviceState.hpp`, `ProjectEngine.hpp` | None |
| P3-P2 | After P3-P1 | `ProjectEngine.cpp` | P3-P1 (needs `DeviceMeterState` and `TrackState::deviceMeters`) |
| P3-P3 | After P3-P1 | `ProjectJson.cpp`, `ProjectJson.hpp`, `EngineHost_commands.cpp` | P3-P1 (needs `TrackState::deviceMeters`) |
| P3-P4 | After P3-P2+P3-P3 | `ProjectJson.cpp` | P3-P2+P3-P3 (old chain legitimately dead only after new paths work) |
| P3-P5 | After P3-P4 | Test files | P3-P4 (compilation only correct after old chain removed) |

### Shared files requiring care

- **`ProjectJson.cpp`** — touched by P3-P3 (additions) and P3-P4 (removals). These must be sequential. P3-P3 adds new functions. P3-P4 removes old functions. The implementation worker for P3-P4 must not accidentally remove P3-P3's additions.

- **`ProjectEngine.hpp`** — only P3-P1 touches it. No conflict risk.

---

## G. API / Data Contracts

### G.1 New struct: `DeviceMeterState`

```cpp
// engine_juce/include/audioapp/ProjectEngine.hpp

/// Live meter readouts for dynamics devices (gate, compressor, expander, limiter).
/// Populated by applyLiveDeviceMetersLocked() during snapshot building.
/// Not persisted to project files — runtime-only.
struct DeviceMeterState {
    std::string deviceId;       ///< Matches DeviceState::id for the owning device.
    float gainReductionDb = 0.0f;  ///< Current gain reduction in dB (positive = reduction).
    float inputLevel = 0.0f;       ///< Current input level (0.0–1.0 normalized).
};
```

**Location:** Put before `struct TrackState` in `ProjectEngine.hpp`.

**Validation rules:**
- `deviceId` should be non-empty for valid meter states
- `gainReductionDb` is typically 0.0 (no reduction) to ~24.0 (heavy reduction)
- `inputLevel` is 0.0–1.0 normalized

### G.2 Modified `TrackState`

```cpp
struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceState> devices;
    std::vector<DeviceMeterState> deviceMeters;  // NEW — parallel to devices
    std::vector<MidiClipState> midiClips;
    std::vector<SampleClipState> sampleClips;
    std::vector<AutomationClipState> automationClips;
};
```

**Notes:**
- `deviceMeters` is NOT persisted to project files. It's snapshot-only.
- `deviceMeters` may be smaller than `devices` (only dynamics devices have meters).
- The order of `deviceMeters` entries does NOT necessarily match `devices` order — each entry carries `deviceId` for matching.

### G.3 Modified `DeviceState`

```cpp
// Remove these two fields (lines 129–130):
// float meterGainReductionDb = 0.0f;
// float meterInputLevel = 0.0f;
```

`DeviceState` is now purely about device parameters. Size decreases by 8 bytes.

### G.4 Modified `snapshotToJson`

```cpp
// engine_juce/include/audioapp/ProjectJson.hpp

/// Serialize a ProjectSnapshot to compact JSON for the Flutter bridge.
/// Uses registry-aware device dispatch and injects live meter values
/// from TrackState::deviceMeters.
/// @param snapshot The project snapshot to serialize.
/// @param registry Device registry for typed serialization dispatch.
/// @returns Compact JSON string.
std::string snapshotToJson(const ProjectSnapshot& snapshot,
                           const DeviceRegistry& registry);
```

### G.5 New function: `trackToVarSnapshot`

```cpp
// Anonymous namespace in ProjectJson.cpp (internal, not in header)

/// Serialize a TrackState to JSON for the snapshot bridge.
/// Uses registry-aware device dispatch for parameter serialization,
/// then injects live meter values from TrackState::deviceMeters.
/// This replaces the old trackToVar function.
juce::var trackToVarSnapshot(const TrackState& track,
                              const DeviceRegistry& registry);
```

### G.6 Snapshot JSON Schema (unchanged)

```json
{
  "bpm": 120,
  "playheadBeats": 0.0,
  "playing": false,
  "loopEnabled": true,
  "loopRegionStartBeat": 0.0,
  "loopRegionEndBeat": 16.0,
  "loopLengthBeats": 16.0,
  "recordArmed": false,
  "selectedTrackId": "track-1",
  "master": { "id": "master", "name": "Master", "gain": 1.0 },
  "samples": [],
  "tracks": [
    {
      "id": "track-1",
      "name": "Track 1",
      "devices": [
        {
          "id": "dev-1",
          "type": "compressor",
          "parameters": { "gain": 1.0, "pan": 0.5, ... },
          "meters": { "gainReductionDb": 3.5, "inputLevel": 0.82 }
        }
      ],
      "midiClips": [],
      "sampleClips": []
    }
  ],
  "lfos": [],
  "modEdges": [],
  "automationClips": []
}
```

Key: `tracks[i].devices[j].meters.gainReductionDb` and `tracks[i].devices[j].meters.inputLevel` — exactly the same structure as before.

### G.7 Error handling

| Scenario | Behavior |
|----------|----------|
| Device with no meters in `deviceMeters` array | `trackToVarSnapshot` writes whatever `slotToVar` produces (0.0 meters for dynamics, no meters field for non-dynamics). Correct. |
| Device in `deviceMeters` not found in `devices` | Entry is silently ignored. Unlikely in practice (same array built from same track). |
| `deviceMeters` empty for a dynamics device | JSON shows `meters: {gainReductionDb: 0.0, inputLevel: 0.0}` from slotToVar default. Acceptable. |
| Unknown device type in snapshot | `audioapp::deviceToVar(DeviceState, Registry)` returns empty var. `trackToVarSnapshot` adds it (empty JSON `{}`). Same behavior as current `deviceSlotToVarImpl` which asserts or returns empty for unknown types. |
| `registry.slotFromSnapshot` for an unknown type | Returns empty DeviceSlot. `audioapp::deviceToVar` returns empty var. Same as Phase 2 behavior. |

---

## H. Tests

### H.1 Existing C++ tests that must continue to pass

| Test file | What it validates | Risk after Phase 3 |
|-----------|-------------------|-------------------|
| `engine_juce/tests/device_slot_serialization_test.cpp` | `slotToVar`/`varToSlot` round-trip for all 14 types. "Dynamics devices: verify meters sub-object present" test (line 162) checks that `hasMeters(parsed)` is true. | **No change expected.** `slotToVar` still writes `meters` sub-object. Test passes. |
| `engine_juce/tests/device_registry_test.cpp` | Registry type lookup, default creation. | No change — registry untouched. |
| `engine_juce/tests/device_types_test.cpp` | Per-type param set, playback node build. | No change — device types untouched. |
| `engine_juce/tests/project_serialization_test.cpp` | Save/load round-trip via `EngineHost`. Also calls `getProjectSnapshotJson()`. | **Low risk.** `EngineHost` API unchanged, only internally passes registry. Snapshot JSON should be identical. |
| `engine_juce/tests/device_chain_test.cpp` | Audio DSP processing. | No change — audio thread untouched. |
| All other `engine_juce/tests/*.cpp` | Various engine behaviors. | No change — none access `DeviceState` meter fields directly (confirmed by grep). |

### H.2 Flutter tests that must continue to pass

| Test file | What it validates | Risk after Phase 3 |
|-----------|-------------------|-------------------|
| `app_flutter/test/drum_mono_output_test.dart` | "compressor shows GR from device meters" test (line 68) constructs a `DeviceSnapshot.fromMap` with a `meters` sub-object. | **No change expected.** Flutter-side parsing of `meters` sub-object is unchanged. JSON structure is identical. |

All Flutter tests should pass without modifications.

### H.3 New test recommended (optional)

Add a snapshot meter injection test in a new file or extend an existing one:

```cpp
// engine_juce/tests/snapshot_meter_test.cpp (optional, not required)

/// Verify that the snapshot JSON path correctly injects live meter values
/// from TrackState::deviceMeters into the serialized device output.
int main() {
    const auto registry = audioapp::DeviceRegistry::createBuiltIn();

    audioapp::ProjectSnapshot snap;
    snap.bpm = 120;

    audioapp::TrackState track;
    track.id = "track-1";
    track.name = "Test Track";

    // Add a compressor device
    audioapp::DeviceState comp;
    comp.id = "dev-comp";
    comp.type = "compressor";
    comp.gain = 1.0f;
    comp.pan = 0.5f;
    track.devices.push_back(comp);

    // Add meter entry for the compressor
    audioapp::DeviceMeterState meter;
    meter.deviceId = "dev-comp";
    meter.gainReductionDb = 4.5f;
    meter.inputLevel = 0.78f;
    track.deviceMeters.push_back(meter);

    snap.tracks.push_back(std::move(track));

    // Serialize
    const std::string json = audioapp::snapshotToJson(snap, registry);
    const auto parsed = juce::JSON::parse(juce::String(json));
    const auto* root = parsed.getDynamicObject();
    assert(root != nullptr);

    const auto tracks = root->getProperty("tracks");
    const auto* trackArray = tracks.getArray();
    assert(trackArray != nullptr && trackArray->size() == 1);

    const auto trackVar = (*trackArray)[0];
    const auto* trackObj = trackVar.getDynamicObject();
    assert(trackObj != nullptr);

    const auto devices = trackObj->getProperty("devices");
    const auto* deviceArray = devices.getArray();
    assert(deviceArray != nullptr && deviceArray->size() == 1);

    const auto deviceVar = (*deviceArray)[0];
    const auto* deviceObj = deviceVar.getDynamicObject();
    assert(deviceObj != nullptr);

    const auto meters = deviceObj->getProperty("meters");
    const auto* metersObj = meters.getDynamicObject();
    assert(metersObj != nullptr);

    const float actualGR = static_cast<float>(static_cast<double>(metersObj->getProperty("gainReductionDb")));
    const float actualIL = static_cast<float>(static_cast<double>(metersObj->getProperty("inputLevel")));

    assert(std::abs(actualGR - 4.5f) < 0.001f);
    assert(std::abs(actualIL - 0.78f) < 0.001f);

    std::cout << "PASS: Meter injection via registry dispatch works." << std::endl;
    return EXIT_SUCCESS;
}
```

### H.4 Manual verification

1. **Build and run all C++ tests** — confirm 0 failures.
2. **Run Flutter tests** — `cd app_flutter && flutter test` — confirm 0 failures.
3. **Snapshot JSON diff:** Before applying Phase 3, capture a snapshot JSON from a project with dynamics devices and live meters. After Phase 3, compare. The only difference should be that meter values come from the parallel array instead of DeviceState — functionally identical.
4. **File JSON verification:** Save a project before and after Phase 3. The file JSON must be byte-identical (persistence path is unchanged from Phase 2).

---

## I. Risks

| Risk | Severity | Mitigation |
| ---- | -------- | ---------- |
| **Flutter bridge breakage**: JSON schema for meters changes, breaking `DeviceSnapshot.fromMap` | **High** if it happens | **Mitigation: schema is preserved identically.** `trackToVarSnapshot` writes `"meters": {"gainReductionDb": ..., "inputLevel": ...}` as a sub-object of each device JSON — exactly what the old chain wrote. The `DeviceSnapshot.fromMap` reads `map['meters']` — unchanged. Flutter zero-change guarantee. |
| **Meters lost in snapshot**: `trackToVarSnapshot` uses registry dispatch which produces 0.0 meters, and the injection from `deviceMeters` doesn't fire | **Medium** — meters always show 0.0 | **Mitigation:** The meter injection loop in `trackToVarSnapshot` explicitly iterates `track.deviceMeters` and overwrites `"meters"` on the device var. Test coverage in P3-P5 (or manual verification step) confirms this works. |
| **Old chain not fully dead**: A code path still calls anonymous `deviceToVar(DeviceState)` or `trackToVar(TrackState)` | **High** — linker error if removed before all callers updated | **Mitigation:** P3-P4 removes old chain only AFTER P3-P3 has updated all callers. The call graph is well-understood: `snapshotToJson` → `snapshotToVar` → `trackToVar` → `deviceToVar(DeviceState)` is the only chain. P3-P3 replaces it entirely. |
| **`DeviceState` meter field removal breaks `stripSnapshot` helpers** | None — `stripSnapshot` doesn't touch meter fields | Confirmed by reading all 4 dynamics `*DeviceType.cpp` files' `stripSnapshot` implementations. They set id/type/gain/pan/bypassed only. |
| **`toSnapshotState()` no longer sets meter values** (they were never set) | None | Meters were never populated by `toSnapshotState()` — they were always injected by `applyLiveDeviceMetersLocked()` after the fact. Removing the fields from `DeviceState` changes nothing about this flow. |
| **Compilation failure from outdated test that access meter fields** | **Low** — no test accessed them (confirmed by grep) | Grep for `meterGainReductionDb` and `meterInputLevel` across `engine_juce/tests/` returned 0 matches. |
| **`project_serialization_test.cpp` fails because snapshot JSON changes** | **Low** — the test may compare snapshot output strings | If the test stringifies and compares the snapshot JSON, the output should be identical because: (a) dynamics devices in test setup likely have 0.0 meters anyway, (b) JSON structure is identical. If the test uses `EngineHost::getProjectSnapshotJson()` (which still works), it should pass. |
| **`device_slot_serialization_test.cpp` meters test (line 162) fails** | **Low** — `hasMeters(parsed)` checks for `"meters"` key | `slotToVar` for dynamics types still writes `"meters"` sub-object with 0.0 values. No change in Phase 3. Test continues to pass. |
| **Header include order**: `ProjectEngine.hpp` includes `DeviceState.hpp` (through the chain `DeviceRegistry.hpp` → `IDeviceType.hpp` → `DeviceState.hpp`). Removing fields from `DeviceState.hpp` is visible everywhere it's needed. | **None** | No include cycle risk. `DeviceState.hpp` is a leaf header. |
| **Pre-existing test compilation issue**: `project_serialization_test.cpp` line 40 calls `audioapp::parseProjectFileJson(json, parsed)` with 2 args, but the post-Phase-2 header requires 3 args (`registry`). The test may already be broken from Phase 2. | **Low** for Phase 3 — this is pre-existing | Phase 3 does not change this test's compilation status. If the test was already fixed in Phase 2 (but the checked-in file hasn't been refreshed), it will compile. If not, it's a separate Phase 2 follow-up — not a Phase 3 regression. Phase 3 P3-P5 should verify the actual state and report. |

---

## J. Implementation Order

### Phase 3 — 5 packages, implement in this order:

1. **P3-P1**: `DeviceState.hpp` — remove meter fields. `ProjectEngine.hpp` — add `DeviceMeterState` struct, add `deviceMeters` to `TrackState`. Compile check.

2. **P3-P2** (parallel with P3-P3): `ProjectEngine.cpp` — rewrite `applyLiveDeviceMetersLocked` to write to `TrackState::deviceMeters`.

3. **P3-P3** (parallel with P3-P2): `ProjectJson.cpp` — add `trackToVarSnapshot`, update `snapshotToVar`/`snapshotToJson`. `ProjectJson.hpp` — update `snapshotToJson` signature. `EngineHost_commands.cpp` — pass registry.

4. **P3-P4**: `ProjectJson.cpp` — remove anonymous `deviceToVar(DeviceState)`, `deviceFromVar(var)`, `trackToVar(TrackState)`, `trackFromVar(var)`.

5. **P3-P5**: Verify all tests pass. Add optional meter injection test.

### Verification order:

1. Compile engine library (`cmake --build build/engine --target audioapp_engine`)
2. Run all C++ tests
3. Run Flutter tests (`cd app_flutter && flutter test`)
4. Manual: compare snapshot JSON output before/after (must be identical)

---

## K. Worker Instructions for Implementation Agents

Each implementation worker MUST:

1. **Obey canonical names** as defined in §A. Do not invent synonyms.
2. **Stay within assigned files** as defined in §D. Do not edit files outside your package's allowed list.
3. **Not invent public APIs** beyond what's specified in §G.
4. **Not rename concepts** — "DeviceMeterState", "deviceMeters", "trackToVarSnapshot" are binding names.
5. **Not redesign architecture** — the approach (parallel meter array + registry dispatch + meter injection after serialization) is fixed.
6. **Stop and report** if any contract item is ambiguous or missing. Do not guess.

### Package P3-P1 instructions

- Open `DeviceState.hpp` and delete `float meterGainReductionDb` and `float meterInputLevel` lines.
- Open `ProjectEngine.hpp` and add `struct DeviceMeterState` definition just before `struct TrackState`.
- Add `std::vector<DeviceMeterState> deviceMeters;` to `TrackState`, right after the `devices` field.
- Verify compilation: `DeviceMeterState` must be visible before its use in `TrackState`.

### Package P3-P2 instructions

- Open `ProjectEngine.cpp`, find `applyLiveDeviceMetersLocked` (line 1078).
- Replace the body: instead of `device.meterGainReductionDb = ...` and `device.meterInputLevel = ...`, construct a `DeviceMeterState` and push to `trackState.deviceMeters`.
- The loop structure (iterate tracks → iterate devices → match via deviceMeterIds_) stays the same.
- Include `ProjectEngine.hpp` (already present).

### Package P3-P3 instructions

- In `ProjectJson.cpp` anonymous namespace, add `trackToVarSnapshot(TrackState, DeviceRegistry)`:
  - Copy the device-serialization loop from `trackToVar` (lines 577–580).
  - Replace `deviceToVar(device)` with `audioapp::deviceToVar(device, registry)`.
  - After serialization, add a loop over `track.deviceMeters` to find matching meter and overwrite `"meters"` on the device var.
  - Copy midi/sample clip serialization verbatim from `trackToVar`.
  - Copy the top-level object construction verbatim (id, name, devices, midiClips, sampleClips).
  - Do NOT include `automationClips` in the output (same as current `trackToVar`).
- Update `snapshotToVar` (anonymous, ~line 754):
  - Add `const DeviceRegistry& registry` parameter.
  - Replace `trackToVar(track)` with `trackToVarSnapshot(track, registry)`.
- Update `snapshotToJson` (namespace `audioapp`, ~line 949):
  - Add `const DeviceRegistry& registry` parameter.
  - Pass registry to `snapshotToVar(snapshot, registry)`.
- In `ProjectJson.hpp`:
  - Update `snapshotToJson` declaration with `const DeviceRegistry& registry` parameter.
- In `EngineHost_commands.cpp`:
  - Update `getProjectSnapshotJson()` to pass `project_.deviceRegistry()`.

### Package P3-P4 instructions

Wait for P3-P2 and P3-P3 to be merged first.

- Verify: `snapshotToJson` now goes through `trackToVarSnapshot` → `audioapp::deviceToVar(DeviceState, Registry)`.
- Verify: `projectFileToJson` goes through `trackToVarPersistence` → `audioapp::deviceToVar(DeviceState, Registry)`.
- Delete these functions from the anonymous namespace in `ProjectJson.cpp`:
  - `deviceToVar(DeviceState)` — the one-argument version, lines 80–264.
  - `deviceFromVar(var)` — the one-argument version, lines 266–429.
  - `trackToVar(TrackState)` — lines 575–605.
  - `trackFromVar(var)` — lines 607–634.
- Verify: no remaining references to these functions (grep the codebase).
- Verify: `audioapp::deviceToVar(DeviceState, DeviceRegistry)` still exists in `namespace audioapp` block (~line 936).
- Verify: `audioapp::deviceFromVar(var, DeviceRegistry)` still exists (~line 942).
- Verify compilation.

### Package P3-P5 instructions

Wait for P3-P4 to be merged first.

- Run all C++ tests.
- Run Flutter tests.
- If any test references removed fields/functions, update the test (report to orchestrator if contract was incomplete).
- Optionally add the meter injection test described in §H.3.

---

## L. Success Criteria (Checklist)

- [ ] `DeviceMeterState` struct exists in `ProjectEngine.hpp`
- [ ] `TrackState` has `std::vector<DeviceMeterState> deviceMeters` member
- [ ] `DeviceState` no longer has `meterGainReductionDb` or `meterInputLevel` fields
- [ ] `applyLiveDeviceMetersLocked` writes to `TrackState::deviceMeters` instead of `DeviceState` fields
- [ ] `trackToVarSnapshot` exists in anonymous namespace and uses registry dispatch
- [ ] `snapshotToVar` takes `const DeviceRegistry&` and calls `trackToVarSnapshot`
- [ ] `snapshotToJson(ProjectSnapshot, DeviceRegistry)` — updated signature
- [ ] `EngineHost::getProjectSnapshotJson()` passes `project_.deviceRegistry()`
- [ ] Anonymous `deviceToVar(DeviceState)` is deleted (old if/else-if chain, lines 80–264)
- [ ] Anonymous `deviceFromVar(var)` is deleted (old if/else-if chain, lines 266–429)
- [ ] Anonymous `trackToVar(TrackState)` is deleted (lines 575–605)
- [ ] Anonymous `trackFromVar(var)` is deleted (lines 607–634)
- [ ] `audioapp::deviceToVar(DeviceState, DeviceRegistry)` still exists (public overload, line 936)
- [ ] `audioapp::deviceFromVar(var, DeviceRegistry)` still exists (public overload, line 942)
- [ ] `trackToVarPersistence`/`trackFromVarPersistence` still exist (Phase 2, unchanged)
- [ ] `projectFileToJson` and `parseProjectFileJson` signatures unchanged from Phase 2
- [ ] Snapshot JSON schema is identical to before (each device has `"meters"` sub-object for dynamics)
- [ ] All existing C++ tests pass without modification
- [ ] All Flutter tests pass without modification
- [ ] Audio thread code has zero changes
- [ ] `IDeviceType.hpp`, `DeviceRegistry.hpp`, `DeviceSlot.hpp` have zero changes
- [ ] All `*DeviceType.cpp` files have zero changes
- [ ] All `*Instance.hpp` / `*Instance.cpp` files have zero changes
- [ ] No Flutter files were changed