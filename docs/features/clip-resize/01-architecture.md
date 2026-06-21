# Architecture: Clip Resize in Arranger View

## Overview

Clip resize is a Flutter UI feature backed by the existing engine `setClipLength` infrastructure. There is no new audio processing — resizing simply changes a `double lengthBeats` field on the clip model, which affects when the clip ends during playback (MIDI note truncation, sample region end, automation curve end).

## Architecture diagram

```
┌───────────────────────────────────────────────────────────────────┐
│  Flutter UI                                                        │
│                                                                    │
│  ArrangementView (StatefulWidget)                                  │
│  ├── ArrangementViewState                                          │
│  │   ├── _ClipResizeSession (new state field)                      │
│  │   ├── _startClipResize(globalPos, clipId, startBeat, ...)       │
│  │   ├── _updateClipResize(details)                                │
│  │   ├── _endClipResize()                                          │
│  │   └── _cancelClipResize()                                       │
│  │                                                                  │
│  ├── _TrackLane (per-track)                                        │
│  │   ├── _MidiClipBlock                                            │
│  │   │   └── _ClipResizeHandle (new widget, overlaid right edge)   │
│  │   ├── _SampleClipBlock                                          │
│  │   │   └── _ClipResizeHandle                                     │
│  │   └── _AutomationClipBlock                                      │
│  │       └── _ClipResizeHandle                                     │
│  │                                                                  │
│  └── _ClipDragPreview (unchanged — separate from resize)           │
│                                                                     │
│  ArrangementTimelineMetrics (helpers)                               │
│  ├── quantizeBeat()         ← reuse for snap                        │
│  ├── clipIntervalsForTrack() ← reuse for adjacent-clip detection    │
│  └── kMinClipLengthBeats   ← reuse                                 │
│                                                                     │
└──────────────────────┬────────────────────────────────────────────┘
                       │
                       │ setClipLength(clipId, lengthBeats) via MethodChannel
                       ▼
┌───────────────────────────────────────────────────────────────────┐
│  Android Kotlin Bridge (MainActivity.kt)                           │
│  └── MethodChannel handler dispatch to "setClipLength" (existing)  │
└──────────────────────┬────────────────────────────────────────────┘
                       │
                       ▼
┌───────────────────────────────────────────────────────────────────┐
│  C++ Engine                                                        │
│                                                                     │
│  EngineHost::setClipLength()              (existing, thin wrapper)  │
│    └── ProjectEngine::setClipLength()     (existing, mutex + route)  │
│         ├── Check clipRepo_ for MIDI/Sample → setClipLength()      │
│         └── Check automationClipStore_ → setLength()              │
│                                                                     │
│  ClipRepository::setClipLength()          (existing clamps to 0.25) │
│  AutomationClipStore::setLength()         (existing clamps to 0.01) │
│                                                                     │
│  rebuildTrackPlaybackLocked()             (existing — rebuilds audio
│    └── MIDI notes beyond new length are truncated during playback)  │
└───────────────────────────────────────────────────────────────────┘
```

## Module boundaries

| Layer | Module | Responsibility |
|-------|--------|---------------|
| UI | `ArrangementView` | Renders clips, resize handles, handles gesture input, shows live preview |
| Bridge | `EngineBridge` | Dart MethodChannel proxy to Kotlin → C++ |
| Kotlin | `MainActivity.kt` | MethodChannel handler dispatch (existing) |
| C++ | `EngineHost` | Command-layer interface to ProjectEngine |
| C++ | `ProjectEngine` | Thread-safe dispatch to clip stores |
| C++ | `ClipRepository` | MIDI + sample clip CRUD |
| C++ | `AutomationClipStore` | Automation clip CRUD |

## Threading / async boundaries

- **Flutter UI thread**: resize gestures, state updates, `setState` calls, bridge invocation — all on main isolate
- **MethodChannel**: async call to Kotlin, returns `Map<String, dynamic>` snapshot
- **C++ mutex**: `ProjectEngine::setClipLength` acquires `std::shared_mutex` — safe for concurrent access from audio thread (which acquires shared lock) and control thread (which acquires exclusive lock)

## Error model

| Error | Source | Behavior |
|-------|--------|----------|
| Clip ID not found | Engine `setClipLength` returns `false` | Bridge returns error; Flutter catches, shows toast "Failed to resize clip" |
| Bridge call fails | MethodChannel timeout/exception | Flutter catch, roll back preview to pre-resize length, show toast |
| Resize stuck at minimum | UI clamp + engine clamp | Both sides enforce; visual stop at min width |
| Resize blocked by adjacent clip | UI clamp | Visual stop; engine receives the clamped value, not the raw pointer |

## Persistence model

Clip length is persisted as part of project save/load via the existing `ProjectSnapshot` serialization. The `lengthBeats` field on all clip types is already serialized and restored. No new persistence code needed.

## UI / state synchronization model

1. **Resize drag**: Pointer move on resize handle → `_updateClipResize` computes new `previewLengthBeats` → `setState` immediately updates clip width
2. **Commit**: Pointer up → `_endClipResize` → convert `previewLengthBeats` to actual `lengthBeats` → call `EngineBridge.setClipLength` → on success, snapshot refreshes widget state
3. **Rollback**: If bridge call fails, clip width reverts to pre-resize `lengthBeats` (stored in resize session at start)
4. **During playback**: `_suspendFollow()` on resize start, `_resumeFollow()` on commit — matches ruler scrub pattern
