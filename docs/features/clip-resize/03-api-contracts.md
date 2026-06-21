# API Contracts: Clip Resize

## 1. Dart: EngineBridge (existing, no changes)

```dart
Future<ProjectSnapshot> setClipLength({
  required String clipId,
  required double lengthBeats,
}) async {
  return _invokeForSnapshot('setClipLength', {
    'clipId': clipId,
    'lengthBeats': lengthBeats,
  });
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `clipId` | String | Yes | Any valid MIDI, sample, or automation clip ID |
| `lengthBeats` | double | Yes | New length in beats. Engine clamps to minimum. |

**Returns:** `ProjectSnapshot` — full project state after the length change.

**Errors:** Throws if clip ID not found.

## 2. Dart: ArrangementView (new callbacks)

### New constructor parameters for `ArrangementView`

```dart
final Future<void> Function({
  required String clipId,
  required double lengthBeats,
})? onResizeClipCommit;
```

### New constructor parameters for `_TrackLane`

```dart
final void Function({
  required String clipId,
  required String trackId,
  required double startBeat,
  required double lengthBeats,
  required Offset globalPosition,
  required double adjacentClipStartBeat,
}) onResizeClipStart;
final void Function(LongPressMoveUpdateDetails details) onResizeClipUpdate;
final void Function(LongPressEndDetails details) onResizeClipEnd;
final VoidCallback onResizeClipCancel;
```

### New constructor parameters for `_MidiClipBlock`, `_SampleClipBlock`, `_AutomationClipBlock`

```dart
final void Function({
  required String clipId,
  required String trackId,
  required double startBeat,
  required double lengthBeats,
  required Offset globalPosition,
  required double adjacentClipStartBeat,
}) onResizeStart;
final void Function(LongPressMoveUpdateDetails details) onResizeUpdate;
final void Function(LongPressEndDetails details) onResizeEnd;
final VoidCallback onResizeCancel;
```

## 3. C++: EngineHost (existing, no changes)

```cpp
bool EngineHost::setClipLength(const std::string& clipId, double lengthBeats);
```

**Returns:** `true` on success, `false` if clip ID not found.

**Side effects:** Acquires `std::shared_mutex` exclusive lock, calls `rebuildTrackPlaybackLocked()`.

## 4. C++: ProjectEngine (existing, no changes)

```cpp
bool ProjectEngine::setClipLength(const std::string& clipId, double lengthBeats);
```

**Dispatch logic:**

```
if clipId found in ClipRepository (MIDI or sample)
    → clipRepo_.setClipLength(clipId, lengthBeats)
    → rebuildTrackPlaybackLocked()
    → return true
else if clipId found in AutomationClipStore
    → automationClipStore_.setLength(clipId, lengthBeats)
    → rebuildTrackPlaybackLocked()
    → return true
else
    → return false
```

## 5. C++: ClipRepository::setClipLength (existing)

```cpp
bool ClipRepository::setClipLength(const std::string& clipId, double lengthBeats);
```

**Clamp:** `lengthBeats < kMinClipLengthBeats ? kMinClipLengthBeats : lengthBeats`

**Returns:** `true` if clip was found and updated; `false` if not found.

## 6. C++: AutomationClipStore::setLength (existing)

```cpp
bool AutomationClipStore::setLength(const std::string& clipId, double lengthBeats);
```

**Clamp:** `lengthBeats < 0.01 ? 0.01 : lengthBeats`

**Returns:** `true` if clip was found and updated; `false` if not found.

## 7. UX: Clip resize handle contract

The handle is a widget (`_ClipResizeHandle`) overlaid on the right edge of each clip block:

| Property | Value |
|----------|-------|
| Width | `32.0` logical pixels (`kResizeHandleWidth`) |
| Height | 100% of clip block height |
| Hit test | Opaque (`HitTestBehavior.opaque`) — captures pointer events |
| Visual | Thin vertical bar indicator at rightmost 4px; 2px wide `Container` with `resizeHandleColor` |
| Position | `Positioned(right: 0, top: 0, bottom: 0)` inside the clip block `Stack` |
| Gesture | `GestureDetector` with `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd`, `onLongPressCancel` |
| Activation | Gesture starts immediately (no threshold delay — tap-slop of 0) since resize gesture is distinct from tap/double-tap/long-press-drag |
| During drag | Handle color changes to indicate active state; opaque overlay over clip |
| Overlap prevention | Gesture competes with clip-block tap/double-tap — handle should have priority on right edge via separate GestureDetector or by checking pointer position in parent |

**Important**: The resize handle gesture must NOT conflict with the existing long-press-to-drag gesture on the clip block. The handle's `GestureDetector` is a sibling in the clip block's `Stack`, positioned only on the right edge. The handle uses `onLongPressStart` whereas the clip block's drag uses `onLongPressStart` on the parent — having separate gesture areas (handle vs. clip body) avoids conflict because the handle's hit region is physically separate.
