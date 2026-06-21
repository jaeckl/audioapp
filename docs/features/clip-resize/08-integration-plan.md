# Integration Plan: Clip Resize

## Recommended implementation order

```
         ┌─────────────┐
         │   WP-3      │  C++ engine tests (clip_length_test.cpp)
         │  (C++ tests)│  — validates all clip types handle setClipLength
         └──────┬──────┘
                │
         ┌──────┴──────┐
         │   WP-1      │  Flutter resize UI (handle + session + gesture)
         │  (Flutter)  │  — the bulk of the feature
         └──────┬──────┘
                │
         ┌──────┴──────┐
         │   WP-2      │  Flutter widget tests
         │  (Flutter   │  — tests resize handle, gesture, snap, clamp
         │   tests)    │
         └─────────────┘
```

## Packages that can run in parallel

| Group | Packages | Rationale |
|-------|----------|-----------|
| **Group A** | WP-3 (C++ tests) | No dependencies — engine already supports all clip-type `setClipLength`. Tests can be written immediately. |
| **Group B** | WP-1 (Flutter UI) after WP-3 | The Flutter UI is independent of engine changes. The contract defines bridge API, snap grid, min lengths — all of which exist. No engine code changes are needed. |
| **Group C** | WP-2 (Flutter tests) after WP-1 | Needs the widget tree from WP-1 to be compiled. |

## Shared files requiring care

1. **`arrangement_view.dart`** — Only WP-1 touches this file. All additions use `resize`/`_resize` prefix to avoid collision with existing drag code. No existing code is modified — only new code is added.
2. **`arrangement_clip_theme.dart`** — Only WP-1 touches this file. Two new color constants added.
3. **`clip_length_test.cpp`** — Only WP-3 touches this file. New tests added at the end.

## Parallel execution strategy

1. **Start parallel**: WP-3 (C++ tests) — pure engine tests, no Flutter dependency
2. **Start**: WP-1 (Flutter UI) — can start immediately, independent of WP-3
3. **After WP-1**: WP-2 (Flutter tests) — builds on completed widget tree
4. **Integration check**: Verify that the existing `setClipLength` bridge method is indeed routed through `ProjectEngine::setClipLength` which handles automation clips (confirmed during exploration — `ProjectEngine::setClipLength` falls through to `automationClipStore_.setLength` after checking `ClipRepository`)
5. **Manual verification** (one-time): Build Flutter app, run on device/emulator, visually verify resize handles appear on all clip types and gesture works correctly

## Contract gaps or risks

1. **No gap — engine already supports all clip types**: `ProjectEngine::setClipLength()` checks `ClipRepository` first (MIDI/sample), then falls through to `AutomationClipStore` (automation). The existing `EngineBridge.setClipLength` already routes through this. No new bridge method needed.
2. **Risk: Gesture conflict with clip drag**: The resize handle's `GestureDetector` occupies only the rightmost 32px of each clip block. The clip body's `GestureDetector` (for long-press-to-drag) must NOT capture taps on the right edge. Since they are separate children in the `Stack` with different hit regions, and the handle uses `HitTestBehavior.opaque`, the handle should take priority. However, if the existing clip body uses `HitTestBehavior.translucent` or its gesture area overlaps, the handle may not intercept. **Mitigation**: Ensure the handle's `GestureDetector` is stacked after the clip body's `GestureDetector` in the `Stack` children list (later children render on top and receive gesture priority).
3. **Risk: Performance during live resize**: On every pointer move during drag, `setState` is called to update clip width. For many clips visible, this triggers a full rebuild of the track lanes. **Mitigation**: Use `RepaintBoundary` around each clip block to limit repaint scope. Since the existing code already uses `Stack` with `Positioned`, only the resized clip's width changes.
4. **Contract gap: Automation clip minimum length in Flutter**: The existing Dart code defines `kMinClipLengthBeats = 0.25` in `timeline_clip.dart` but the C++ engine uses `0.01` for automation clips. The Flutter UI needs to distinguish clip type when clamping minimum length in the resize preview. **Decision**: Use `0.25` for MIDI/Sample clips, `0.01` for automation clips in the UI preview clamp. The engine clamp is the final authority.
5. **No undo yet**: The current engine `setClipLength` is not wrapped in an undoable action. Undo for clip resize is a future enhancement. The user is warned: Ctrl+Z will not undo a resize in v1.
6. **No bridge change needed**: The existing `setClipLength` bridge method already works for all three clip types via `ProjectEngine::setClipLength`. Verified by reading `ProjectEngine::setClipLength` which checks `clipRepo_.findMidiClip`, `clipRepo_.findSampleClip`, then falls through to `automationClipStore_.setLength`. The Kotlin bridge already dispatches `"setClipLength"` to `EngineHost::setClipLength`.
