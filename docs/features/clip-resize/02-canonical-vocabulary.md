# Canonical Vocabulary: Clip Resize

## Binding table

| Concept | Canonical name | Type/file | Notes |
|---------|---------------|-----------|-------|
| Resize session state | `_resizeSession` | `ArrangementViewState` | Null when idle, `_ClipResizeSession` when dragging |
| Resize session class | `_ClipResizeSession` | `arrangement_view.dart` (private) | Stores `clipId`, `originalLengthBeats`, `startBeat`, `adjacentClipStartBeat`, `previewLengthBeats` |
| Resize handle widget | `_ClipResizeHandle` | `arrangement_view.dart` (private) | GestureDetector on right edge of clip blocks |
| Start resize callback | `onResizeClipStart` | `_TrackLane` → `ArrangementViewState._startClipResize` | Callback chain from handle gesture to state |
| Update resize callback | `onResizeClipUpdate` | → `ArrangementViewState._updateClipResize` | Pointer move → compute preview |
| End resize callback | `onResizeClipEnd` | → `ArrangementViewState._endClipResize` | Pointer up → commit via bridge |
| Cancel resize callback | `onResizeClipCancel` | → `ArrangementViewState._cancelClipResize` | Gesture cancel → revert preview |
| Resize preview length | `previewLengthBeats` | `_ClipResizeSession` | Live-updating length during drag, not yet committed |
| Original length (pre-resize) | `originalLengthBeats` | `_ClipResizeSession` | Stored at drag start for rollback |
| Adjacent clip start beat | `adjacentClipStartBeat` | `_ClipResizeSession` | Next clip start in same track lane; `double.infinity` if none |
| Snap grid | `resizeGridBeats` | `arrangement_view.dart` | `1.0` — matches existing `ArrangementTimelineMetrics.gridBeats` |
| Minimum clip length (MIDI/Sample) | `kMinClipLengthBeats` | `TimelineClipTypes.hpp` / `timeline_clip.dart` | `0.25` |
| Minimum clip length (Automation) | `kMinAutomationClipLengthBeats` | `AutomationClipStore::setLength()` | `0.01` (hard-coded in setLength) |
| Resize handle width | `kResizeHandleWidth` | `arrangement_view.dart` | `32.0` logical pixels |
| Resize handle color | `resizeHandleColor` | `ArrangementClipTheme` (new) | `Colors.white54` with 0.3 opacity when idle, `Colors.white` when dragging |
| Resize cursor (desktop) | N/A | — | Not applicable for mobile touch; no cursor change |
| Bridge method | `setClipLength` | `EngineBridge` | Existing, unchanged signature |

## Parameter canonical names (bridge JSON)

| JSON key | Type | Range | Default | Notes |
|----------|------|-------|---------|-------|
| `clipId` | string | any valid clip ID | — | Required |
| `lengthBeats` | double | `[minLength, adjacentClipStart)` | — | Already clamped by engine |

## Flutter event callback signatures

| Callback | Signature | Owner |
|----------|-----------|-------|
| `onResizeClipStart` | `({required String clipId, required String trackId, required double startBeat, required double lengthBeats, required Offset globalPosition, required double adjacentClipStartBeat})` | `ArrangementView` |
| `onResizeClipUpdate` | `(LongPressMoveUpdateDetails details)` | `ArrangementView` |
| `onResizeClipEnd` | `(LongPressEndDetails details)` | `ArrangementView` |
| `onResizeClipCancel` | `()` | `ArrangementView` |

## State fields

| Field | Type | Owner | Initial | Description |
|-------|------|-------|---------|-------------|
| `_resizeSession` | `_ClipResizeSession?` | `ArrangementViewState` | `null` | Active resize drag; null when idle |
| `_resizeActive` | `bool` | `ArrangementViewState` | `false` | Derived from `_resizeSession != null` |
