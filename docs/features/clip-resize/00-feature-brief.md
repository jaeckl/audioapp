# Feature Brief: Clip Resize in Arranger View

> **STATUS: COMPLETED** — Implemented in commit `13acf36` (`feat(arrangement): implement drag-to-resize and live editing for all clip types`).

## User-visible goal

The user can resize any clip (MIDI, Sample, Automation) from the right edge in the arranger view by dragging a resize handle. Resizing lengthens or shortens the clip visually and commits the new length to the engine model. The resize snaps to the beat grid, respects minimum clip length, and cannot overlap adjacent clips.

## Demo script (PO acceptance)

1. User opens a project with MIDI, sample, and automation clips visible
2. User taps and drags the right-edge resize handle of a MIDI clip to the right → clip width grows in real-time, snapping to beat grid
3. User drags the same handle to the left → clip width shrinks in real-time, stops at `kMinClipLengthBeats` (0.25)
4. User resizes a sample clip → same behavior, visual width updates live
5. User resizes an automation clip → same behavior, visual width updates live
6. User drags resize handle past an adjacent clip's start → resize clamps to adjacent clip start edge (no overlap)
7. User releases the handle → new length committed to engine via bridge; snapshot refreshes
8. User undoes the resize → clip returns to previous length
9. User resizes a clip in a playing project → resize works during playback; follow-playhead temporarily suspended

## Non-goals

- Do not implement left-edge resize (would require shifting startBeat, changing overlap detection — v2 feature)
- Do not implement multi-select resize (v2)
- Do not add resize animation or easing (instant width update during drag)
- Do not add a numerical length input for clip resize (v2)
- Do not implement "trim to loop" or "fit to content" resize modes
- Do not add resize undo history beyond the existing per-command undo pattern
- Do not change the `clipDisplayWidthPx` floor-gap logic for sample clips (resize operates on the model, not the display hack)

## Existing code to reuse

- **`ClipRepository::setClipLength()`** — C++ engine already handles MIDI/sample clip length change with min-clamp (`kMinClipLengthBeats = 0.25`)
- **`AutomationClipStore::setLength()`** — C++ engine already handles automation clip length change with min-clamp (0.01)
- **`ProjectEngine::setClipLength()`** — routes to `ClipRepository` for MIDI/sample and to `AutomationClipStore` for automation clips; already takes `std::shared_mutex` lock and calls `rebuildTrackPlaybackLocked()`
- **`EngineHost::setClipLength()`** — thin wrapper around `ProjectEngine::setClipLength`
- **`EngineBridge.setClipLength()`** — Dart bridge method already exists and returns `ProjectSnapshot`
- **`ArrangementClipDragSession`** — existing drag session pattern in Flutter for clip repositioning (long-press ghost); provides the pointer-tracking and commit model to follow
- **`ArrangementTimelineMetrics.quantizeBeat()`** — beat quantization to grid (floor-based, grid = 1.0 beats)
- **`ArrangementTimelineMetrics.clipIntervalsForTrack()`** — existing overlap detection used for placement
- **Existing gesture pattern** — `GestureDetector` with `onLongPressStart/MoveUpdate/End` on clip blocks

## New code required

- **Flutter**: Resize handle widget (`_ClipResizeHandle`) composable for all three clip-block types
- **Flutter**: Resize session state (`ArrangementClipResizeSession`) tracking pointer delta, beat preview, adjacent clip constraint
- **Flutter**: Callback chain: `onResizeClipStart` → `onResizeClipUpdate` → `onResizeClipEnd` through `ArrangementView` → `ArrangementViewState`
- **Flutter**: Visual resize handle painted on right edge of `ArrangementClipChrome`
- **C++**: `setAutomationClipLength()` bridge method on `EngineHost` / `ProjectEngine` / `EngineBridge` (the `setClipLength` bridge already delegates to `AutomationClipStore::setLength` via `ProjectEngine::setClipLength`, but verify the route works for automation clips — it does as shown in `ProjectEngine::setClipLength` which checks `clipRepo_.findMidiClip` / `clipRepo_.findSampleClip` first, then falls through to `automationClipStore_.setLength`)

## Key design decisions

1. **Resize handle**: A skinny rectangular grip on the right edge of each clip block, 32 logical pixels wide (touch-friendly), visually distinct (small vertical bar or chevron icon)
2. **Live preview**: During drag, resize updates the clip width in real-time by calling `setState` — no ghost (unlike repositioning which uses a ghost)
3. **Snap**: Resize snaps to 1.0 beat grid (matching existing `ArrangementTimelineMetrics.quantizeBeat` which uses `grid = 1.0`)
4. **Minimum length**: Enforced at both UI (visual clamp) and engine (engine-side clamp)
5. **Adjacent clip clamping**: If another clip starts at `adjacentStart`, the resize preview width is clamped to `adjacentStart - clip.startBeat` (leaving no gap)
6. **Resize during playback**: `followPlayheadEnabled` is temporarily suspended during resize drag (same pattern as ruler scrub)
