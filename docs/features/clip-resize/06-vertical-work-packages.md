# Vertical Work Packages: Clip Resize

## Package WP-1: Flutter resize UI (handle + session + gesture)

**User-visibility**: User can see a resize handle on every clip, drag it to resize, and see the clip width change in real-time. Releasing commits the resize to the engine.

**Assigned files**:
- `app_flutter/lib/features/arrangement/arrangement_view.dart` (modify)
- `app_flutter/lib/features/arrangement/arrangement_clip_theme.dart` (modify)

**What to implement**:

1. **`_ClipResizeSession`** — private class in `arrangement_view.dart`:
   - Fields: `clipId`, `trackId`, `originalLengthBeats`, `startBeat`, `adjacentClipStartBeat`, `pointerBeatAtStart`, `previewLengthBeats`
   - Getter: `maxLengthBeats` = `adjacentClipStartBeat - startBeat`
   - No `copyWith` needed (mutable `previewLengthBeats` for perf)

2. **`resizeHandleColor` / `resizeHandleActiveColor`** in `arrangement_clip_theme.dart`:
   - `resizeHandleColor` = `Colors.white.withValues(alpha: 0.3)` (idle state)
   - `resizeHandleActiveColor` = `Colors.white` (during drag)

3. **`_ClipResizeHandle`** — private widget in `arrangement_view.dart`:
   - SizedBox with `width: 32.0`, `height: double.infinity`
   - `Stack` child: a thin vertical bar (Container, 2px wide, centered horizontally in 32px, full height)
   - Background: transparent
   - `GestureDetector` with `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd`, `onLongPressCancel`
   - Each callback delegates to a corresponding callback prop

4. **Modify `_MidiClipBlock`, `_SampleClipBlock`, `_AutomationClipBlock`**:
   - Add resize handle callbacks as new constructor parameters
   - Add `_ClipResizeHandle` as an overlay inside the existing `Stack`:
     ```dart
     Positioned(
       right: 0,
       top: 0,
       bottom: 0,
       child: _ClipResizeHandle(
         onResizeStart: ...,
         onResizeUpdate: ...,
         onResizeEnd: ...,
         onResizeCancel: ...,
       ),
     )
     ```
   - The handle is visible at all times (not only on hover — mobile touch)

5. **Modify `_TrackLane`**:
   - Add resize handle callbacks as new constructor parameters
   - Forward them to each clip block
   - Compute `adjacentClipStartBeat` from track's clip intervals (excluding the clip being resized)

6. **Add state fields + methods to `ArrangementViewState`**:
   - `_resizeSession` (null when idle)
   - `_startClipResize({clipId, trackId, startBeat, lengthBeats, globalPosition, adjacentClipStartBeat})`:
     - Create `_ClipResizeSession`
     - Store `pointerBeatAtStart = _beatFromGlobal(globalPosition)`
     - Suspend follow-playhead (same as ruler scrub pattern)
     - `setState(() => _resizeSession = session)`
   - `_updateClipResize(LongPressMoveUpdateDetails details)`:
     - Compute `currentPointerBeat = _beatFromGlobal(details.globalPosition)`
     - Compute `previewLengthBeats` via `_computePreviewLengthBeats` helper
     - `setState(() => _resizeSession!.previewLengthBeats = previewLengthBeats)`
   - `_endClipResize(LongPressEndDetails details)`:
     - Capture final `previewLengthBeats`
     - Clear `_resizeSession`
     - Call `widget.onResizeClipCommit!` with final length
     - Re-enable follow-playhead
   - `_cancelClipResize()`:
     - Clear `_resizeSession` (UI snaps back to original width)
   - `_computePreviewLengthBeats(double pointerBeat, _ClipResizeSession s)`:
     - `delta = pointerBeat - s.pointerBeatAtStart`
     - `raw = s.originalLengthBeats + delta`
     - `snapped = ArrangementTimelineMetrics.quantizeBeat(raw, grid: resizeGridBeats)`
     - `minLength = clipType == automation ? 0.01 : kMinClipLengthBeats`
     - return `snapped.clamp(minLength, s.maxLengthBeats)`

7. **Modify `ArrangementView` constructor**:
   - Add `onResizeClipCommit` callback

8. **Wire callbacks through build()**:
   - Pass `adjacentClipStartBeat` from `_TrackLane` to each clip block
   - Pass resize callbacks through `_TrackLane` → clip block → handle

**Canonical names used**: `_ClipResizeSession`, `_ClipResizeHandle`, `_resizeSession`, `previewLengthBeats`, `originalLengthBeats`, `adjacentClipStartBeat`, `pointerBeatAtStart`, `resizeHandleColor`, `resizeHandleActiveColor`, `kResizeHandleWidth`, `resizeGridBeats`

**API/data contracts used**: `_ClipResizeSession` from §4, `_ClipResizeHandle` contract from §3, minimum length rules from §4

**Dependencies**: `engine_bridge.dart` (existing `setClipLength`), `arrangement_timeline_metrics.dart` (existing `quantizeBeat`, `clipIntervalsForTrack`), `timeline_clip.dart` (existing `kMinClipLengthBeats`)

**Acceptance criteria**:
1. MIDI clip shows resize handle on right edge
2. Sample clip shows resize handle on right edge
3. Automation clip shows resize handle on right edge
4. Dragging handle to right lengthens clip in real-time, snapped to 1-beat grid
5. Dragging handle to left shortens clip in real-time, stops at minimum length
6. Resize clamps to adjacent clip start (cannot overlap)
7. Releasing handle commits new length via bridge
8. If bridge fails, clip reverts to original length
9. During playback, follow-playhead is suspended during resize drag
10. Other clips on same track are not visually affected
11. Resize handle does not interfere with existing long-press-to-drag gesture on clip body

**Parallel-safe**: YES — no engine-side changes needed; pure Flutter UI work. The engine `setClipLength` already handles all clip types.

---

## Package WP-2: Flutter widget tests for resize

**User-visibility**: Not user-facing. Verifies resize handle exists, responds to gestures, and produces correct preview lengths.

**Assigned files**:
- `app_flutter/test/arrangement_view_resize_test.dart` (create)

**What to implement**:
- Widget test: resize handle is rendered on each clip type
- Widget test: dragging right increases preview length
- Widget test: dragging left decreases preview length
- Widget test: resize snaps to beat grid
- Widget test: resize clamps to adjacent clip start
- Widget test: resize clamps to minimum length
- Widget test: resize commits correct `lengthBeats` via mock bridge
- Widget test: resize cancel reverts to original length
- Widget test: resize does not trigger clip drag

**Canonical names used**: All from §2

**Dependencies**: WP-1 must be implemented first (the widget tree must exist to test)

**Acceptance criteria**:
1. All widget tests pass
2. Tests exercise all three clip types

**Parallel-safe**: NO — depends on WP-1 implementation

---

## Package WP-3: C++ engine tests for all-clip-type resize

**User-visibility**: Not user-facing. Verifies that `ProjectEngine::setClipLength` correctly updates all three clip types and enforces minimum length.

**Assigned files**:
- `engine_juce/tests/clip_length_test.cpp` (modify — add tests)

**What to implement**:
- Add test: `setClipLength` on automation clip updates `lengthBeats`
- Add test: `setClipLength` on automation clip enforces minimum length (0.01)
- Add test: `setClipLength` on sample clip updates `lengthBeats`
- Add test: `setClipLength` on unknown clip ID returns false
- Add test: MIDI notes beyond new clip length are properly truncated during playback (via `activeMidiPitchAtBeat` — already exists but extend)

**Canonical names used**: `ProjectEngine::setClipLength`, `AutomationClipStore::setLength`

**Dependencies**: No Flutter dependency. Uses existing `TestHelpers.h`.

**Acceptance criteria**:
1. All C++ tests pass
2. Automation clip length set and clamped correctly
3. Sample clip length set and clamped correctly
4. Unknown clip ID returns false

**Parallel-safe**: YES — can run in parallel with WP-1

---

## Summary of packages

| Package | Name | Parallel-safe | Depends on |
|---------|------|--------------|------------|
| WP-1 | Flutter resize UI | YES | None |
| WP-2 | Flutter resize tests | NO | WP-1 |
| WP-3 | C++ resize tests | YES | None |
