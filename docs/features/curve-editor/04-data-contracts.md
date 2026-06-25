# Data Contracts: Fullscreen Curve Modulator Editor

## 1. Canonical Vocabulary

| Concept | Canonical name | Type/file | Notes |
|---------|---------------|-----------|-------|
| Curve modulator editor screen | `CurveEditorScreen` | `curve_editor_screen.dart` | Fullscreen `StatefulWidget`, pushed via `Navigator.push` |
| Editor painter | `_CurveEditorPainter` | `curve_editor_screen.dart` | `CustomPainter` for the curve canvas |
| Breakpoint index | `bpIdx` | `int` | 0-based index into breakpoint arrays (max 32) |
| Breakpoint position | `position` | `double` | Normalized X [0, 1], mapped to `bp_{i}_pos` |
| Breakpoint value | `value` | `double` | Normalized Y [0, 1] for unipolar, [-1, 1] for bipolar; mapped to `bp_{i}_val` |
| Breakpoint shape | `shape` | `int` | 0=linear, 1=smooth (cubic hermite), 2=step; mapped to `bp_{i}_shape` |
| Segment | `segment` | `int` | Index of the segment between bp[i] and bp[i+1] (0-based, count-1 segments) |
| Polarity | `polarity` | `int` in `LfoSnapshot` | 0=bipolar (center line, fill from center), 1=unipolar-positive (fill from bottom) |
| Breakpoint count | `breakpointCount` | `int` | [2, 32], mapped to `'breakpointCount'` param |
| Steps stepper | step +/- buttons | `CurveEditorScreen` header | Increment/decrement `breakpointCount` |
| `onOpenEditor` | `onOpenEditor` | `VoidCallback?` in `CurvePropertiesPanel` | Existing callback, currently TODO — wires to `CurveEditorScreen` push |
| `onUpdate` | `onUpdate` | `Future<void> Function(String param, double value)` | Existing bridge callback — used for all param updates |
| `applyParamUpdate` | `applyParamUpdate` | `LfoSnapshot.applyParamUpdate` | Dart-side optimistic update (already handles `bp_*`, `breakpointCount`, `polarity`) |

### Shape enum (shared with engine, defined in `CurveBreakpoint.shape`)

| Value | Canonical name | Description |
|-------|---------------|-------------|
| 0 | `linear` | Straight line between breakpoints |
| 1 | `smooth` | Cubic Hermite interpolation (s-curve) |
| 2 | `step` | Hold previous breakpoint value until next |

### Terms

| Term | Definition |
|------|-----------|
| Curve editor | Fullscreen view for editing a single curve modulator's breakpoints |
| Breakpoint dot | A draggable point on the curve (position × value) |
| Segment | The span between two adjacent breakpoints, rendered as a line/shape |
| Canvas | The `CustomPaint` area where the curve, grid, and breakpoints are rendered |
| Zero line | Horizontal line at Y center (bipolar) or Y bottom (unipolar) |
| Fill | Semi-transparent area between curve and zero line |

## 2. API / Data Contracts

### 2.1 CurveEditorScreen constructor

```dart
class CurveEditorScreen extends StatefulWidget {
  const CurveEditorScreen({
    super.key,
    required this.mod,               // LfoSnapshot for the curve modulator
    required this.onUpdate,           // bridge update callback (existing)
    required this.bridge,             // EngineBridge for optional preview transport
    this.playing = false,
    this.playheadBeat = 0.0,
    this.bpm = 120,
  });
}
```

**Fields:**

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `mod` | `LfoSnapshot` | required | The curve modulator snapshot. Must have `type == 'curve'`. |
| `onUpdate` | `Future<void> Function(String param, double value)` | required | Existing bridge callback — same signature as `CurvePropertiesPanel.onUpdate`. |
| `bridge` | `EngineBridge` | required | For optional preview transport connection. |
| `playing` | `bool` | `false` | Whether transport is currently playing (for live preview). |
| `playheadBeat` | `double` | `0.0` | Current playhead position in beats. |
| `bpm` | `int` | `120` | Project BPM. |

### 2.2 CurveEditorScreen state

```dart
class _CurveEditorScreenState extends State<CurveEditorScreen> {
  late List<double> _positions;       // local mutable copy of mod.curveBpPositions
  late List<double> _values;          // local mutable copy of mod.curveBpValues
  late List<int> _shapes;            // local mutable copy of mod.curveBpShapes
  late int _bpCount;                 // local mutable copy of bp count
  int? _draggingIndex;               // index of breakpoint being dragged, null if none
  int? _selectedSegment;             // index of tapped segment for shape toggle
}
```

**State sync:** On `initState` and `didUpdateWidget`, copy arrays from `widget.mod`. All mutations happen locally first, then flush to bridge via `_syncToBridge()`.

### 2.3 Bridge param keys (already existing — no new bridge methods)

| Param string | Value range | Flutter mapping |
|-------------|-------------|-----------------|
| `'bp_{i}_pos'` | `double` [0, 1] | `onUpdate('bp_0_pos', 0.25)` |
| `'bp_{i}_val'` | `double` [-1, 1] (bipolar) or [0, 1] (unipolar) | `onUpdate('bp_0_val', 0.5)` |
| `'bp_{i}_shape'` | `int` [0, 2] | `onUpdate('bp_0_shape', 1.0)` |
| `'breakpointCount'` | `int` [2, 32] | `onUpdate('breakpointCount', 5.0)` |
| `'polarity'` | `int` [0, 1] | `onUpdate('polarity', 0.0)` |

All callbacks use the existing `onUpdate` lambda which calls `applyParamUpdate` locally and `_onBridgeCall('updateLfoParam', ...)` on the engine.

### 2.4 Coordinate mapping (editor canvas)

| Canvas space | Data space | Formula |
|-------------|-----------|---------|
| X pixel | `position` [0, 1] | `x = position * canvasWidth` |
| Y pixel (bipolar) | `value` [-1, 1] | `y = canvasHeight * (0.5 - value * 0.5)` |
| Y pixel (unipolar) | `value` [0, 1] | `y = canvasHeight * (1.0 - value)` |
| Drag dx → position | Δx / canvasWidth | Clamped to [0, 1] |
| Drag dy → value (bipolar) | -2.0 * Δy / canvasHeight | Clamped to [-1, 1] |
| Drag dy → value (unipolar) | -Δy / canvasHeight | Clamped to [0, 1] |

### 2.5 Hit testing

| Interaction | Target | Hit radius | Result |
|------------|--------|-----------|--------|
| Tap on empty canvas | No breakpoint within 20px | 20px from any dot | Insert breakpoint at nearest curve point on tapped X |
| Tap on breakpoint dot | dot within 20px of tap | 20px | Select dot (highlight, prepare for drag or delete) |
| Tap on segment | tap within segment's X range but not near a dot | 20px from dots | Cycle shape (0→1→2→0) for that segment (update `_shapes[i]`) |
| Drag on breakpoint dot | dot within 20px of pan start | 20px | Update position (X) and value (Y) |
| Long-press on breakpoint dot | dot within 20px of long-press | 20px | Mark for deletion (show delete confirmation or remove immediately) |
| Back button | AppBar leading | — | Pop navigator, no explicit save needed (changes already synced) |

### 2.6 Steps stepper behavior

| Action | Current bpCount | New bpCount | Behavior |
|--------|----------------|-------------|----------|
| Tap `+` | < 32 | +1 | Insert new breakpoint at midpoint of last segment; position clamped to not exceed 1.0 |
| Tap `-` | > 2 | -1 | Remove last breakpoint (index bpCount-1) |
| Limits | 2 ≤ bpCount ≤ 32 | — | Buttons disabled at boundaries |

When changing `breakpointCount` via stepper, the engine param `'breakpointCount'` is updated, and the local arrays are trimmed or extended accordingly. `applyParamUpdate` already handles extension of `curveBpPositions` for the `breakpointCount` case (line 556-558 in project_snapshot.dart).

### 2.7 Optimistic update sequence

```
User action → local state mutation (setState → arrays) → _syncToBridge()

_syncToBridge() {
  // For each changed element, call onUpdate(param, value)
  // onUpdate calls applyParamUpdate locally + bridge call
  // Bridge call: updateLfoParam(lfoId, param, value)
}
```

Since each param update goes through `updateLfoParam` individually, batch multiple updates (e.g., position + value during drag) by debouncing or flushing only on drag end. To avoid flooding the bridge:

- **Drag:** Only call `_syncToBridge()` on `onPanEnd`, not on every `onPanUpdate`. The local visual updates during drag are handled by `setState` alone.
- **Add/delete/cycle:** Call `_syncToBridge()` immediately after the setState.
- **Steps stepper:** Call `_syncToBridge()` immediately.

## 3. File Ownership

| File/path | Owner WP | Allowed changes | Forbidden changes |
|-----------|---------|----------------|-------------------|
| `app_flutter/lib/features/device_strip/curve_editor_screen.dart` | WP2–WP5 | Create new file — full `CurveEditorScreen` widget + `_CurveEditorPainter` | Do not modify other files |
| `app_flutter/lib/features/device_strip/curve_properties_panel.dart` | WP6 | Wire `onOpenEditor` callback, no structural changes | Do not change painter, layout, or API surface |
| `app_flutter/lib/features/device_strip/device_strip_slot.dart` | WP6 | Implement `onOpenEditor` callback in `_buildModulatorPropertiesPanel` (replace TODO) | Do not change any other behavior |
| `app_flutter/lib/bridge/project_snapshot.dart` | (none) | No changes needed | No changes — existing `applyParamUpdate` already handles all curve params |
| `app_flutter/lib/features/device_strip/modulation_grid.dart` | (none) | No changes needed | No changes |

## 4. Vertical Work Packages

### WP1: CurveEditorPainter

**Behavior:** Draw the fullscreen curve canvas (reuses rendering logic from `_CurvePreviewPainter` but at full canvas size with richer visuals).

**Files:** `curve_editor_screen.dart` (internal `_CurveEditorPainter` class)

**Canonical names used:** `positions`, `values`, `shapes`, `bpCount`, `polarity`, `accent`

**API/Data contracts used:** Coordinate mapping from §2.4, hit testing from §2.5

**Dependencies:** None

**Acceptance criteria:**
- `_CurveEditorPainter` draws horizontal grid lines (5 rows), center line for bipolar
- Draws curve path connecting breakpoints in order
- Draws fill between curve and zero line (same polarity-aware fill as `_CurvePreviewPainter`)
- Draws breakpoint dots at each (position, value) coordinate
- Renders each segment using the correct shape (linear=straight line, smooth=cubic, step=horizontal hold)
- Highlights dragged/selected dot differently (larger radius, brighter color)
- `shouldRepaint` checks positions, values, shapes, polarity, bpCount, and dragging/highlight state

**Required tests:** Widget test verifying painter output for 2-bp linear, 3-bp mixed shapes, bipolar vs unipolar, step shape

**Manual verification:** Run on device, open curve editor, visually confirm curve matches properties panel preview

**Parallelization:** Parallel-safe (pure painter, no state management)

### WP2: CurveEditorScreen shell

**Behavior:** Scaffold with dark background, AppBar with title and back button, header with curve label and steps stepper, canvas area, and optional playhead indicator.

**Files:** `curve_editor_screen.dart`

**Canonical names used:** `CurveEditorScreen`, `_CurveEditorPainter`, `bpCount`, `accent`

**API/Data contracts used:** §2.1 constructor, §2.6 steps stepper

**Dependencies:** WP1 (painter exists)

**Acceptance criteria:**
- Fullscreen Scaffold with `resizeToAvoidBottomInset: false`
- AppBar with left arrow back button, title showing `'CURVE {mod.id}'`
- Header row: curve label + polarity badge + steps stepper (`-` / count / `+`)
- Steps stepper buttons disabled at min(2)/max(32)
- Canvas area fills remaining space
- Engages `_CurveEditorPainter` on a `CustomPaint` widget
- `MediaQuery.removePadding` removes bottom safe area
- Back button calls `Navigator.of(context).pop()`

**Required tests:** Smoke test rendering with 3-bp curve, verify back button pops

**Manual verification:** Open curve editor, see fullscreen layout, tap back to return

**Parallelization:** Depends on WP1 (painter must exist for the CustomPaint call)

### WP3: Drag breakpoints

**Behavior:** User touches and drags a breakpoint dot to change its position (X) and/or value (Y).

**Files:** `curve_editor_screen.dart` (state + gesture handling)

**Canonical names used:** `_positions`, `_values`, `_draggingIndex`, `_syncToBridge`

**API/Data contracts used:** §2.4 coordinate mapping, §2.5 hit testing (pan), §2.7 optimistic update

**Dependencies:** WP2 (shell exists, canvas renders)

**Acceptance criteria:**
- `GestureDetector.onPanStart` on canvas: hit-test breakpoints, set `_draggingIndex` if within 20px
- `onPanUpdate`: convert delta to change in position (clamped [0,1]) and value (clamped per polarity)
- First and last breakpoints: only value can change, position is locked at 0.0 and 1.0 respectively
- Other breakpoints: min position must stay > previous bp position + small epsilon; max < next bp position - epsilon
- `onPanEnd` call `_syncToBridge()` to flush position and value changes
- Visual cursor changes to indicate draggable state
- Smooth visual updates during drag via `setState`

**Required tests:** Drag breakpoint, verify position/value clamped correctly, verify first/last bp position locked, verify bridge call on drag end

**Manual verification:** Place two fingers on a breakpoint, drag to new position, verify curve updates live, verify engine state persists after back

**Parallelization:** Depends on WP2

### WP4: Add/delete breakpoints

**Behavior:** Tap empty canvas area to add a breakpoint. Long-press a breakpoint to delete it.

**Files:** `curve_editor_screen.dart`

**Canonical names used:** `_positions`, `_values`, `_shapes`, `_bpCount`, `_syncToBridge`

**API/Data contracts used:** §2.5 hit testing (tap, long-press), §2.7 optimistic update

**Dependencies:** WP2 (shell exists)

**Acceptance criteria:**
- **Add:** `GestureDetector.onTapUp` on canvas, hit-test miss: insert new breakpoint at tapped (x, y), clamped to valid ranges. New breakpoint gets `shape=0` (linear). If tapped X falls within an existing segment, insert between the two segment endpoints and sort by position.
- **Delete:** `GestureDetector.onLongPressStart` on canvas, hit-test hit: remove breakpoint at that index. If `bpCount <= 2`, do nothing (enforce minimum).
- After add/delete, call `_syncToBridge()` immediately.
- Visual feedback: brief highlight on new breakpoint, fade-out animation on deleted.

**Required tests:** Tap empty canvas → bpCount increases, dot visible. Long-press dot → dot removed. Long-press only remaining 2 dots → no removal.

**Manual verification:** Add 3 breakpoints, delete 2, verify curve snaps back to 2 bp. Verify bridge receives correct param updates.

**Parallelization:** Depends on WP2, can be done in parallel with WP3 and WP5

### WP5: Segment shape toggle

**Behavior:** Tap on a segment (space between two breakpoints) to cycle the shape of that segment: linear → smooth → step → linear.

**Files:** `curve_editor_screen.dart`

**Canonical names used:** `_shapes`, `_selectedSegment`, `_syncToBridge`

**API/Data contracts used:** §2.5 hit testing (segment tap), §2.2 shape values

**Dependencies:** WP2 (shell exists)

**Acceptance criteria:**
- `GestureDetector.onTapUp` on canvas: if tap is not near any breakpoint dot, determine which segment it falls in (by X position between two adjacent bps)
- Cycle the left breakpoint's `shape` value: 0→1→2→0
- Visual feedback: brief highlight on the tapped segment
- Call `_syncToBridge()` immediately
- Segment tappable area: the full vertical extent of the canvas between bp[i].x and bp[i+1].x

**Required tests:** Tap segment, verify shape cycles 0→1→2→0. Verify curve rendering changes accordingly. Verify bridge call.

**Manual verification:** Tap each segment, observe curve rendering change (linear→cubic→step→linear). Verify engine reflects changes.

**Parallelization:** Depends on WP2, can be done in parallel with WP3 and WP4

### WP6: Wiring CurvePropertiesPanel → CurveEditorScreen

**Behavior:** Connect the `onOpenEditor` callback in `CurvePropertiesPanel` to push `CurveEditorScreen` via `Navigator.push`. Also connect the sequencer's existing pattern — the `onOpenEditor` is called from the tile tap in the modulation grid.

**Files:** `curve_properties_panel.dart`, `device_strip_slot.dart`

**Canonical names used:** `CurveEditorScreen`, `onOpenEditor`, `onUpdate`

**API/Data contracts used:** §2.1 CurveEditorScreen constructor

**Dependencies:** WP2 (screen exists)

**Acceptance criteria:**
- In `device_strip_slot.dart` `_buildModulatorPropertiesPanel`, replace `// TODO: open curve editor` with `Navigator.push` to `CurveEditorScreen`
- Pass `snapshot` as `mod`, `onUpdate` directly, `bridge` from `_onBridgeCall`, and transport state
- In `curve_properties_panel.dart`, ensure the `GestureDetector` `onTap` calls `onOpenEditor` (already implemented on line 46)
- No other changes to these files

**Required tests:** Tap curve preview in properties panel → curve editor opens. Verify passing correct mod id.

**Manual verification:** Open device strip, select curve modulator, tap curve preview → fullscreen editor opens. Verify back button returns to device strip with unchanged layout.

**Parallelization:** Depends on WP2 (screen class must exist)

## 5. Integration Plan

```
         WP1 (Painter)
             |
         WP2 (Shell)
          /  |   \
        WP3  WP4  WP5   (parallel)
          \  |   /
            |
         WP6 (Wiring)
```

### Parallelization matrix

| WP1 | WP2 | WP3 | WP4 | WP5 | WP6 |
|-----|-----|-----|-----|-----|-----|
| WP1 | — | After | After | After | After | After |
| WP2 | After | — | After | After | After | After |
| WP3 | After | After | — | Same file (sequential recommended) | Same file (sequential recommended) | After |
| WP4 | After | After | Same file | — | Same file (sequential recommended) | After |
| WP5 | After | After | Same file | Same file | — | After |
| WP6 | After | After | After | After | After | — |

### Recommended implementation order

1. **WP1** (painter) — pure rendering, no state
2. **WP2** (shell) — scaffold, layout, steps stepper
3. **WP3, WP4, WP5** — implement sequentially within the same file (they share `_CurveEditorScreenState`). Recommended order: WP3 → WP4 → WP5, but they can be done in any order as long as file conflicts are managed.
4. **WP6** — final wiring

### Contract gaps / risks

1. **Drag jank:** Continuous `_syncToBridge()` during drag will flood the engine bridge. The contract calls for bridge sync only on drag end. Verify this is acceptable for the preview (the engine doesn't need to repaint during drag — the local painter handles that).
2. **`applyParamUpdate` for `breakpointCount`** currently extends `curveBpPositions` but does NOT trim (`copyWith` on line 556-558 only handles if `i < curveBpPositions.length`, else adds default). When reducing count, the values for removed indices persist in the engine's `breakpoints` array but are hidden. This is acceptable because `breakpointCount` controls visibility.
3. **Segment shape:** The shape is stored on the *left* breakpoint of each segment (engine convention in `evaluateCurve` uses `bp[lo].shape`). This is consistent with the engine design. The UI should make this clear: tapping between bp[i] and bp[i+1] modifies `bp[i].shape`.
4. **First/last bp position lock:** WP3 explicitly locks X position for first and last breakpoints at 0.0 and 1.0. The engine does not enforce this, but the UI should to maintain a valid curve that spans [0, 1].
5. **No undo:** The editor does not implement undo/redo (unlike `AutomationEditorScreen` which has `_undoStack`/`_redoStack`). If undo is desired, it should be a follow-up feature. For now, optimistic bridge updates make changes persistent immediately.