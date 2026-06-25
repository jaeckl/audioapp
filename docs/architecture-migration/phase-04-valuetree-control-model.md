# Phase 4 — ValueTree Control Model

> **Goal:** Replace ad-hoc `juce::DynamicObject` trees and manual mutation/notification with `juce::ValueTree` as the control-thread state model — providing change listeners, undo support, and structured serialization.

## Current State

The control thread manages project state through:

- `TrackState`, `TrackPlaybackSnapshot` — hand-rolled structs with manual serialization
- `SnapstonDelta` (Phase 3) — manual diff building
- `DeviceConfig` + `DeviceSlot` — `std::variant` tree visited manually
- JSON serialization — `juce::DynamicObject` property-by-property in each `*DeviceType.cpp`
- No undo/redo at all
- No property change listeners — Flutter polls or gets full snapshot

JUCE's `juce::ValueTree` provides all of this: hierarchical state, value change listeners, undo manager integration, and `toXml()`/`fromXml()` serialization.

## Design

### A. ValueTree Structure

```cpp
// engine_juce/include/audioapp/state/ProjectTree.hpp
namespace audioapp::state {

// Type identifiers (ValueTree type strings)
inline constexpr auto kProjectType    = "Project";
inline constexpr auto kTrackType      = "Track";
inline constexpr auto kClipType       = "Clip";
inline constexpr auto kDeviceType     = "Device";
inline constexpr auto kModulatorType  = "Modulator";
inline constexpr auto kModEdgeType    = "ModulationEdge";
inline constexpr auto kAutomationType = "AutomationClip";

// Property identifiers
namespace props {
    inline constexpr auto id         = "id";
    inline constexpr auto name       = "name";
    inline constexpr auto bpm        = "bpm";
    inline constexpr auto typeId     = "typeId";
    inline constexpr auto paramValue = "paramValue";  // stored per ParamId
    inline constexpr auto bypassed   = "bypassed";
    inline constexpr auto startBeat  = "startBeat";
    inline constexpr auto lengthBeats = "lengthBeats";
    // ... all properties for all node types
}

// Top-level project tree:
// Project {
//   ID: "proj_001"
//   bpm: 120
//   Track { id: "trk_1", name: "Bass"
//     Device { id: "dev_1", typeId: "subtractive_synth"
//       paramValue: { pid: 0x40001, value: 0.5 }  // ParamId::FilterCutoff = 0.5
//       ...
//     }
//     Clip { id: "clip_1", type: "midi", startBeat: 0, lengthBeats: 4, ... }
//   }
//   Modulator { id: 1, typeIndex: 0, ... }
//   ModulationEdge { lfoId: 1, paramId: "dev_1/filterCutoff", amount: 0.3 }
// }
```

### B. From Flat Structs to ValueTree

The current `TrackState` becomes a ValueTree with child nodes for devices and clips:

```cpp
// Before:
struct TrackState {
    std::string id;
    std::string name;
    std::vector<DeviceSlot> devices;
    std::vector<ClipData> clips;
    // ...
};

// After — project state is a single ValueTree root:
juce::ValueTree projectRoot_{kProjectType};
```

### C. Change Listeners

ValueTree's `addListener()` automatically fires on any property or child change:

```cpp
class ProjectEngine : private juce::ValueTree::Listener {
    // Called on any ValueTree mutation (add/remove/change property)
    void valueTreePropertyChanged(juce::ValueTree& tree, const juce::Identifier& property) override {
        // Auto-detect what changed and trigger snapshot rebuild
        if (tree.hasType(kDeviceType) && property == props::paramValue) {
            // This is a device param change — rebuild playback for affected track
            auto trackTree = tree.getParent();
            auto trackId = trackTree[props::id].toString().toStdString();
            scheduleTrackPlaybackRebuild(trackId);
        }
    }

    void valueTreeChildAdded(juce::ValueTree& parent, juce::ValueTree& child) override {
        // New device/modulator/clip — rebuild affected state
        triggerFullRefresh();
    }
};
```

This **replaces** the manual change-detection and diff-building from Phase 3's `SnapshotDelta`. The delta is derived automatically by comparing before/after states.

### D. Undo Manager Integration

```cpp
class ProjectEngine {
    std::unique_ptr<juce::UndoManager> undoManager_;
    juce::ValueTree projectRoot_;

    void performUndoableAction(std::unique_ptr<juce::UndoableAction> action) {
        undoManager_->perform(std::move(action));
    }

    bool undo() { return undoManager_->undo(); }
    bool redo() { return undoManager_->redo(); }
};
```

JUCE's `UndoableAction` wraps ValueTree mutations. `ValueTree::setPropertyExcludingListener` can be used to apply changes without triggering listener callbacks.

### E. Serialization

ValueTree serializes via `toXml()`/`fromXml()`:

```cpp
// Save:
std::unique_ptr<juce::XmlElement> xml = projectRoot_.toXml(juce::Identifier("audioapp"));
juce::String xmlStr = xml->toString();

// Load:
projectRoot_ = juce::ValueTree::fromXml(*juce::XmlDocument::parse(xmlStr));
```

This is simpler than hand-building `DynamicObject` trees and guarantees structural validity.

However, for backward compatibility with the existing `project.json` format, an **adapter layer** converts between the old `juce::DynamicObject` format and `juce::ValueTree` during save/load. This can be deprecated once all clients migrate.

### F. Audio Thread Bridge (unchanged)

The audio thread **never touches** `juce::ValueTree`. The `rebuildTrackPlaybackLocked()` function still reads `TrackState` — but `TrackState` is now built from the ValueTree:

```cpp
TrackPlaybackSnapshot ProjectEngine::rebuildTrackPlayback(const std::string& trackId) {
    // Navigate ValueTree to find the track
    auto trackTree = findTrackTree(trackId);
    TrackPlaybackSnapshot snap;
    snap.trackId = trackId;
    // ... fill from ValueTree properties
    for (auto deviceTree : trackTree) {
        if (deviceTree.hasType(kDeviceType)) {
            auto& device = snap.devices[snap.deviceCount++];
            device.deviceId = deviceTree[props::id].toString().toStdString();
            auto* type = registry_.find(deviceTree[props::typeId].toString().toStdString());
            type->buildPlaybackNode(/* fill from deviceTree */);
        }
    }
    return snap;
}
```

The audio-thread data structures (`TrackPlaybackSnapshot`, `ProcessorArena`, `DeviceNodePlayback`) remain unchanged. Only the control-thread origin changes.

## Changes Required

| File | Change |
|------|--------|
| **NEW** `engine_juce/include/audioapp/state/ProjectTree.hpp` | Type/property identifiers, helper builders |
| **NEW** `engine_juce/include/audioapp/state/ProjectTreeBuilder.hpp` | ValueTree → TrackState conversion |
| **MODIFY** `ProjectEngine.hpp/cpp` | Replace `std::vector<TrackState>` with `juce::ValueTree` root |
| **MODIFY** All mutation methods (addTrack, setBpm, etc.) | Operate on ValueTree; register undoable actions |
| **MODIFY** `ProjectJson.cpp` | Adapter: old JSON format ↔ ValueTree (backward compat) |
| **MODIFY** `EngineHost_commands.cpp` | Listeners auto-trigger snapshot/delta rebuild |
| **NEW** `engine_juce/src/state/UndoCommands.cpp` | `UndoableAction` subclasses for each mutation type |
| **MODIFY** `EngineHost.hpp` | Expose `UndoManager` for future UI undo/redo buttons |
| **TESTS** | Existing round-trip tests must pass with new storage |

## What stays unchanged

| Component | Why |
|-----------|-----|
| `TrackPlaybackSnapshot` struct | Audio-thread read-only; no JUCE dependency on audio thread |
| `ProcessorArena` | Audio-thread arena; no ValueTree |
| `ModulatorArena` + double-buffer | Audio-thread only |
| `DeviceChainOrchestrator` | Audio-thread processing; no ValueTree |
| `thread_local` buffers | Stack-based, no change |

## Test Strategy

1. **ValueTree round-trip:** Create state via ValueTree API, serialize to XML, deserialize, verify equality
2. **Listener correctness:** Every mutation fires the expected listener callbacks
3. **Undo/redo:** Perform sequence of operations, undo all, verify initial state
4. **Backward-compat JSON:** Save via old format, load into ValueTree, verify same state
5. **Audio bridge unchanged:** All audio tests pass with new control-thread storage

## Effort Estimate

| Item | Days |
|------|------|
| `ProjectTree.hpp` type/property identifiers | 0.5 |
| ValueTree migration of TrackState | 3 |
| ValueTree migration of device params (via registry integration) | 2 |
| ValueTree migration of modulators + edges | 1 |
| JSON backward-compat adapter | 2 |
| UndoManager integration + undoable actions | 2 |
| Change listeners + auto-rebuild triggers | 1 |
| Tests | 3 |
| **Total** | **14.5** |

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| ValueTree XML JSON diff from current `project.json` | High | Adapter layer guarantees backward compat; existing tests verify |
| Performance regression from ValueTree listener cascade | Low | Batch mutations under `UndoManager::beginNewTransaction()` |
| Migrating 21 device types' params into ValueTree properties | Medium | Phase 1's ParamRegistry provides the exact property list for each type |
| Undo complexity (nested mutations, modulations referencing devices) | Medium | Start with simple undo (params, BPM), defer complex undo (add/remove track) |