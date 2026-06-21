# DeviceState Refactoring: Architecture Contract

> Replace the monolithic `DeviceState` flat struct with per-device-type snapshot representations, enabling selective frontend polling and eliminating the wasteful `DeviceSlot ↔ DeviceState → DeviceSlot` round-trip during snapshot serialization.

---

## 1. Current State Analysis

### 1.1 The `DeviceState` Struct

`engine_juce/include/audioapp/DeviceState.hpp` defines a struct with **~128 bytes** of fields (50+ float members + 2 strings) that is a superset of every parameter across all 14 device types:

| Device type | Fields used from DeviceState | Fields wasted |
|---|---|---|
| `oscillator` | `id, type, gain, pan, frequencyHz, bypassed` | ~40 fields (~100 bytes) |
| `compressor` | `id, type, gain, pan, compThreshold, compRatio, ...` | ~35 fields (~90 bytes) |
| `subtractive_synth` | `id, type, gain, pan, osc1Shape, osc2Shape, ...` (many) | ~20 fields (~50 bytes) |
| `kick_generator` | `id, type, gain, pan, kickModel, kickPitch, ...` | ~40 fields (~100 bytes) |

Every `DeviceState` instance carries every field regardless of the device's actual type.

### 1.2 Data Flow (Round-Trip Waste)

The snapshot path performs an unnecessary round-trip on every poll:

```
DeviceSlot (typed, compact)
    │
    ▼  ProjectEngine::snapshot() line 416
deviceRegistry_.toSnapshotState(device)
    │  Creates DeviceState with ALL ~50 fields from the typed instance
    │  Wastes: every field not belonging to this device type is default-constructed
    ▼
DeviceState (flat, bloated)  ← stored in TrackState
    │
    ▼  trackToVarSnapshot() → audioapp::deviceToVar()
registry.slotFromSnapshot(device)  →  reconstructs DeviceSlot from DeviceState
    │  Extracts only the fields relevant to the device type from the flat struct
    │  Wastes: must parse DeviceState "type" string, then copy matching fields
    ▼
DeviceSlot (typed, compact)  ← reconstructed, identical to original
    │
    ▼  deviceSlotToVarImpl()
type->slotToVar(slot)  →  produces type-specific JSON
    │
    ▼
JSON string  ← sent to Flutter
```

**Waste per device per snapshot poll:**
- `toSnapshotState()`: copies all 50+ fields, ~40 of which are irrelevant for this device
- `slotFromSnapshot()`: reads back subset of fields, ~40 are ignored
- Total: ~80 unnecessary field copies per device per poll

**Waste at JSON level:** The JSON serialization via `slotToVar` only emits type-relevant parameters (e.g., compressor emits `threshold`, `ratio`, `attack`, `release` — ~6 fields, not 50). So the JSON wire format is already efficient. The waste is in the intermediate DeviceState struct.

### 1.3 Polling Frequency

- Flutter calls `getProjectSnapshot()` via MethodChannel
- Every state-modifying command also returns a full snapshot
- Currently ALL devices on ALL tracks are serialized every time
- The Flutter side then processes ALL device parameters even if only one device's panel is visible

### 1.4 Current Usage of DeviceState

| Location | Usage | Can be eliminated? |
|---|---|---|
| `TrackState::devices` (`ProjectEngine.hpp` line 44) | Storage type for both snapshot and file paths | Yes — replace with `DeviceSlot` |
| `ProjectFileData` (inherits `TrackState`) | File persistence | Yes — replace with `DeviceSlot` |
| `ProjectEngine::snapshot()` (ProjectEngine.cpp line 416) | Calls `toSnapshotState()` to produce DeviceState | Yes — copy DeviceSlot directly |
| `ProjectEngine::toProjectFileData()` (ProjectEngine.cpp line 807) | Calls `toSnapshotState()` for file save | Yes — copy DeviceSlot directly |
| `ProjectEngine::loadFromProjectFileData()` (ProjectEngine.cpp line 879) | Iterates `trackState.devices` and calls `slotFromSnapshot()` | Yes — DeviceSlot is already the target |
| `audioapp::deviceToVar(DeviceState, Registry)` (ProjectJson.cpp line 577) | Public API, converts to DeviceSlot then serializes | Yes — overload taking DeviceSlot directly |
| `audioapp::deviceFromVar(var, Registry)` (ProjectJson.cpp line 584) | Public API, deserializes to DeviceState | Yes — overload returning DeviceSlot directly |
| `DeviceRegistry::toSnapshotState(DeviceSlot)` (DeviceRegistry.hpp) | Converts DeviceSlot → DeviceState | Remove entirely |
| `DeviceRegistry::slotFromSnapshot(DeviceState)` (DeviceRegistry.hpp) | Converts DeviceState → DeviceSlot | Remove entirely (can keep as impl detail) |
| `IDeviceType::toSnapshotState(DeviceSlot)` (IDeviceType.hpp line 28) | Virtual method on each device type | Remove entirely |
| `IDeviceType::slotFromSnapshot(DeviceState)` (IDeviceType.hpp line 30) | Virtual method on each device type | Remove entirely |
| `DeviceState` meter fields | Already removed in Phase 3 | Already done |
| Flutter `DeviceSnapshot.fromMap()` (project_snapshot.dart) | Reads `parameters` sub-object from JSON | No change needed — JSON schema stays same |

### 1.5 Phase 3 Already Achieved

Phase 3 successfully:
- Removed `meterGainReductionDb`/`meterInputLevel` from `DeviceState`
- Added `DeviceMeterState` parallel array on `TrackState`
- Migrated snapshot serialization to registry dispatch
- The snapshot JSON schema is unchanged; Flutter side unchanged

---

## 2. Problem Definition

### 2.1 Current Inefficiencies

1. **Every DeviceState is 128 bytes regardless of type.** A compressor only needs ~32 bytes of type-specific data. The excess is copied on every snapshot poll.

2. **Round-trip conversion:** DeviceSlot → DeviceState → DeviceSlot → JSON. The DeviceState intermediate is purely historical.

3. **No selective polling.** `getProjectSnapshot()` returns everything. There is no way to ask "give me device-42's state only."

4. **Flutter side deserializes everything.** `DeviceSnapshot.fromMap()` reads all ~50 parameters even for devices where the UI only shows a subset.

### 2.2 Quantified Impact

For a project with:
- 4 tracks
- ~3 devices each (average 12 total)
- 60 fps polling

| Metric | Current | After per-device state |
|---|---|---|
| Field copies per poll (C++) | 12 devices × 50 fields = 600 copies | 12 devices × ~8 avg fields = 96 copies |
| Memory per snapshot | 12 × 128B = 1.5 KB | 12 × ~40B avg = 480 bytes |
| JSON payload on wire | Already efficient (~2 KB/project) | No change |
| Bridge calls per frame | 1 (full snapshot) | 1 (full) or N (selective) |

The primary gain is in C++ processing efficiency and the ability to do selective polling, not in wire bandwidth.

### 2.3 Non-Goals

- Changing the file persistence JSON schema (must remain backward-compatible)
- Changing the snapshot JSON schema sent to Flutter (must remain backward-compatible initially)
- Any audio thread changes
- Redesigning `DeviceSlot`, `IDeviceType`, or the registry system

---

## 3. Proposed Options

### 3.1 Option A (Recommended): Per-Device State Structs via DeviceSlot

**Eliminate `DeviceState` entirely.** Replace `TrackState::devices` with `std::vector<DeviceSlot>`. Remove the `toSnapshotState()`/`slotFromSnapshot()` round-trip. All serialization works directly on `DeviceSlot`.

**How it works:**
- `TrackState::devices` changes type: `std::vector<DeviceState>` → `std::vector<DeviceSlot>`
- `ProjectEngine::snapshot()` copies `DeviceSlot` directly (line 416 changes from `toSnapshotState()` to a direct copy)
- `snapshotToJson()` converts DeviceSlot → JSON via `slotToVar` directly
- `projectFileToJson()` same, via `trackToVarPersistence` → `deviceSlotToVarImpl`
- New `audioapp::deviceToVar(DeviceSlot, Registry)` overload for direct serialization
- For selective polling: new bridge command `getDeviceStates(deviceIds[])` returning type-specific JSON

**Upstream impact on ProjectFileData:**
- `ProjectFileData::tracks` is `std::vector<TrackState>`. If `TrackState::devices` changes to `DeviceSlot`, `ProjectFileData` changes too.
- The file JSON serialization (`projectFileToJson`/`parseProjectFileJson`) already uses registry dispatch, so the JSON format is **unchanged**.
- Old `.audioapp.zip` files remain loadable as long as the deserialization path handles the old `DeviceState` → JSON → `varToSlot` flow, which it already does.

**What changes per-device-type:**
- `IDeviceType::toSnapshotState()` and `IDeviceType::slotFromSnapshot()` become dead code. Remove them from the interface.
- `IDeviceType::slotToVar()` and `IDeviceType::varToSlot()` are the only serialization methods.
- `DeviceRegistry::toSnapshotState()` and `DeviceRegistry::slotFromSnapshot()` removed.

### 3.2 Option B: Category-Split DTOs

Keep `DeviceState` but split into categories:
```cpp
struct SynthParams { /* osc1Shape, osc2Shape, oscMix, unisonVoices, ... */ };
struct DynamicsParams { /* threshold, ratio, attack, release, knee, ... */ };
struct DrumParams { /* kickPitch, snareBody, clapSpread, ... */ };
struct SamplerParams { /* trimStartSec, trimEndSec, rootPitch, ... */ };
struct CommonParams { /* id, type, gain, pan, bypassed */ };
struct DeviceState { CommonParams common; std::variant<SynthParams, DynamicsParams, DrumParams, SamplerParams, EmptyParams> typedParams; };
```

**Pros:** Less drastic change, maintains a single DTO type.
**Cons:** Category boundaries are fuzzy (filter params overlap), still requires round-trip conversion, doesn't fully eliminate waste, selective polling is harder.

### 3.3 Option C: Dirty Flags / Version Counters

Keep `DeviceState` as-is but add a `uint64_t version` field on each device. Increment on every parameter change. The Flutter side caches known versions and skips deserialization for unchanged devices.

```cpp
struct DeviceState {
    // ... all current fields ...
    uint64_t version = 0;  // NEW — incremented on every setParameter
};
```

**Pros:** Minimal C++ changes, easy to implement.
**Cons:** Doesn't reduce the JSON payload size (still sends all parameters for every device every time), the version tracking adds complexity on the Flutter side, and if the UI only needs 2 visible devices, it still processes all.

### 3.4 Option D: Hybrid — Keep DeviceState But Enable Selective Direct Slot Serialization

Keep `DeviceState` for the full-snapshot path but add a new bridge entry point that serializes a `DeviceSlot` directly without round-tripping through `DeviceState`:

```
Bridge: getDeviceState(deviceId) → JSON(deviceRegistry_.findDevice(id) → slotToVar)
```

**Pros:** Minimal initial change, enables selective polling.
**Cons:** `DeviceState` struct remains as dead-weight in the full snapshot path, technical debt continues.

---

## 4. Recommendation: Option A (Per-Device State via DeviceSlot)

### 4.1 Rationale

1. **Eliminates the round-trip entirely.** This is the root cause of waste. The DeviceSlot variant already has exactly the right data. The DeviceState intermediate exists only because it predates the variant-based device system.

2. **Architectural correctness.** After Phases 1–3, DeviceState serves only as an intermediate DTO between DeviceSlot and JSON. It has no independent reason to exist. Removing it simplifies the system.

3. **Enables natural selective polling.** Once `TrackState::devices` holds `DeviceSlot` directly, a "get device by ID" bridge command returns type-specific JSON trivially — just call `slotToVar` on the matching slot.

4. **Backward compatible.** The file JSON schema uses `slotToVar`/`varToSlot`. The snapshot JSON schema uses `slotToVar`. Both are unchanged. Old project files load via the existing `varToSlot` path.

5. **No Flutter changes needed initially.** The JSON emitted by `slotToVar` is identical to the JSON emitted by the current `deviceToVar(DeviceState, Registry)` → `slotFromSnapshot` → `slotToVar` chain.

### 4.2 What Exists Already

The per-device instance structs in `engine_juce/include/audioapp/devices/instances/` already contain all device-specific parameters:

| Instance struct | Key fields | Lines |
|---|---|---|
| `OscillatorInstance` | `frequencyHz` | 1 header field |
| `SamplerInstance` | `sampleId, trimStartSec, trimEndSec, ...` | ~10 fields |
| `SubtractiveSynthInstance` | `osc1Shape, osc2Shape, ...` | ~40 fields |
| `CompressorInstance` | `threshold, ratio, attack, release, knee, makeup` | ~6 fields |
| `KickGeneratorInstance` | `kickModel, kickPitch, kickPunch, ...` | ~8 fields |
| `BassSynthInstance` | `bassOscShape, bassSubMix, bassNoise, ...` | ~9 fields |
| ... | ... | ... |

These are the **authoritative** storage of device parameters. `DeviceState` duplicates them.

### 4.3 Approach

Replace `std::vector<DeviceState>` with `std::vector<DeviceSlot>` in `TrackState`. Update all code that reads/writes this field. Remove `toSnapshotState`/`slotFromSnapshot` methods. Add select polling bridge commands.

---

## 5. Canonical Vocabulary

| Concept | Canonical name | Type/file | Notes |
|---|---|---|---|
| Deprecated flat struct (REMOVED) | `DeviceState` | ~~DeviceState.hpp~~ | Replaced by `DeviceSlot` in TrackState |
| Device slot (PRESERVED) | `DeviceSlot` | `DeviceSlot.hpp` | `std::variant<DeviceInstance>` + id/gain/pan/bypassed |
| Per-device instance (PRESERVED) | `OscillatorInstance`, `CompressorInstance`, etc. | `instances/*.hpp` | One struct per device type, contains type-specific fields |
| Track-level device list (MODIFIED) | `TrackState::devices` | `ProjectEngine.hpp` | Changes from `std::vector<DeviceState>` to `std::vector<DeviceSlot>` |
| Project file data (MODIFIED) | `ProjectFileData::tracks` | `ProjectJson.hpp` | `std::vector<TrackState>` — inherits the DeviceSlot change |
| Snapshot-to-JSON (MODIFIED) | `snapshotToJson(ProjectSnapshot, Registry)` | `ProjectJson.hpp` | Now works with DeviceSlot directly, no round-trip |
| File-to-JSON (MODIFIED) | `projectFileToJson(ProjectFileData, Registry)` | `ProjectJson.hpp` | Now works with DeviceSlot directly, no round-trip |
| public deviceToVar (MODIFIED) | `audioapp::deviceToVar(DeviceSlot, Registry)` | `ProjectJson.cpp` | New overload taking DeviceSlot directly |
| public deviceFromVar (MODIFIED) | `audioapp::deviceFromVar(var, Registry)` → `DeviceSlot` | `ProjectJson.cpp` | New overload returning DeviceSlot directly |
| public deviceToVar (REMOVED) | ~~`audioapp::deviceToVar(DeviceState, Registry)`~~ | `ProjectJson.cpp` | Replaced by DeviceSlot overload |
| public deviceFromVar (REMOVED) | ~~`audioapp::deviceFromVar(var, Registry)` → `DeviceState`~~ | `ProjectJson.cpp` | Replaced by DeviceSlot overload |
| Snapshot builder (MODIFIED) | `ProjectEngine::snapshot()` | `ProjectEngine.cpp` | Copies DeviceSlot directly, no `toSnapshotState()` call |
| File builder (MODIFIED) | `ProjectEngine::toProjectFileData()` | `ProjectEngine.cpp` | Copies DeviceSlot directly, no `toSnapshotState()` call |
| File loader (MODIFIED) | `ProjectEngine::loadFromProjectFileData()` | `ProjectEngine.cpp` | Iterates DeviceSlot directly, no `slotFromSnapshot()` call |
| Registry method (REMOVED) | ~~`DeviceRegistry::toSnapshotState(DeviceSlot)`~~ | `DeviceRegistry.hpp` | Dead code — remove |
| Registry method (REMOVED) | ~~`DeviceRegistry::slotFromSnapshot(DeviceState)`~~ | `DeviceRegistry.hpp` | Dead code — remove |
| IDeviceType method (REMOVED) | ~~`IDeviceType::toSnapshotState(DeviceSlot)`~~ | `IDeviceType.hpp` | Dead code — remove |
| IDeviceType method (REMOVED) | ~~`IDeviceType::slotFromSnapshot(DeviceState)`~~ | `IDeviceType.hpp` | Dead code — remove |
| Selective device fetch (NEW) | `EngineHost::getDeviceStatesJson(deviceIds)` | `EngineHost_commands.cpp` | Returns JSON array of per-device state for specified device IDs |
| Bridge command (NEW) | `EngineBridge::getDeviceStates(deviceIds)` | `engine_bridge.dart` | Flutter-side method for selective polling |
| Meter injection (PRESERVED) | `TrackState::deviceMeters` | `ProjectEngine.hpp` | Unchanged from Phase 3. Device meters still injected by `applyLiveDeviceMetersLocked` into the parallel array. Then merged during JSON serialization. |
| Snapshot track serializer (MODIFIED) | `trackToVarSnapshot(TrackState, Registry)` | `ProjectJson.cpp` | Now iterates `std::vector<DeviceSlot>` instead of `std::vector<DeviceState>`. Calls `deviceSlotToVarImpl(slot, registry)` directly — no round-trip. |
| Persistence track serializer (MODIFIED) | `trackToVarPersistence(TrackState, Registry)` | `ProjectJson.cpp` | Now iterates `std::vector<DeviceSlot>`. Calls `deviceSlotToVarImpl(slot, registry)` directly. |
| Persistence track deserializer (MODIFIED) | `trackFromVarPersistence(var, Registry)` | `ProjectJson.cpp` | Returns `DeviceSlot` directly via `deviceVarToSlotImpl`. |
| DeviceSlot serializer (PRESERVED) | `deviceSlotToVarImpl(DeviceSlot, Registry)` | `ProjectJson.cpp` | Unchanged. Already the function that calls `slotToVar`. |
| DeviceSlot deserializer (PRESERVED) | `deviceVarToSlotImpl(var, Registry)` | `ProjectJson.cpp` | Unchanged. Already the function that calls `varToSlot`. |
| Public deviceSlotToVar (PRESERVED) | `audioapp::deviceSlotToVar(DeviceSlot, Registry)` | `ProjectJson.hpp` | Unchanged. |
| Public deviceVarToSlot (PRESERVED) | `audioapp::deviceVarToSlot(string, Registry)` | `ProjectJson.hpp` | Unchanged. |

---

## 6. API/Data Contracts

### 6.1 Modified: `TrackState` (ProjectEngine.hpp)

```cpp
struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceSlot> devices;       // WAS: std::vector<DeviceState>
    std::vector<DeviceMeterState> deviceMeters;  // Phase 3, unchanged
    std::vector<MidiClipState> midiClips;
    std::vector<SampleClipState> sampleClips;
    std::vector<AutomationClipState> automationClips;
};
```

**Impact:** `TrackState` now requires `DeviceSlot.hpp` to be included in `ProjectEngine.hpp`. This include is already present (line 12).

### 6.2 Removed: `DeviceState` (DeviceState.hpp)

The entire file `engine_juce/include/audioapp/DeviceState.hpp` is deleted.

All callers that referenced `DeviceState` must be updated to use `DeviceSlot` instead.

### 6.3 Removed: `IDeviceType::toSnapshotState` and `slotFromSnapshot`

Two virtual methods removed from `IDeviceType`:

```cpp
// REMOVED:
virtual DeviceState toSnapshotState(const DeviceSlot& slot) const = 0;
virtual DeviceSlot slotFromSnapshot(const DeviceState& state) const = 0;
```

All 14 concrete implementations in `*DeviceType.cpp` files have their overrides removed.

### 6.4 Removed: `DeviceRegistry::toSnapshotState` and `slotFromSnapshot`

```cpp
// REMOVED:
DeviceState toSnapshotState(const DeviceSlot& slot) const;
DeviceSlot slotFromSnapshot(const DeviceState& state) const;
```

### 6.5 New: `audioapp::deviceToVar(DeviceSlot, Registry)`

```cpp
// engine_juce/src/ProjectJson.cpp (namespace audioapp)
// Direct serialization from DeviceSlot → juce::var, no round-trip.
// Simply calls deviceSlotToVarImpl(slot, registry).
juce::var deviceToVar(const DeviceSlot& slot, const DeviceRegistry& registry);
```

### 6.6 New: `audioapp::deviceFromVar(var, Registry)` returning `DeviceSlot`

```cpp
// engine_juce/src/ProjectJson.cpp (namespace audioapp)
// Direct deserialization from juce::var → DeviceSlot, no round-trip.
// Simply calls deviceVarToSlotImpl(value, registry).
DeviceSlot deviceFromVar(const juce::var& value, const DeviceRegistry& registry);
```

### 6.7 Deprecated (then removed): Old overloads with `DeviceState`

```cpp
// REMOVED after all callers migrated:
juce::var deviceToVar(const DeviceState& device, const DeviceRegistry& registry);
DeviceState deviceFromVar(const juce::var& value, const DeviceRegistry& registry);
```

### 6.8 New: `EngineHost::getDeviceStatesJson`

```cpp
// engine_juce/include/audioapp/EngineHost.hpp
// engine_juce/src/EngineHost_commands.cpp

/// Returns JSON for a subset of devices, indexed by their deviceId.
/// Used for selective frontend polling.
/// Format: { "ok": true, "devices": { "dev-1": { "type": "...", "parameters": {...}, "meters": {...} }, ... } }
std::string EngineHost::getDeviceStatesJson(const std::vector<std::string>& deviceIds) const;
```

**Implementation:**
```cpp
std::string EngineHost::getDeviceStatesJson(const std::vector<std::string>& deviceIds) const {
    auto snap = project_.snapshot();  // Builds full DeviceSlot-based snapshot
    // Build a map from deviceId → DeviceSlot
    std::unordered_map<std::string, const DeviceSlot*> deviceMap;
    for (const auto& track : snap.tracks) {
        for (const auto& device : track.devices) {
            deviceMap[device.id] = &device;
        }
    }
    auto* obj = new juce::DynamicObject();
    auto* devicesObj = new juce::DynamicObject();
    for (const auto& deviceId : deviceIds) {
        auto it = deviceMap.find(deviceId);
        if (it != deviceMap.end()) {
            juce::var deviceVar = deviceSlotToVarImpl(*it->second, project_.deviceRegistry());
            // Inject meters from trackState.deviceMeters
            // ... (see existing meter injection pattern)
            devicesObj->setProperty(toJuceString(deviceId), deviceVar);
        }
    }
    obj->setProperty("ok", true);
    obj->setProperty("devices", juce::var(devicesObj));
    return toStdString(juce::JSON::toString(juce::var(obj), false));
}
```

### 6.9 New: Flutter-side `EngineBridge::getDeviceStates`

```dart
// app_flutter/lib/bridge/engine_bridge.dart

Future<Map<String, DeviceSnapshot>> getDeviceStates(List<String> deviceIds) async {
  final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceStates', {
    'deviceIds': deviceIds,
  });
  if (result == null || result['ok'] != true) {
    throw PlatformException(...);
  }
  final devices = result['devices'] as Map<dynamic, dynamic>? ?? {};
  return devices.map((key, value) => MapEntry(
    key as String,
    DeviceSnapshot.fromMap(value as Map<dynamic, dynamic>),
  ));
}
```

### 6.10 Modified: `ProjectEngine::snapshot()`

```cpp
ProjectSnapshot ProjectEngine::snapshot() const {
    std::shared_lock<std::shared_mutex> lock(mutex_);
    ProjectSnapshot snap;
    // ... (transport state unchanged) ...
    snap.tracks.reserve(trackRepo_.tracks().size());
    for (const auto& track : trackRepo_.tracks()) {
        TrackState ts;
        ts.id = track.id;
        ts.name = track.name;
        // BEFORE:  ts.devices.push_back(deviceRegistry_.toSnapshotState(device));
        // AFTER:   Direct copy — DeviceSlot is what we want.
        ts.devices.reserve(track.devices.size());
        for (const auto& device : track.devices) {
            ts.devices.push_back(device);  // Copy DeviceSlot directly
        }
        // ... (clip handling unchanged) ...
        snap.tracks.push_back(std::move(ts));
    }
    // ... (automation clips, lfos, mod edges unchanged) ...
    applyLiveDeviceMetersLocked(snap);  // Phase 3 — unchanged
    return snap;
}
```

### 6.11 Modified: `applyLiveDeviceMetersLocked`

Currently iterates `trackState.devices` and reads `device.type` string to identify dynamics devices. With `DeviceSlot`, the type is determined by `std::visit` on the variant, not a string field.

```cpp
void ProjectEngine::applyLiveDeviceMetersLocked(ProjectSnapshot& snap) const {
    for (auto& trackState : snap.tracks) {
        for (auto& device : trackState.devices) {
            const bool isDynamics = std::visit([](const auto& inst) {
                using T = std::decay_t<decltype(inst)>;
                return std::is_same_v<T, GateInstance> ||
                       std::is_same_v<T, CompressorInstance> ||
                       std::is_same_v<T, ExpanderInstance> ||
                       std::is_same_v<T, LimiterInstance>;
            }, device.instance);
            if (!isDynamics) continue;
            // ... (remainder: match via deviceMeterIds_, push to deviceMeters) ...
        }
    }
}
```

### 6.12 Modified: `trackToVarSnapshot` and `trackToVarPersistence`

Both now iterate `std::vector<DeviceSlot>` and call `deviceSlotToVarImpl(slot, registry)` directly — no round-trip through `audioapp::deviceToVar(DeviceState, ...)`.

```cpp
juce::var trackToVarSnapshot(const TrackState& track,
                              const DeviceRegistry& registry) {
    juce::Array<juce::var> devices;
    devices.ensureStorageAllocated(static_cast<int>(track.devices.size()));
    for (size_t i = 0; i < track.devices.size(); ++i) {
        // Direct serialization from DeviceSlot — no round-trip!
        juce::var deviceVar = deviceSlotToVarImpl(track.devices[i], registry);
        // Meter injection (unchanged from Phase 3)
        for (const auto& meter : track.deviceMeters) {
            if (meter.deviceId == track.devices[i].id) { ... }
        }
        devices.add(deviceVar);
    }
    // ... (rest unchanged) ...
}
```

### 6.13 Snapshot JSON Schema (UNCHANGED)

The JSON emitted for each device still has:
```json
{
  "id": "dev-1",
  "type": "compressor",
  "parameters": {
    "gain": 1.0,
    "pan": 0.5,
    "threshold": 0.55,
    "ratio": 0.50,
    ...
  },
  "meters": { "gainReductionDb": 3.5, "inputLevel": 0.82 }
}
```

This is produced by `slotToVar` which already generates type-specific `parameters`. No Flutter changes needed.

### 6.14 File JSON Schema (UNCHANGED)

The file serialization (`projectFileToVar` → `trackToVarPersistence` → `deviceSlotToVarImpl`) already produces the same format. Old files load via `varToSlot` which is unchanged.

---

## 7. File Ownership

### 7.1 Files to Delete

| File | Reason |
|---|---|
| `engine_juce/include/audioapp/DeviceState.hpp` | Struct definition removed entirely |

### 7.2 Files to Modify

| File | Changes | Owner package |
|---|---|---|
| `engine_juce/include/audioapp/ProjectEngine.hpp` | Change `TrackState::devices` type from `std::vector<DeviceState>` to `std::vector<DeviceSlot>`. Remove `#include "audioapp/DeviceState.hpp"` (may be used elsewhere — check first). Keep `#include "audioapp/devices/DeviceSlot.hpp"` (already present). | P0-P1 |
| `engine_juce/src/ProjectEngine.cpp` | In `snapshot()`: copy DeviceSlot directly instead of calling `toSnapshotState()`. In `toProjectFileData()`: same. In `loadFromProjectFileData()`: iterates DeviceSlot directly (already `slotFromSnapshot` — just remove the conversion call). Update `applyLiveDeviceMetersLocked` to use `std::visit` instead of string type comparison. Remove `#include "audioapp/DeviceState.hpp"` if present. | P0-P2 |
| `engine_juce/src/ProjectJson.cpp` | Update `trackToVarSnapshot()` to iterate `DeviceSlot` and call `deviceSlotToVarImpl()` directly (no `audioapp::deviceToVar(DeviceState, ...)`). Update `trackToVarPersistence()` and `trackFromVarPersistence()` similarly. Add `audioapp::deviceToVar(DeviceSlot, Registry)` overload. Add `audioapp::deviceFromVar(var, Registry)` returning `DeviceSlot`. Remove old `audioapp::deviceToVar(DeviceState, Registry)` and `audioapp::deviceFromVar(var, Registry)` → DeviceState after callers are updated. Remove `#include "audioapp/DeviceState.hpp"`. | P0-P3 |
| `engine_juce/include/audioapp/ProjectJson.hpp` | Update `deviceToVar` and `deviceFromVar` declarations to use `DeviceSlot`. | P0-P3 |
| `engine_juce/src/EngineHost_commands.cpp` | Add `getDeviceStatesJson()` implementation. Update `getProjectSnapshotJson()` if signature changes. | P0-P4 |
| `engine_juce/include/audioapp/EngineHost.hpp` | Add `getDeviceStatesJson()` declaration. | P0-P4 |
| `engine_juce/include/audioapp/devices/DeviceRegistry.hpp` | Remove `toSnapshotState()` and `slotFromSnapshot()` declarations. | P0-P1 |
| `engine_juce/src/devices/DeviceRegistry.cpp` | Remove `toSnapshotState()` and `slotFromSnapshot()` implementations. | P0-P1 |
| `engine_juce/include/audioapp/devices/IDeviceType.hpp` | Remove `toSnapshotState()` and `slotFromSnapshot()` virtual methods. | P0-P1 |
| All `*DeviceType.cpp` (14 files) | Remove `toSnapshotState()` and `slotFromSnapshot()` override implementations. | P0-P5 |
| All `*DeviceType.hpp` (14 files) | Remove `toSnapshotState()` and `slotFromSnapshot()` override declarations. | P0-P5 |
| `app_flutter/lib/bridge/engine_bridge.dart` | Add `getDeviceStates()` method. | P0-P6 |
| All test files that use `DeviceState` or call removed methods | Update to use `DeviceSlot`. | P0-P7 |

### 7.3 Files NOT Modified (Read-Only)

| File | Rationale |
|---|---|
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | No changes needed. The variant and struct are already correct. |
| `engine_juce/include/audioapp/devices/instances/*.hpp` | Instance structs are unchanged. Their data is what `slotToVar` reads. |
| `app_flutter/lib/bridge/project_snapshot.dart` | JSON schema is identical. `DeviceSnapshot.fromMap` reads `parameters` from JSON — no change. |
| `app_flutter/lib/features/device_strip/*.dart` | All Flutter UI code reads from `DeviceSnapshot` objects. No change. |
| `engine_juce/include/audioapp/DeviceChain.hpp` | Audio thread structs and `DeviceMeterAtomic` unchanged. |
| All audio thread code (DSP modules) | Zero changes — audio thread never touches DeviceState. |

---

## 8. Vertical Work Packages

### Package P0-P1 (Prerequisite): Remove DeviceState, update TrackState and DeviceRegistry/IDeviceType

**Behavior:** `DeviceState.hpp` deleted. `TrackState::devices` is `std::vector<DeviceSlot>`. `IDeviceType` no longer has `toSnapshotState`/`slotFromSnapshot`. `DeviceRegistry` no longer has `toSnapshotState`/`slotFromSnapshot`.

**Files changed:**
- `engine_juce/include/audioapp/DeviceState.hpp` — DELETE
- `engine_juce/include/audioapp/ProjectEngine.hpp` — change field type, verify includes
- `engine_juce/include/audioapp/devices/DeviceRegistry.hpp` — remove two methods
- `engine_juce/src/devices/DeviceRegistry.cpp` — remove two implementations

**Canonical names used:** `DeviceSlot`, `TrackState`, `DeviceRegistry`, `IDeviceType`

**Acceptance criteria:**
- Codebase compiles without `DeviceState.hpp`
- `TrackState::devices` is `std::vector<DeviceSlot>` and compiles
- `DeviceRegistry` has no `toSnapshotState()` or `slotFromSnapshot()` methods
- All non-test C++ files that previously included `DeviceState.hpp` have been updated

**Parallelization:** Sequential prerequisite. All other packages depend on this.

**Integration risk:** High if any code outside the known callers uses `DeviceState`. Need to grep thoroughly.

---

### Package P0-P2 (Parallel-safe after P0-P1): Update ProjectEngine.cpp

**Behavior:** `snapshot()` copies DeviceSlot directly. `toProjectFileData()` copies DeviceSlot directly. `loadFromProjectFileData()` iterates DeviceSlot directly. `applyLiveDeviceMetersLocked` uses `std::visit` instead of string type comparison.

**Files changed:**
- `engine_juce/src/ProjectEngine.cpp`

**Canonical names used:** `DeviceSlot`, `ProjectSnapshot`, `TrackState`, `applyLiveDeviceMetersLocked`

**Acceptance criteria:**
- `snapshot()` produces `TrackState::devices` containing `DeviceSlot`
- `toProjectFileData()` produces `ProjectFileData` with `DeviceSlot` in `track.devices`
- `loadFromProjectFileData()` reads `DeviceSlot` from `ProjectFileData` directly
- `applyLiveDeviceMetersLocked` correctly identifies dynamics devices via variant visit
- No compilation errors

**Parallelization:** Parallel-safe with P0-P3 (different files).

---

### Package P0-P3 (Parallel-safe after P0-P1): Update ProjectJson.cpp serialization

**Behavior:** All serialization functions work with `DeviceSlot` directly. New `audioapp::deviceToVar(DeviceSlot, Registry)` and `audioapp::deviceFromVar(var, Registry)` → `DeviceSlot` overloads. Old `DeviceState` overloads removed.

**Files changed:**
- `engine_juce/src/ProjectJson.cpp`
- `engine_juce/include/audioapp/ProjectJson.hpp`

**Canonical names used:** `DeviceSlot`, `deviceSlotToVarImpl`, `deviceVarToSlotImpl`, `trackToVarSnapshot`, `trackToVarPersistence`, `trackFromVarPersistence`

**Acceptance criteria:**
- `trackToVarSnapshot` iterates `std::vector<DeviceSlot>` and calls `deviceSlotToVarImpl` directly
- `trackToVarPersistence` same
- `trackFromVarPersistence` returns `DeviceSlot` via `deviceVarToSlotImpl` directly
- `audioapp::deviceToVar(DeviceSlot, Registry)` exists and compiles
- `audioapp::deviceFromVar(var, Registry)` returns `DeviceSlot`
- Old `audioapp::deviceToVar(DeviceState, Registry)` and `audioapp::deviceFromVar(var, Registry)` → `DeviceState` are removed
- Snapshot JSON output is byte-identical to Phase 3 for same input
- File JSON output is byte-identical to Phase 3 for same input

**Parallelization:** Parallel-safe with P0-P2 (no file overlap).

---

### Package P0-P4 (Sequential after P0-P3): Add selective polling bridge command

**Behavior:** New `EngineHost::getDeviceStatesJson(deviceIds)` and Flutter-side `EngineBridge::getDeviceStates(deviceIds)`.

**Files changed:**
- `engine_juce/src/EngineHost_commands.cpp`
- `engine_juce/include/audioapp/EngineHost.hpp`
- `app_flutter/lib/bridge/engine_bridge.dart`

**Canonical names used:** `getDeviceStatesJson`, `getDeviceStates`

**Acceptance criteria:**
- `EngineHost::getDeviceStatesJson({"dev-1", "dev-3"})` returns JSON with only those two devices
- JSON format: `{"ok": true, "devices": {"dev-1": {...}, "dev-3": {...}}}`
- Each device's JSON is identical to what `trackToVarSnapshot` would produce for that device
- Meters are injected for dynamics devices
- Unknown device IDs are silently omitted (no error)
- Empty device ID list returns empty devices object
- Flutter `getDeviceStates` correctly parses the response into `Map<String, DeviceSnapshot>`
- Old `getProjectSnapshot()` still works unchanged

**Parallelization:** Sequential after P0-P3 (because it uses the new serialization path).

---

### Package P0-P5 (Sequential after P0-P1): Remove old overrides from all 14 device type implementations

**Behavior:** All `*DeviceType.hpp` and `*DeviceType.cpp` files have `toSnapshotState()` and `slotFromSnapshot()` overrides removed.

**Files changed:**
- 14 `*DeviceType.hpp` files
- 14 `*DeviceType.cpp` files

**Canonical names removed:** `toSnapshotState`, `slotFromSnapshot`

**Acceptance criteria:**
- No `toSnapshotState` or `slotFromSnapshot` override remains in any device type file
- All files still compile (the removed overrides were the implementations of removed virtual methods)
- `slotToVar` and `varToSlot` remain (these are still needed for serialization)

**Parallelization:** Sequential after P0-P1 (interface changed), but can run in parallel with P0-P2, P0-P3, P0-P4.

---

### Package P0-P6 (Sequential after P0-P4): Flutter selective polling integration

**Behavior:** The DAW shell or appropriate state management code optionally polls only visible devices instead of the full snapshot.

**Files changed:**
- `app_flutter/lib/bridge/engine_bridge.dart` (already modified in P0-P4)
- `app_flutter/lib/app/daw_shell.dart` (or equivalent polling code)

**Canonical names used:** `getDeviceStates`, `EngineBridge`

**Acceptance criteria:**
- Flutter can optionally call `getDeviceStates(visibleDeviceIds)` instead of full `getProjectSnapshot()`
- The polling interval for selective polling can be higher (e.g., 60fps for visible devices vs 15fps for full snapshot)
- Full snapshot is still used on state-modifying command responses (which return full snapshot anyway)

**Note:** This package is marked "optional" — the core architecture works without changing Flutter polling behavior. The selective polling capability exists; whether to use it is a UI-level decision.

**Parallelization:** Sequential after P0-P4.

---

### Package P0-P7 (Sequential after P0-P5): Update tests

**Behavior:** All C++ tests that use `DeviceState`, `toSnapshotState()`, or `slotFromSnapshot()` are updated.

**Files changed:**
- `engine_juce/tests/device_slot_serialization_test.cpp` — verify slotToVar/varToSlot round-trip still works (unchanged in behavior)
- `engine_juce/tests/project_serialization_test.cpp` — update if DeviceState is used in test construction
- Any test file that fails to compile due to removed symbols

**Acceptance criteria:**
- All C++ tests compile and pass
- All Flutter tests pass without changes
- Device round-trip tests using DeviceSlot directly produce identical JSON to old DeviceState-based tests

**Parallelization:** Sequential after P0-P5.

---

## 9. Parallelism and Dependencies

```
P0-P1 (prerequisite: remove DeviceState, update TrackState, DeviceRegistry, IDeviceType)
  │
  ├──→ P0-P2 (parallel: update ProjectEngine.cpp)
  │
  ├──→ P0-P3 (parallel: update ProjectJson.cpp serialization)
  │
  └──→ P0-P5 (parallel: update all 14 *DeviceType.cpp files to remove overrides)
          │
          └──→ P0-P4 (sequential: add selective polling bridge) → P0-P6 (sequential: Flutter side, optional)
                                     │
                                     └──→ P0-P7 (sequential: update tests)
```

| Package | Runs | Files | Dependencies |
|---------|------|-------|-------------|
| P0-P1 | First | `DeviceState.hpp`, `ProjectEngine.hpp`, `DeviceRegistry.hpp/.cpp` | None |
| P0-P2 | After P0-P1 | `ProjectEngine.cpp` | P0-P1 (needs TrackState::devices type change) |
| P0-P3 | After P0-P1 | `ProjectJson.cpp`, `ProjectJson.hpp` | P0-P1 (needs DeviceSlot in TrackState) |
| P0-P4 | After P0-P3 | `EngineHost_commands.cpp`, `EngineHost.hpp`, `engine_bridge.dart` | P0-P3 (needs direct slot serialization) |
| P0-P5 | After P0-P1 | 14 `*DeviceType.hpp`, 14 `*DeviceType.cpp` | P0-P1 (needs IDeviceType interface change) |
| P0-P6 | After P0-P4 | `daw_shell.dart`, bridge files | P0-P4 (needs getDeviceStates bridge command) |
| P0-P7 | After P0-P5 | Test files | P0-P5 (compilation only correct after overrides removed) |

### Shared files requiring care

- **`ProjectEngine.hpp`** — only P0-P1 touches it. However, since it's an include-heavy header, changes to the `TrackState::devices` type will cause downstream recompilation of many files. All packages after P0-P1 will need to ensure their includes are correct (no lingering `#include "DeviceState.hpp"`).

- **`ProjectJson.cpp`** — touched by P0-P3 only. No conflict risk.

- **`EngineHost.hpp` / `EngineHost_commands.cpp`** — touched by P0-P4 only.

- **All `*DeviceType.cpp` files** — touched by P0-P5 only.

---

## 10. Selective Polling Design (Flutter Frontend Changes)

### 10.1 How It Works

The existing polling pattern is:
```dart
// Current: poll everything at some rate
Future<void> _poll() async {
  final snap = await bridge.getProjectSnapshot();
  setState(() => _snapshot = snap);
}
```

The new capability:
```dart
// New: poll only visible device IDs at high rate
Future<void> _pollVisible() async {
  final deviceStates = await bridge.getDeviceStates(_visibleDeviceIds);
  _snapshot = _snapshot.withMergedDeviceStates(deviceStates);
}

// Existing: still get full snapshot on state changes
Future<void> _onDeviceParamChange(deviceId, paramId, value) async {
  final snap = await bridge.setDeviceParameter(deviceId: deviceId, ...);
  setState(() => _snapshot = snap);
}
```

### 10.2 Caching Strategy

The `ProjectSnapshot` on the Flutter side acts as a cache:
- Full snapshot fetched on state-modifying commands (already happens)
- Selective device-state fetches between commands (new capability)
- `withMergedDeviceStates(Map<String, DeviceSnapshot>)` merges freshly fetched device states into the cached snapshot

### 10.3 Determining Visible Devices

The Flutter UI already knows which devices are visible:
- The `DeviceChainScreen` renders `DeviceStripSlot` widgets for each device
- Only the selected track's devices are shown in full (parameters editable)
- Other tracks show minimal chrome (gain, pan, bypass)
- The visible device list can be derived from the current UI state

### 10.4 Polling Rates

| Data | Current | After refactor |
|---|---|---|
| Transport state | Via `getTransportState()` (lightweight) | Unchanged |
| Full project snapshot | 60fps | 15fps (background refresh) |
| Visible devices | N/A | 60fps (via `getDeviceStates`) |
| Dynamics meters | Included in full snapshot | Included in selective fetch |

### 10.5 Meter Handling

Dynamics meters (`gainReductionDb`, `inputLevel`) change every frame and are important for visual feedback. The selective polling path MUST include meter data:
- `getDeviceStates` builds a `ProjectSnapshot` internally (to access meter data)
- For each requested device, it injects meters from `TrackState::deviceMeters`
- The Flutter side receives meters as part of each device's JSON

This means building the full snapshot internally is still necessary for meter data access, but the serialization cost is limited to only the requested devices.

---

## 11. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| **Compiler errors from lingering `DeviceState` references** — code outside the known callers may include `DeviceState.hpp` and use the struct | **High** — blocks compilation | Mitigation: thorough grep for `DeviceState` across entire codebase before merging P0-P1. Any usage outside `ProjectEngine.cpp`, `ProjectJson.cpp`, and `*DeviceType.*` files must be reported and excluded. |
| **`ProjectFileData` backward compatibility** — old `.audioapp.zip` files contain JSON that was read via `deviceFromVar(var, Registry)` → `DeviceState`. If DeviceState is removed, the return type changes. | **Medium** | Mitigation: the deserialization path (`parseProjectFileJson` → `trackFromVarPersistence` → `audioapp::deviceFromVar`) already goes through `deviceVarToSlotImpl` which returns `DeviceSlot`. The `DeviceState` was just an intermediate. Changing the return type to `DeviceSlot` is transparent. But old files that embed `DeviceState` fields directly (none — Phase 2 already migrated to registry dispatch) would need special handling. |
| **Flutter side deserialization breaks** if JSON schema changes | **High** if it happens | Mitigation: JSON schema is UNCHANGED. `slotToVar` produces the same `parameters` sub-object. Meters come in the same format. No Flutter changes needed for the initial migration. |
| **Meters lost in selective polling** — `getDeviceStatesJson` builds a snapshot internally and injects meters, but if the snapshot-building/ meter-injection path has a bug, meters show 0.0 | **Medium** | Mitigation: `getDeviceStatesJson` calls `project_.snapshot()` which includes `applyLiveDeviceMetersLocked`. The meter injection logic in the selective path must explicitly be tested. |
| **`std::visit` in `applyLiveDeviceMetersLocked` is slower than string comparison** | **Low** — variant visit is typically as fast as a switch-on-index | Mitigation: profile if concerned. The function is called once per snapshot build (not per frame). |
| **New `audioapp::deviceToVar(DeviceSlot, Registry)` conflicts with old `deviceToVar(DeviceState, Registry)`** — overload resolution ambiguity | **Low** | Mitigation: remove old overload at the same time as adding new one. P0-P3 does both in one atomic change. |
| **`TrackState` copying is now heavier** — `DeviceSlot` contains strings and a variant, which is more expensive to copy than a flat POD `DeviceState`. | **Medium** | Mitigation: `TrackState` is typically small (3-6 devices per track) and is only constructed once per snapshot or file save. The copies happen on the control thread under a mutex. The savings from eliminating the round-trip (DeviceSlot → DeviceState conversion) outweigh the slightly heavier copies. Additionally, `std::vector` moves are used (reserve + push_back with move semantics). |
| **Header dependency bloat** — `ProjectEngine.hpp` already includes `DeviceSlot.hpp`. No new includes needed. | **None** | Already handled. |
| **`IDeviceType` interface change breaks third-party device types** | **Low** — no third-party device types exist | There are no external plugins. All 14 types are in-tree. We update all 14 in P0-P5. |

---

## 12. Implementation Order (Recommended)

### Phase 0 — 7 packages, implement in this order:

1. **P0-P1 (Prerequisite):** Delete `DeviceState.hpp`. Change `TrackState::devices` type. Remove `toSnapshotState`/`slotFromSnapshot` from `IDeviceType` and `DeviceRegistry`. Verify compilation.

2. **P0-P2 (Parallel with P0-P3, after P0-P1):** Update `ProjectEngine.cpp` — `snapshot()`, `toProjectFileData()`, `loadFromProjectFileData()`, `applyLiveDeviceMetersLocked`.

3. **P0-P3 (Parallel with P0-P2, after P0-P1):** Update `ProjectJson.cpp` — direct DeviceSlot serialization. Add new overloads. Remove old DeviceState overloads.

4. **P0-P5 (Parallel with P0-P2, P0-P3, after P0-P1):** Remove `toSnapshotState`/`slotFromSnapshot` overrides from all 14 *DeviceType.cpp files.

5. **P0-P4 (After P0-P3):** Add `getDeviceStatesJson` bridge command and Flutter `getDeviceStates` method.

6. **P0-P6 (After P0-P4, optional):** Integrate selective polling in Flutter UI.

7. **P0-P7 (After P0-P5):** Update tests. Verify all C++ and Flutter tests pass.

### Verification order:

1. Compile engine library: `cmake --build build/engine --target audioapp_engine`
2. Run all C++ tests
3. Run Flutter tests: `cd app_flutter && flutter test`
4. Manual: compare snapshot JSON output before/after — must be identical for same project
5. Manual: compare file JSON output before/after — must be identical for same project
6. Manual: test selective `getDeviceStates` returns correct subset

---

## 13. Worker Instructions for Implementation Agents

Each implementation worker MUST:

1. **Obey canonical names** as defined in §5. Do not invent synonyms.
2. **Stay within assigned files** as defined in §7. Do not edit files outside your package's allowed list.
3. **Not invent public APIs** beyond what's specified in §6.
4. **Not rename concepts** — "DeviceSlot", "deviceSlotToVarImpl", "trackToVarSnapshot" are binding names.
5. **Not redesign architecture** — the approach (eliminate DeviceState, use DeviceSlot directly) is fixed.
6. **Stop and report** if any contract item is ambiguous or missing. Do not guess.

### Package P0-P1 instructions

1. Grep the entire codebase for `DeviceState` to find all references. Report findings before deleting.
2. Delete `engine_juce/include/audioapp/DeviceState.hpp`.
3. In `ProjectEngine.hpp`: change `std::vector<DeviceState> devices;` to `std::vector<DeviceSlot> devices;`. Verify `DeviceSlot.hpp` is already included (line 12).
4. Remove `#include "audioapp/DeviceState.hpp"` from `ProjectEngine.hpp` if present.
5. In `DeviceRegistry.hpp`: remove `DeviceState toSnapshotState(const DeviceSlot&) const;` and `DeviceSlot slotFromSnapshot(const DeviceState& state) const;`.
6. In `DeviceRegistry.cpp`: remove implementations of the above methods.
7. In `IDeviceType.hpp`: remove `virtual DeviceState toSnapshotState(const DeviceSlot& slot) const = 0;` and `virtual DeviceSlot slotFromSnapshot(const DeviceState& state) const = 0;`.
8. Verify compilation after each step.

### Package P0-P2 instructions

1. Wait for P0-P1 to be merged.
2. In `ProjectEngine.cpp`:
   - `snapshot()` (line 415): Change `ts.devices.push_back(deviceRegistry_.toSnapshotState(device));` to `ts.devices.push_back(device);` (DeviceSlot can be pushed directly since TrackState::devices is now vector<DeviceSlot>).
   - `toProjectFileData()` (line 807): Same change — `ts.devices.push_back(device);`.
   - `loadFromProjectFileData()` (line 879): The loop already iterates `trackState.devices` which is now `vector<DeviceSlot>`. Change `track.devices.push_back(deviceRegistry_.slotFromSnapshot(deviceState));` to `track.devices.push_back(deviceState);` (direct copy).
   - `applyLiveDeviceMetersLocked()` (line 1078): Change type detection from `device.type != "gate" && ...` to `std::visit` with `std::is_same_v<T, GateInstance>`, etc.
3. Remove `#include "audioapp/DeviceState.hpp"` from `ProjectEngine.cpp` if present.
4. Verify compilation.

### Package P0-P3 instructions

1. Wait for P0-P1 to be merged.
2. In `ProjectJson.cpp`:
   - `trackToVarSnapshot()` (line 521): Change `audioapp::deviceToVar(track.devices[i], registry)` to `deviceSlotToVarImpl(track.devices[i], registry)` (direct, no round-trip).
   - `trackToVarPersistence()` (line 459): Same change.
   - `trackFromVarPersistence()`: The return is already `TrackState`. The internal `audioapp::deviceFromVar(deviceVar, registry)` call returns `DeviceState` (in current code). Change to a new overload or use `deviceVarToSlotImpl` directly — the result is already a `DeviceSlot` that gets pushed into `track.devices`.
   - Add new function: `juce::var deviceToVar(const DeviceSlot& slot, const DeviceRegistry& registry)` in `namespace audioapp` that calls `deviceSlotToVarImpl(slot, registry)`.
   - Add new function: `DeviceSlot deviceFromVar(const juce::var& value, const DeviceRegistry& registry)` in `namespace audioapp` that calls `deviceVarToSlotImpl(value, registry)`.
   - Remove old `audioapp::deviceToVar(DeviceState, Registry)` (line 577).
   - Remove old `audioapp::deviceFromVar(var, Registry)` → `DeviceState` (line 584).
3. In `ProjectJson.hpp`:
   - Change `juce::var deviceToVar(const DeviceState& device, const DeviceRegistry& registry);` to `juce::var deviceToVar(const DeviceSlot& slot, const DeviceRegistry& registry);`
   - Change `DeviceState deviceFromVar(const juce::var& value, const DeviceRegistry& registry);` to `DeviceSlot deviceFromVar(const juce::var& value, const DeviceRegistry& registry);`
4. Remove `#include "audioapp/DeviceState.hpp"` from `ProjectJson.cpp` if present.
5. Verify compilation.

### Package P0-P4 instructions

1. Wait for P0-P3 to be merged.
2. In `EngineHost.hpp`: add `std::string getDeviceStatesJson(const std::vector<std::string>& deviceIds) const;`.
3. In `EngineHost_commands.cpp`: implement `getDeviceStatesJson`. Call `project_.snapshot()` to get the current state (already returns DeviceSlot-based TrackState). Iterate requested device IDs. For each, find the matching DeviceSlot across all tracks. Serialize via `deviceSlotToVarImpl`. Inject meters from the track's `deviceMeters` array. Build response JSON.
4. In `EngineHost_commands.cpp` or the bridge command handler: add a case for `"getDeviceStates"` MethodChannel command that calls `getDeviceStatesJson` with the provided device IDs.
5. In `app_flutter/lib/bridge/engine_bridge.dart`: add `getDeviceStates(List<String> deviceIds)` method.
6. Verify compilation on both sides.

### Package P0-P5 instructions

1. Wait for P0-P1 to be merged.
2. For each of the 14 *DeviceType.hpp files, remove the `toSnapshotState` and `slotFromSnapshot` override declarations.
3. For each of the 14 *DeviceType.cpp files, remove the `toSnapshotState` and `slotFromSnapshot` override implementations.
4. The `slotToVar` and `varToSlot` implementations must remain — they are the serialization path.
5. If any device type had logic in `toSnapshotState` that wasn't purely field-copying (unlikely — they all just copy instance fields to DeviceState fields), that logic is simply removed.
6. Verify compilation.

### Package P0-P6 instructions (optional)

1. Wait for P0-P4 to be merged.
2. Identify the polling site (likely `app_flutter/lib/app/daw_shell.dart`).
3. Add a mechanism to track currently visible device IDs (derived from UI state).
4. Add an optional fast timer that calls `getDeviceStates(visibleDeviceIds)` at 60fps.
5. Keep the full `getProjectSnapshot()` call on state-modifying command responses.
6. Add `ProjectSnapshot.withMergedDeviceStates(Map<String, DeviceSnapshot>)` method.
7. Verify Flutter tests pass.

### Package P0-P7 instructions

1. Wait for P0-P5 to be merged.
2. Run all C++ tests. Fix any compilation failures (likely in tests that construct `DeviceState` directly).
3. Run `cd app_flutter && flutter test`. Fix any failures (unlikely — JSON schema unchanged).
4. If new tests are needed, add:
   - A test for `deviceSlotToVarImpl` / `deviceVarToSlotImpl` round-trip (existing test may already cover this)
   - A test for `getDeviceStatesJson` returning the correct subset
   - A test for selective polling JSON format
5. Report any contract gaps found during test updates.

---

## 14. Success Criteria (Checklist)

### Core architecture
- [ ] `DeviceState.hpp` deleted from the codebase
- [ ] `TrackState::devices` type changed to `std::vector<DeviceSlot>`
- [ ] `IDeviceType::toSnapshotState()` removed from interface and all implementations
- [ ] `IDeviceType::slotFromSnapshot()` removed from interface and all implementations
- [ ] `DeviceRegistry::toSnapshotState()` and `slotFromSnapshot()` removed
- [ ] All 14 `*DeviceType.cpp` files have `toSnapshotState`/`slotFromSnapshot` overrides removed

### Serialization
- [ ] `audioapp::deviceToVar(DeviceSlot, Registry)` exists, works directly with DeviceSlot
- [ ] `audioapp::deviceFromVar(var, Registry)` returns `DeviceSlot`, not `DeviceState`
- [ ] Old `audioapp::deviceToVar(DeviceState, Registry)` overload removed
- [ ] Old `audioapp::deviceFromVar(var, Registry)` → `DeviceState` removed
- [ ] `trackToVarSnapshot` iterates DeviceSlot and calls `deviceSlotToVarImpl` directly
- [ ] Snapshot JSON output is identical to Phase 3 output
- [ ] File JSON output is identical to Phase 3 output
- [ ] Old `.audioapp.zip` files load correctly

### Engine
- [ ] `ProjectEngine::snapshot()` copies DeviceSlot directly (no `toSnapshotState`)
- [ ] `ProjectEngine::toProjectFileData()` copies DeviceSlot directly
- [ ] `ProjectEngine::loadFromProjectFileData()` reads DeviceSlot directly
- [ ] `applyLiveDeviceMetersLocked` uses `std::visit` for dynamics type detection
- [ ] Audio thread code has zero changes

### Selective polling
- [ ] `EngineHost::getDeviceStatesJson()` exists and returns only requested devices
- [ ] Meters are injected correctly in the selective polling path
- [ ] Flutter `getDeviceStates()` bridge method exists and parses correctly
- [ ] Full `getProjectSnapshot()` still works unchanged

### Tests
- [ ] All C++ tests compile and pass
- [ ] All Flutter tests pass without changes

### Flutter (unchanged)
- [ ] `DeviceSnapshot.fromMap()` unchanged
- [ ] `ProjectSnapshot.fromMap()` unchanged
- [ ] All UI code unchanged (unless P0-P6 integrated)