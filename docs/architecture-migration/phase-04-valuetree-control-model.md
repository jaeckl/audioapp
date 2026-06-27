# Phase 4 — ValueTree Control Model

> **Goal:** Replace `std::vector<Track>` / `std::vector<AutomationClip>` / etc.
> with `juce::ValueTree` as the single source of truth on the control thread —
> providing change listeners (auto-trigger `rebuildTrackPlaybackLocked()`),
> undo support, and structured serialization.

## Current state (after Phase 1–3)

The control thread already has decent separation of concerns:

| Class | Storage | Mutations trigger rebuild? |
|-------|---------|---------------------------|
| `TrackRepository` | `std::vector<Track>` | Manual |
| `ClipRepository` | Delegates to `TrackRepository` | Manual |
| `AutomationClipStore` | `std::vector<AutomationClip>` | Manual |
| `ModulationGraph` | Inline arrays | Manual |
| `TransportController` | Scalar fields | Manual |
| `ProjectEngine` | Calls `rebuildTrackPlaybackLocked()` after each mutation (~30 call sites) | — |

Problem: every mutation method in `ProjectEngine` must remember to call
`rebuildTrackPlaybackLocked()` manually. There are **~30 call sites**.
Forgetting one = stale audio playback state.

## Design

### A. ProjectTree — single ValueTree root

```cpp
// engine_juce/include/audioapp/state/ProjectTree.hpp
namespace audioapp::state {

// ValueTree type identifiers
inline constexpr auto kProjectType     = "Project";
inline constexpr auto kTrackType       = "Track";
inline constexpr auto kMidiClipType    = "MidiClip";
inline constexpr auto kSampleClipType  = "SampleClip";
inline constexpr auto kDeviceType      = "Device";
inline constexpr auto kModulatorType   = "Modulator";
inline constexpr auto kModEdgeType     = "ModulationEdge";
inline constexpr auto kAutomationType  = "AutomationClip";

// Property identifiers
namespace props {
    inline constexpr auto id          = "id";
    inline constexpr auto name        = "name";
    inline constexpr auto bpm         = "bpm";
    inline constexpr auto typeId      = "typeId";
    inline constexpr auto bypassed    = "bypassed";
    inline constexpr auto startBeat   = "startBeat";
    inline constexpr auto lengthBeats = "lengthBeats";
    // ... etc
}
```

Project tree structure:

```
Project {
  bpm: 120
  selectedTrackId: "trk_1"
  recordArmed: false
  Track { id: "trk_1", name: "Bass"
    Device { id: "dev_1", typeId: "subtractive_synth" }
    MidiClip { id: "clip_1", startBeat: 0, lengthBeats: 4, ... }
    SampleClip { id: "smp_1", sampleId: "...", ... }
  }
  Modulator { id: 1, typeIndex: 0, ... }
  ModulationEdge { lfoId: 1, deviceId: "dev_1", paramId: "cutoff", amount: 0.3 }
  AutomationClip { id: "auto_1", homeTrackId: "trk_1", deviceId: "dev_1", paramId: "gain", ... }
}
```

### B. ValueTree change listener → auto-rebuild

`ProjectEngine` implements `juce::ValueTree::Listener` and auto-triggers
`rebuildTrackPlaybackLocked()` when a relevant property or child changes:

```cpp
class ProjectEngine : private juce::ValueTree::Listener {
    void valueTreePropertyChanged(juce::ValueTree& tree, const juce::Identifier& property) override {
        if (tree.hasType(state::kDeviceType) && property == state::props::paramValue) {
            scheduleTrackPlaybackRebuild(tree.getParent());
        }
    }
    void valueTreeChildAdded(juce::ValueTree& parent, juce::ValueTree& child) override {
        triggerFullRefresh();
    }
    void valueTreeChildRemoved(juce::ValueTree& parent, juce::ValueTree& child, int) override {
        triggerFullRefresh();
    }
    void valueTreeChildOrderChanged(juce::ValueTree& parent, int, int) override {
        triggerFullRefresh();
    }
};
```

This eliminates the ~30 manual `rebuildTrackPlaybackLocked()` calls.

### C. Adapter: ValueTree ↔ Track/AutomationClip snapshots

Keep the existing `buildSnapshot()` method but read from ValueTree instead
of `std::vector<Track>`. The snapshot structs (`TrackPlaybackSnapshot`,
`ProjectSnapshot`) remain unchanged — only the control-thread origin changes.

### D. Incremental approach

Not a big-bang rewrite. 4 small sub-phases:

| Step | What | Files changed | Days |
|------|------|--------------|------|
| **4a** | `ProjectTree` type/property identifiers + helper builders, make `ProjectEngine` a ValueTree::Listener | NEW: `ProjectTree.hpp`, MODIFY: `ProjectEngine.hpp/cpp` | 1 |
| **4b** | Migrate `TrackRepository` + `ClipRepository` storage to ValueTree child nodes | `TrackRepository.hpp/cpp`, `ClipRepository.hpp/cpp` | 2 |
| **4c** | Migrate `AutomationClipStore`, `ModulationGraph` metadata (edge list) to ValueTree | `AutomationClipStore.hpp/cpp`, `ModulationGraph.hpp/cpp` | 2 |
| **4d** | Add `UndoManager` + undoable actions for basic mutations (param changes, BPM, clip move) | NEW: `UndoCommands.cpp`, MODIFY: `ProjectEngine` | 2 |
| **4e** | JSON backward-compat adapter; tests | `ProjectJson.cpp`, tests | 2 |

**Total effort: ~9 days** (vs 14.5 in the original doc, because repositories already exist)

### E. What stays unchanged

- `TrackPlaybackSnapshot`, `DeviceNodePlayback`, `ProcessorArena` — audio-thread only
- `DeviceInstance` variant — still the parameter storage per device
- `ParamRegistry` — still the canonical param descriptor list
- `SnapshotDelta` — still used for bridge deltas (derived from ValueTree changes)
- Flutter code — no changes needed (it consumes snapshots/deltas as before)

## Migration steps

### Step 4a: ProjectTree skeleton + Listener

1. Create `state/ProjectTree.hpp` with type/property identifiers
2. Add `juce::ValueTree projectRoot_{state::kProjectType}` to `ProjectEngine`
3. Add `juce::ValueTree::Listener` inheritance to `ProjectEngine`
4. Implement listener callbacks that call `rebuildTrackPlaybackLocked()`
5. Remove manual `rebuildTrackPlaybackLocked()` calls from mutation methods
6. Test: verify rebuild still fires correctly via listener

### Step 4b: Migrate TrackRepository

1. Change `TrackRepository::tracks_` from `std::vector<Track>` to
   `juce::ValueTree` child management
2. `addTrack()` → `projectRoot_.addChild(trackTree, ...)`
3. `deleteTrack()` → `projectRoot_.removeChild(trackTree, ...)`
4. `findTrack()` → navigate children by `props::id` property
5. Keep `Track` struct as a value type for snapshot building; add
   `trackFromValueTree()` / `trackToValueTree()` helpers
6. Build snapshot from ValueTree children instead of `tracks_` vector

### Step 4c: Migrate AutomationClipStore + ModulationGraph metadata

Same pattern: replace `std::vector<AutomationClip>` with ValueTree children.

### Step 4d: UndoManager

1. Add `std::unique_ptr<juce::UndoManager>` to `ProjectEngine`
2. Create `UndoableAction` subclasses:
   - `SetPropertyAction` — wraps `ValueTree::setProperty`
   - `AddChildAction` — wraps `ValueTree::addChild`
   - `RemoveChildAction` — wraps `ValueTree::removeChild`
3. Expose `undo()` / `redo()` methods on `EngineHost`
4. Wire bridge commands for undo/redo (optional for UI)

### Step 4e: Backward-compat JSON

1. `toProjectFileData()` now traverses ValueTree instead of vectors
2. `loadFromProjectFileData()` now builds ValueTree instead of filling vectors
3. `ProjectJson.cpp` adapter handles old format → new ValueTree

## Risk assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Listener fires at wrong time (e.g. during bootstrap) | Medium | Use `ValueTree::setPropertyExcludingListener()` during load |
| Performance: listener cascade on bulk operations | Low | Batch under `UndoManager::beginNewTransaction()` |
| Device params stored in `DeviceInstance` variant, not ValueTree | Low | Params stay in variant; ValueTree track child holds `DeviceConfig` as opaque property |
| Snapshot building must traverse ValueTree instead of vector | Low | `trackFromValueTree()` is O(n) same as vector iteration |
| Undo/redo breaks structural mutations | Medium | Start with simple undo (param, BPM); defer add/remove track until stable |

## Doneness criteria

- [ ] `ProjectEngine::rebuildTrackPlaybackLocked()` triggered by ValueTree listeners, not manual calls
- [ ] All existing mutation commands produce correct snapshots/deltas
- [ ] Project save/load round-trip produces identical state
- [ ] Undo/redo works for at least param changes and BPM
- [ ] All existing engine tests pass
- [ ] Flutter UI updates correctly (no behavioral change)