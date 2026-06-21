# Data Contracts: Clip Resize

## 1. `_ClipResizeSession` (new, private to `arrangement_view.dart`)

```dart
class _ClipResizeSession {
  _ClipResizeSession({
    required this.clipId,
    required this.originalLengthBeats,
    required this.startBeat,
    required this.adjacentClipStartBeat,
    required this.trackId,
    required this.pointerBeatAtStart,
    this.previewLengthBeats,
  });

  final String clipId;
  final String trackId;
  final double originalLengthBeats;
  final double startBeat;
  /// Beat of the next clip's start on same track lane, or double.infinity if none.
  final double adjacentClipStartBeat;
  /// The timeline beat under the pointer at drag start (for computing delta).
  final double pointerBeatAtStart;
  /// Live-updating preview during drag; initially equals originalLengthBeats.
  double previewLengthBeats;

  double get maxLengthBeats =>
      adjacentClipStartBeat.isFinite
          ? (adjacentClipStartBeat - startBeat)
          : double.infinity;
}
```

### Field details

| Field | Type | Initial | Constraints |
|-------|------|---------|-------------|
| `clipId` | `String` | — | Must match engine clip ID |
| `trackId` | `String` | — | Must match engine track ID |
| `originalLengthBeats` | `double` | — | Copied from clip snapshot at drag start |
| `startBeat` | `double` | — | Clip start beat (immutable during resize) |
| `adjacentClipStartBeat` | `double` | `double.infinity` | Must be > `startBeat`; computed from `clipIntervalsForTrack` |
| `pointerBeatAtStart` | `double` | — | Used to compute beat delta from pointer movement |
| `previewLengthBeats` | `double` | = `originalLengthBeats` | Updated on every drag move; clamped to `[minLength, maxLengthBeats]` and snapped to grid |

## 2. Compute preview length

```dart
double _computePreviewLengthBeats(
  double currentPointerBeat,
  _ClipResizeSession session,
  double minLength,
  double grid,
) {
  final delta = currentPointerBeat - session.pointerBeatAtStart;
  final rawLength = session.originalLengthBeats + delta;
  final snapped = ArrangementTimelineMetrics.quantizeBeat(rawLength, grid: grid);
  return snapped.clamp(minLength, session.maxLengthBeats);
}
```

## 3. Adjacent clip detection

```dart
double _findAdjacentClipStartBeat(TrackSnapshot track, String excludeClipId, double clipStartBeat) {
  final starts = ArrangementTimelineMetrics.clipIntervalsForTrack(track)
    .where((interval) => interval.start > clipStartBeat)
    .map((interval) => interval.start)
    .toList()
    ..sort();
  return starts.isNotEmpty ? starts.first : double.infinity;
}
```

## 4. Minimum length constants

| Constant | Value | Used by |
|----------|-------|---------|
| `kMinClipLengthBeats` (Dart) | `0.25` | Flutter UI clamps MIDI/Sample resize |
| `kMinClipLengthBeats` (C++) | `0.25` | `ClipRepository::setClipLength` clamps MIDI/Sample |
| Automation min length (C++) | `0.01` | `AutomationClipStore::setLength` clamps automation |
| Automation min length (Dart) | `0.01` | Flutter UI clamps automation resize preview |

The Flutter side should distinguish minimum length per clip type:
- `ClipContentKind.midi`, `ClipContentKind.sample` → `kMinClipLengthBeats = 0.25`
- `ClipContentKind.automation` → `0.01`

## 5. JSON bridge payload (unchanged)

```json
{
  "method": "setClipLength",
  "args": {
    "clipId": "clip-3",
    "lengthBeats": 6.0
  }
}
```

No new JSON fields are introduced. The existing `setClipLength` bridge already routes through `ProjectEngine::setClipLength` which handles all three clip types.

## 6. No data model changes

No fields added to `MidiClipSnapshot`, `SampleClipSnapshot`, `AutomationClipSnapshot`, `MidiClip`, `SampleClip`, `AutomationClip`, or `AutomationClipState`. The `lengthBeats` field already exists on all clip types in both Dart and C++.
