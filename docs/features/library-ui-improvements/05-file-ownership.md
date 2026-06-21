# File Ownership

| File/path | Owner work package | Allowed changes | Forbidden changes |
|-----------|--------------------|-----------------|-------------------|
| `app_flutter/lib/features/content_library/library_content_pane.dart` | WP‑1 (Shrink preview), WP‑2 (MIDI preview), WP‑3 (Automation preview), WP‑4 (Selection model) | Add `selectedItemId` state, compact tile layout, waveform rendering, per‑tile play button, selection highlight, remove per‑tile insert buttons | Change `LibraryItem` hierarchy or manifest loading logic |
| `app_flutter/lib/features/content_library/library_preview_widget.dart` *(new)* | WP‑1, WP‑2, WP‑3 | Define `LibraryPreviewWidget` composable that renders waveform or placeholder; accept `ClipPreviewData` | Import or depend on bridge‑specific types not in data contracts |
| `app_flutter/lib/features/content_library/library_header.dart` *(new)* | WP‑4 | Define `LibraryHeader` widget with global insert button; wire to `LibraryContentPane` selection state | Modify `LibraryFlyInPanel` layout or animation logic |
| `app_flutter/lib/features/content_library/device_preset_filter_list.dart` *(new)* | WP‑5 | Define `DevicePresetFilterList` widget; filter `LibraryPresetItem` by `deviceType` | Modify selection model or bridge callbacks |
| `app_flutter/lib/bridge/engine_bridge.dart` | WP‑6 (Bridge callback) | Add `fetchClipPreview` method returning `ClipPreviewData`; add MethodChannel method name | Remove or modify existing bridge methods (`play`, `stop`, `getProjectSnapshot`, etc.) |
| `native_bridge/effects_bridge.cpp` | WP‑6 | Add native implementation for `fetchClipPreview` MethodChannel handler | Modify unrelated native bridge code |
| `app_flutter/lib/features/content_library/library_fly_in_panel.dart` | WP‑INT (Integration) | Wire `LibraryHeader` (global insert) into the panel layout; pass new callbacks | Change animation, slide logic, or menu layout |
| `app_flutter/lib/features/content_library/library_catalog.dart` | *(none)* | — | **Read‑only** during this feature; `LibraryItem` types are contract stubs, not to be modified |
| `app_flutter/lib/features/content_library/library_category.dart` | *(none)* | — | **Read‑only**; `LibraryCategory` enum must not be extended |
| `app_flutter/lib/features/content_library/library_manifest.dart` | *(none)* | — | **Read‑only**; manifest loading is unchanged |
| `app_flutter/lib/features/content_library/library_theme.dart` | WP‑1 | Add any needed colour constants for new widgets | Remove existing theme values |
| `app_flutter/lib/bridge/project_snapshot.dart` | *(none)* | — | **Read‑only**; `SampleLibraryEntrySnapshot` is a pre‑existing contract |
| `app_flutter/test/library_ui_test.dart` *(new)* | WP‑7 | Widget tests for compact tile, waveform preview, selection, global insert, preset filter list | Test engine logic or modify non‑library code |
| `app_flutter/test/library_preset_filter_test.dart` | WP‑7 | Add tests for device preset filter behaviour | Modify existing test structure |
| `app_flutter/test/library_fly_in_panel_test.dart` | WP‑7 | Add tests for selection/insert flow | Modify existing panel tests |