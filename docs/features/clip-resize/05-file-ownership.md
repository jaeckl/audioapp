# File Ownership: Clip Resize

| File/path | Owner work package | Allowed changes | Forbidden changes |
|-----------|--------------------|-----------------|-------------------|
| `app_flutter/lib/features/arrangement/arrangement_view.dart` | WP-1 (Flutter resize handle + session) | Add `_ClipResizeSession` class; add `_ClipResizeHandle` widget; add `onResizeClipStart/Update/End/Cancel` to `ArrangementView`, `_TrackLane`, `_MidiClipBlock`, `_SampleClipBlock`, `_AutomationClipBlock`; add `_startClipResize`, `_updateClipResize`, `_endClipResize`, `_cancelClipResize` methods; add `_resizeSession` state field; modify existing clip block `Stack` to include resize handle; wire resize callbacks through `_TrackLane` to state | Remove or modify existing clip drag logic (`_clipDrag`, `ArrangementClipDragSession`, `_startClipDrag`, etc.); change `ArrangementGridPainter` or ruler interaction; remove existing callbacks on `ArrangementView` |
| `app_flutter/lib/features/arrangement/arrangement_clip_drag.dart` | *(none)* | — | **Read-only** during this feature |
| `app_flutter/lib/features/arrangement/arrangement_timeline_metrics.dart` | *(none)* | — | **Read-only** during this feature (existing helpers reused, not modified) |
| `app_flutter/lib/features/arrangement/arrangement_clip_theme.dart` | WP-1 | Add `resizeHandleColor` and `resizeHandleActiveColor` color constants | Remove/modify existing clip theme colors |
| `app_flutter/lib/features/arrangement/clip_renderer.dart` | WP-1 | Add optional resize handle rendering to `ArrangementClipChrome` (or keep handle as a separate widget outside chrome) | Change `ClipRenderer` interface or `_ClipContentPainter` |
| `app_flutter/lib/features/arrangement/midi_clip_renderer.dart` | *(none)* | — | **Read-only** |
| `app_flutter/lib/features/arrangement/sample_clip_renderer.dart` | *(none)* | — | **Read-only** |
| `app_flutter/lib/features/arrangement/automation_clip_renderer.dart` | *(none)* | — | **Read-only** |
| `app_flutter/lib/bridge/engine_bridge.dart` | *(none)* | — | **Read-only** (existing `setClipLength` method is used as-is) |
| `app_flutter/lib/bridge/timeline_clip.dart` | *(none)* | — | **Read-only** |
| `app_flutter/lib/bridge/clip_snapshots.dart` | *(none)* | — | **Read-only** |
| `native_bridge/` (entire directory) | *(none)* | — | **Read-only** (no changes needed) |
| `engine_juce/src/EngineHost_commands.cpp` | *(none)* | — | **Read-only** (existing `setClipLength` is used as-is) |
| `engine_juce/src/ProjectEngine.cpp` | *(none)* | — | **Read-only** (existing `setClipLength` already handles all clip types) |
| `engine_juce/src/model/ClipRepository.cpp` | *(none)* | — | **Read-only** |
| `engine_juce/src/model/AutomationClipStore.cpp` | *(none)* | — | **Read-only** |
| `app_flutter/test/arrangement_view_resize_test.dart` *(new)* | WP-2 (Flutter tests) | Widget tests for resize handle rendering, gesture, snap, min-length clamp, adjacent-clip clamp | Test engine-side logic or modify non-resize test files |
| `engine_juce/tests/clip_length_test.cpp` | WP-3 (C++ tests) | Add test for automation clip length set, confirm `setClipLength` route works for all three clip types | Modify existing test structure or remove existing assertions |

## Shared files requiring care

1. **`arrangement_view.dart`** — This is the primary file (~1980 lines). Only WP-1 touches it. Multiple additions are made (resize session, handle widget, callbacks, state) but all additions are prefixed with `resize`/`_resize` to avoid name collisions with existing drag code. No existing code is modified — only new code added.
2. **`arrangement_clip_theme.dart`** — Small addition of color constants. No existing code modified.
