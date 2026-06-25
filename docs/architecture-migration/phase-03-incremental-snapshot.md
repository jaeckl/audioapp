# Phase 3 — Incremental Snapshots

> **Goal:** Stop serializing the entire project state on every mutation. Instead, return only the changed subset — delta-based UI updates.

## Current State

Every mutation command (`setDeviceParameter`, `setBpm`, `addTrack`, etc.) calls `getProjectSnapshotJson()` which serializes the **complete project tree** (all tracks, clips, devices, modulators, automation) and returns it through 3 JSON round-trips.

For a slider drag (`setDeviceParameter`), the entire project is serialized — but only one float changed in one device. This wastes:

- CPU: `juce::JSON::toString()` on the full tree
- Binder bandwidth: MethodChannel serializes the full map through IPC
- Dart GC: `ProjectSnapshot.fromMap()` allocates many intermediate objects
- Frametime: Flutter rebuilds the entire widget tree from the snapshot

## Design

### A. Snapshot Delta Type

```cpp
// engine_juce/include/audioapp/snapshot/SnapshotDelta.hpp
namespace audioapp::snapshot {

struct DeviceParamDelta {
    std::string deviceId;
    std::string paramId;
    float newValue;
};

struct DeviceDelta {
    std::string deviceId;
    std::vector<DeviceParamDelta> params;
    bool deviceAdded = false;
    bool deviceRemoved = false;
};

struct TrackDelta {
    std::string trackId;
    std::vector<DeviceDelta> devices;
    bool trackAdded = false;
    bool trackRemoved = false;
    bool trackSelected = false;
};

struct ModulatorDelta {
    int lfoId = 0;
    std::vector<std::pair<std::string, float>> params;
    bool modulatorAdded = false;
    bool modulatorRemoved = false;
};

struct TransportDelta {
    bool bpmChanged = false;
    int newBpm = 120;
    bool playingChanged = false;
    bool newPlaying = false;
};

struct SnapshotDelta {
    std::vector<TrackDelta> tracks;
    std::vector<ModulatorDelta> modulators;
    std::optional<TransportDelta> transport;
    bool fullRefresh = false;  // set on project load, undo, structural change

    std::string toJson() const;
};

} // namespace audioapp::snapshot
```

### B. Engine Mutation Returns Delta

Each mutation method on `EngineHost` / `ProjectEngine` returns a `SnapshotDelta` instead of a full JSON string:

```cpp
// EngineHost.hpp (modified)
class EngineHost {
    // Old: std::string setDeviceParameter(deviceId, paramId, value);
    // New:
    snapshot::SnapshotDelta setDeviceParameter(const std::string& deviceId,
                                                const std::string& parameterId,
                                                float value);
};
```

For simple param changes, the delta is tiny:

```json
{
    "tracks": [{
        "trackId": "abc123",
        "devices": [{
            "deviceId": "dev456",
            "params": [{"paramId": "filterCutoff", "newValue": 0.75}]
        }]
    }]
}
```

For structural changes (add/remove track/clip), set `fullRefresh = true` and the full snapshot is returned as today.

### C. Full Snapshot Still Available

`getProjectSnapshot()` still exists for initial load, full refresh, and explicit polling. But 90% of mutations use the delta path.

### D. Bridge Delta Handling

```cpp
// BridgeHost::handleCommand() — delta-aware
std::string BridgeHost::handleCommand(const std::string& method,
                                       const std::string& argumentsJson) {
    // ... command registry dispatch ...
    auto delta = engine().commandRegistry().execute(method, args);
    return delta.toJson();  // lightweight JSON, not full project tree
}
```

The Dart side merges deltas into the cached snapshot:

```dart
class SnapshotStore {
    ProjectSnapshot _cached;

    void applyDelta(Map<String, dynamic> delta) {
        if (delta['fullRefresh'] == true) {
            _cached = ProjectSnapshot.fromMap(delta['fullSnapshot']);
            notifyListeners();
            return;
        }
        // Apply incremental updates to _cached
        for (final trackDelta in delta['tracks']) {
            final track = _cached.tracks.firstWhere((t) => t.id == trackDelta['trackId']);
            for (final deviceDelta in trackDelta['devices']) {
                final device = track.devices.firstWhere((d) => d.id == deviceDelta['deviceId']);
                for (final paramDelta in deviceDelta['params']) {
                    device.parameters[paramDelta['paramId']] = paramDelta['newValue'];
                }
            }
        }
        notifyListeners();
    }
}
```

### E. Throttled State Polling

For high-frequency updates during playback (position, meters), keep dedicated polling:

```dart
// Existing: TransportState polling — keep as-is (lightweight, no full tree)
Future<TransportState> getTransportState();

// Existing: getDeviceStates(List<ids>) — keep as-is (returns only requested devices)
Future<Map<String, DeviceSnapshot>> getDeviceStates(List<String> deviceIds);
```

These already avoid the full snapshot. The delta system is for **mutation responses** (user edits), not for real-time monitoring.

## Changes Required

| File | Change |
|------|--------|
| **NEW** `SnapstonDelta.hpp` | Delta struct + serialization |
| **MODIFY** `ProjectEngine.hpp/cpp` | Return `SnapshotDelta` from mutations |
| **MODIFY** `EngineHost_commands.cpp` | Thread deltas through command handlers |
| **MODIFY** `BridgeHost.cpp` | Return delta JSON instead of full snapshot |
| **MODIFY** Dart `engine_bridge.dart` | Parse delta, merge into `ProjectSnapshot` |
| **NEW** Dart `snapshot_store.dart` | Cached snapshot + delta merge + `ChangeNotifier` |
| **MODIFY** All Flutter screens | Consume from `SnapshotStore` instead of raw bridge |

## Test Strategy

1. **C++ delta unit tests:** Every mutation produces correct delta, `fullRefresh` triggers on structural changes
2. **Dart delta merge tests:** Apply deltas to various cached states, verify correct merge
3. **Round-trip equivalence test:** For each mutation, verify that full-snapshot path and delta path produce the same final Flutter state
4. **Performance benchmark:** Compare MethodChannel payload size before/after for typical slider drag

## Effort Estimate

| Item | Days |
|------|------|
| Delta struct + serialization | 1 |
| Return delta from ProjectEngine mutations | 2 |
| Bridge delta handling | 0.5 |
| Dart SnapshotStore + delta merge | 1.5 |
| Migrate Flutter screens | 1 |
| Tests | 2 |
| **Total** | **8** |

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Missing a mutation that needs fullRefresh | Medium | Assertion in debug mode: if UI shows stale data, investigate |
| Dart merge logic diverges from C++ truth | Low | Full sync available on explicit `getProjectSnapshot()` call |
| Delta serialization overhead beats purpose | Low | Benchmark: delta is ~200 bytes vs ~50KB full snapshot for a typical project |