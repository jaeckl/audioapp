# UX Flow Contract – Clip Resize in Arranger View

## UX Summary

- **User Goal**: Lengthen or shorten any clip (MIDI, Sample, Automation) directly from the arranger timeline by dragging its right-edge resize handle.
- **Main Flow**: User sees a thin vertical resize handle on every clip's right edge → user long-presses the handle → drags left/right → clip width updates live (snapped to beat grid) → user releases → new length committed to engine.
- **Secondary Flows**: User cancels mid-drag (finger lifts without completing gesture) → clip reverts to original length. User resizes during playback → follow-playhead suspends temporarily.
- **Non‑Goals**: Left-edge resize, multi-select resize, numerical length input, resize animation.

## Screen Map

| Screen/Area | Purpose | Entry point | Exit / Next action |
|-------------|---------|-------------|--------------------|
| Arranger View (root) | Timeline with track lanes, clips, ruler, playhead. | Navigation from project view. | User taps a clip to edit it, or uses transport controls. |
| Clip block (MIDI/Sample/Automation) | Rendered clip content with header, body, and resize handle on right edge. | Visible on page load per project data. | Resize handle drag → clip width updates live. |
| Resize handle (`_ClipResizeHandle`) | 32px-wide grip zone on right edge of each clip block. | Always visible when clip block is rendered. | Long-press + drag → resize session active. |

## Resize Handle Visual Contract

```
┌──────────────────────┬────┐
│  Clip Content Area   │ ‖  │  ‖ = resize handle (2px vertical bar, 30px padding on each side)
│  (MIDI notes /       │ ‖  │  Total handle zone width: 32px
│   waveform /         │ ‖  │  Handle color: Colors.white54 (0.3 alpha) idle
│   automation curve)  │ ‖  │  Active color: Colors.white (full opacity)
└──────────────────────┴────┘
  <- variable width ->  │<32>│
```

## User Flows

### 1. Resize Clip Flow

- **Trigger**: User long-presses and drags the resize handle on any clip's right edge.
- **Precondition**: Clip is rendered in a track lane, visible in viewport.
- **Steps**:
  1. User places finger on the resize handle zone (rightmost 32px of clip block).
  2. Handle visual changes: color brightens to `Colors.white` (active state).
  3. User drags finger horizontally (no vertical tracking — only horizontal movement matters).
  4. Clip width updates in real-time as finger moves:
     - Dragging **right** → clip lengthens (right edge moves right, content area expands)
     - Dragging **left** → clip shortens (right edge moves left, content area contracts)
     - Width snaps to the 1-beat grid (no sub-beat positions)
     - Width clamps to `adjacentClipStartBeat - clip.startBeat` (cannot overlap next clip)
     - Width clamps to minimum length per clip type
  5. User lifts finger.
  6. Handle returns to idle color.
  7. New length is committed to engine via `EngineBridge.setClipLength()`.
  8. Snapshot refreshes; UI reflects committed state.
- **Expected Feedback**:
  - Immediate visual width change (no ghost, no delay)
  - Handle becomes brighter during drag
  - Adjacent clip is not pushed or moved
  - If next clip is reached, width stalls at clamp point (no bouncy/push feedback — just stops)
- **Success State**: Clip rendered at new width; engine confirms via snapshot.
- **Error State**: Bridge call fails → clip reverts to pre-resize width; toast "Failed to resize clip".

### 2. Cancel Resize Flow

- **Trigger**: Long-press gesture cancelled (finger lifted off screen without completing, or gesture system cancels).
- **Steps**:
  1. Gesture cancel detected.
  2. `_resizeSession` cleared.
  3. Clip width snaps back to `originalLengthBeats`.
  4. Handle returns to idle color.
  5. No bridge call made.
- **Feedback**: Clip width instantly reverts to pre-drag size; no toast, no error.

### 3. Resize During Playback Flow

- **Trigger**: User starts resize drag while project is playing.
- **Steps**:
  1. `_suspendFollow()` called (follow-playhead temporarily disabled — same as when user manually scrolls during playback).
  2. Resize proceeds as normal (Flow #1).
  3. On release: `_resumeFollow()` re-enables follow-playhead (playhead jumps back to current position).
- **Feedback**: Playhead stays at position when follow was suspended; timeline does not scroll during resize; follow resumes on release.

## State Contract

### ArrangementViewState

| State | Description | Visual |
|-------|-------------|--------|
| **idle** | No resize active. | Resize handles visible at idle color. |
| **resizing** | `_resizeSession` is non-null; user is dragging handle. | Resize handle active color; clip width updates live. |
| **committing** | Resize ended; awaiting bridge response. | Clip shows final preview width (same as last drag position). |
| **error** | Bridge call failed. | Clip width reverts to pre-resize length; error toast shown. |
| **cancelled** | Gesture cancelled mid-drag. | Clip reverts to pre-resize length instantly. |

### Resize Handle

| State | Description | Visual |
|-------|-------------|--------|
| **idle** | No touch on handle. | Thin vertical bar, `Colors.white.withValues(alpha: 0.3)`. |
| **active** | User is touching/dragging handle. | Thin vertical bar, `Colors.white` (full opacity). |

## Responsive Behavior

- **All screen sizes**: Resize handle remains 32px wide regardless of viewport width.
- **Very zoomed-out** (pixelsPerBeat < 32): If clip width falls below 40px total, the resize handle visually overlaps the clip content (handle stays 32px, clip content shrinks). This is acceptable — the handle remains tappable even on tiny clips.
- **Portrait vs landscape**: No behavior change.

## Accessibility Expectations

- Resize handle has `semanticLabel: "Resize {clipName}"` attribute.
- During drag, accessibility announcements should describe the new length in beats (e.g., "Clip now 6 beats long").
- Touch target for resize handle must be at least 32px wide (the contract defines 32px, which is slightly less than the recommended 48px but matches typical scroll-handle affordances in mobile DAWs. The 32px width is a design decision for visual proportion — the handle is intentionally subtle). **Mitigation**: The handle's `HitTestBehavior.opaque` ensures the full 32px zone responds to touch.

## Implementation Notes

- **Binding decisions**: The resize handle is always visible (not hover-only). The handle uses a separate `GestureDetector` from the clip body. The handle's gesture uses `onLongPressStart` (no delay threshold — activates immediately on touch) because the handle's small hit zone is unlikely to be accidentally triggered.
- **Adjustable decisions**: `kResizeHandleWidth` can be tuned (currently 32px). `resizeGridBeats` can be reduced to 0.5 or 0.25 for finer snap.
- **Contract‑related changes**: If the bridge `setClipLength` does not work for automation clips (it should based on code analysis), a new `setAutomationClipLength` bridge method must be added. Verify during implementation.
- **Testing hints**: Test with clips at various zoom levels, near the edge of the viewport, near loop markers, and with adjacent clips at varying distances.

## UX Risks & Mitigations

| Risk | Description | Mitigation |
|------|-------------|------------|
| Gesture conflict between handle and clip drag | Long-press on the resize handle may trigger the clip's long-press-to-drag. | Separate `GestureDetector` widgets in `Stack` with non-overlapping hit regions; handle uses `HitTestBehavior.opaque` and is rendered after (on top of) the clip body's gesture detector. |
| Accidental resize trigger | User trying to tap a clip triggers resize handle instead. | The handle is only 32px on the right edge — the remaining clip width is unaffected. The handle requires a drag movement to activate (not just a tap). |
| Resize not visible on very short clips | If clip is already at minimum length, dragging left has no effect. | Visual stop at minimum width — clipping prevents further left movement. Handle remains draggable (user can still drag right). |
| Resize past adjacent clip on undo | If user resizes past adjacent clip start (clamped by UI), then moves adjacent clip away, the first clip does not automatically fill the gap. | This is expected behavior — resize only sets length at commit time; it does not track future changes. The user can resize again to fill the gap. |
| Loss of data when shortening | MIDI notes or automation points beyond the new length are truncated during playback but preserved in the model. | The model retains all notes/points; they simply won't play until the clip is lengthened again. This is standard DAW behavior. |
