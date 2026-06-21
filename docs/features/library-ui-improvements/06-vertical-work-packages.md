# Vertical Work Packages: Library UI Improvements

---

## Package WP‑1: Shrink preview widgets + play button

**User‑visibility**: All library item tiles have a compact 48 dp visual, a play‑preview icon per tile (audio samples play preview, other items show a visual icon), and no sizing/favouring of any item type.

**Assigned files**:
- `app_flutter/lib/features/content_library/library_content_pane.dart` — modify `_LibraryItemTile` layout, reduce `_LeadingVisual` height to 48 dp, add `previewPlayButton` to trailing actions
- `app_flutter/lib/features/content_library/library_preview_widget.dart` *(new)* — create composable `LibraryPreviewWidget` that accepts a `Widget` child and renders a compact 48 dp box with optional play overlay
- `app_flutter/lib/features/content_library/library_theme.dart` — add any new colour constants needed

**Canonical names used**: `LibraryPreviewWidget`, `previewPlayButton`, `_LeadingVisual`, `_LibraryItemTile`.

**API contracts used**: `LibraryContentPane.onPreviewAudio`, `SampleLibraryEntrySnapshot` (for waveform peaks in audio items only).

**Dependencies**: None (foundational).

**Acceptance criteria**:
1. Every tile has a uniform 48 dp leading visual area (was 52–96 dp).
2. Audio items show a play‑preview button (play icon) in the trailing area; pressing it calls `onPreviewAudio`.
3. All other item types show the play‑preview button as well (except automation items per feature brief — automation uses preview waveform instead).
4. Layout is consistent across all four `LibraryCategory` values.
5. No regressions in existing tile rendering for any item type.

**Parallel‑safe**: YES — other packages can start after this widget structure is established.

---

## Package WP‑2: MIDI clip preview (waveform instead of badge)

**User‑visibility**: MIDI items show a miniature waveform clip preview (rendered from `ClipPreviewData`) in the leading visual area, replacing the note‑count badge.

**Assigned files**:
- `app_flutter/lib/features/content_library/library_content_pane.dart` — modify `_LeadingVisual` for `LibraryMidiItem` to render waveform via `LibraryPreviewWidget` instead of `_BadgeBox`
- `app_flutter/lib/features/content_library/library_preview_widget.dart` — add `WaveformPainter` integration and loading/fallback states for async `ClipPreviewData`

**Canonical names used**: `ClipPreviewData`, `LibraryPreviewWidget`, `WaveformPainter`.

**API contracts used**: `ClipPreviewData.peaks`, `ClipPreviewData.length`.

**Dependencies**: WP‑1 (compact widget structure must exist). WP‑6 (bridge callback) must exist at the bridge level but UI should accept a `Future<ClipPreviewData>` fetcher — can be stubbed during development.

**Acceptance criteria**:
1. `_LeadingVisual` for `LibraryMidiItem` displays a waveform rendered from `ClipPreviewData.peaks` instead of a numeric badge.
2. Waveform uses the same `WaveformPainter` that audio items use for their sample waveform.
3. While `ClipPreviewData` is loading, a shimmer / loading placeholder is shown (48 dp height).
4. If preview data is empty (error), a fallback dashed placeholder is shown.
5. The existing `midiSizeBadge` is completely removed — no note count visible.

**Parallel‑safe**: YES after WP‑1 widget structure is in place. Can run in parallel with WP‑3 and WP‑5.

---

## Package WP‑3: Automation clip preview (waveform instead of generic icon)

**User‑visibility**: Automation items show a miniature waveform clip preview in the leading visual area, replacing the generic `Icons.show_chart` icon.

**Assigned files**:
- `app_flutter/lib/features/content_library/library_content_pane.dart` — modify `_LeadingVisual` for `LibraryAutomationItem` to render waveform via `LibraryPreviewWidget` instead of `_BadgeBox` with icon
- `app_flutter/lib/features/content_library/library_preview_widget.dart` — reuse shared `LibraryPreviewWidget` (same as WP‑2)

**Canonical names used**: `ClipPreviewData`, `LibraryPreviewWidget`, `WaveformPainter`.

**API contracts used**: `ClipPreviewData.peaks`, `ClipPreviewData.length`.

**Dependencies**: WP‑1 (compact widget structure). WP‑6 (bridge callback — `fetchClipPreview` must support automation clip IDs).

**Acceptance criteria**:
1. `_LeadingVisual` for `LibraryAutomationItem` displays a waveform rendered from `ClipPreviewData.peaks` instead of the `show_chart` icon.
2. Loading and fallback states behave identically to WP‑2.
3. The `automationIcon` (`Icons.show_chart` in `_BadgeBox`) is completely removed.

**Parallel‑safe**: YES after WP‑1. Can run in parallel with WP‑2 (same structure, different subtype match).

---

## Package WP‑4: Selection model + global insert button

**User‑visibility**: Tapping a library item **selects** it (highlighted border/fill). The per‑tile "Insert" and "Load" buttons are removed. A single "Insert" button in the panel header inserts the selected item. Selecting a hidden item (e.g. after filtering) clears the selection.

**Assigned files**:
- `app_flutter/lib/features/content_library/library_content_pane.dart` — add `selectedItemId` state (`String?`), selection highlight on `_LibraryItemTile`, remove per‑tile insert/load buttons, clear selection when filtered items change
- `app_flutter/lib/features/content_library/library_header.dart` *(new)* — create `LibraryHeader` widget with a "Insert" `FilledButton` that reads `selectedItemId` and invokes the appropriate insert callback
- `app_flutter/lib/features/content_library/library_fly_in_panel.dart` — incorporate `LibraryHeader` replacing the existing `_LibraryPanelHeader` (or augment it), wire callbacks

**Canonical names used**: `selectedItemId`, `globalInsertAction`, `LibraryHeader`.

**API contracts used**: `globalInsertAction(String selectedItemId)` — dispatches to `onInsertAudio`, `onMidiClipTap`, `onPresetTap` based on item type.

**Dependencies**: WP‑1 (need compact tile layout before removing insert buttons).

**Acceptance criteria**:
1. Tapping any library item highlights it with an accent‑coloured border/background; tapping a different item moves the highlight.
2. Tapping the already‑selected item does nothing (toggle is not needed per spec).
3. Per‑tile "Insert" and "Load" `FilledButton`s are removed (audio, MIDI, preset items).
4. "Insert" button appears in the `LibraryHeader`; it is disabled (greyed out) when `selectedItemId` is null.
5. Pressing "Insert" calls the correct insert callback for the selected item type.
6. Changing category or applying a filter that hides the selected item clears the selection.
7. The panel header now shows: "Library" title, global "Insert" button (enabled/disabled), close icon.

**Parallel‑safe**: YES after WP‑1. Must not conflict with WP‑2/WP‑3 file changes since they edit distinct switch‑case branches in `_LibraryItemTile`.

---

## Package WP‑5: Device preset filter list

**User‑visibility**: When the `devicePresets` category is active, the left rail shows a "Presets" sub‑list (below the category menu) with device‑type filter chips (Sampler, Synth, Kick, etc.). Selecting a chip filters the preset list to that device type. Selecting "All" or no chip shows all presets.

**Assigned files**:
- `app_flutter/lib/features/content_library/device_preset_filter_list.dart` *(new)* — define `DevicePresetFilterList` widget with single‑select chip list using `kDevicePresetFilters`
- `app_flutter/lib/features/content_library/library_content_pane.dart` — integrate `DevicePresetFilterList` in the `devicePresets` layout, replace `LibraryTagFilterBar` for presets with the new filter list, pipe selection state

**Canonical names used**: `DevicePresetFilterList`, `DevicePresetFilter`, `kDevicePresetFilters`.

**API contracts used**: `LibraryPresetItem.deviceType`, `selectedItemId` (clear on filter change).

**Dependencies**: None — independent UI widget.

**Acceptance criteria**:
1. When `category == LibraryCategory.devicePresets`, a vertical list of filter chips appears in the left rail below `LibraryCategoryMenu`.
2. Each chip displays the correct `label` and `icon` from `kDevicePresetFilters`.
3. Tapping a chip selects it (highlighted state); only one chip can be selected at a time.
4. The preset list below filters to only `LibraryPresetItem` entries matching `selectedDeviceType`.
5. Tapping the same chip again deselects it (returns to "All").
6. Selection (`selectedItemId`) is cleared if the selected preset is no longer visible after filtering.
7. The existing `LibraryTagFilterBar` for presets is replaced by this new filter list (tag‑based filtering of presets is removed).

**Parallel‑safe**: YES — fully independent widget; only modifies `library_content_pane.dart` in a `devicePresets`‑specific branch.

---

## Package WP‑6: Bridge preview callback (`fetchClipPreview`)

**User‑visibility**: A MethodChannel call `fetchClipPreview` that takes a library item ID and returns `ClipPreviewData{peaks, lengthMs}` for MIDI and automation clips. The Flutter side can await a `Future<ClipPreviewData>`.

**Assigned files**:
- `app_flutter/lib/bridge/engine_bridge.dart` — add:
  ```dart
  Future<ClipPreviewData> fetchClipPreview(String itemId) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('fetchClipPreview', {
      'itemId': itemId,
    });
    if (result == null) throw PlatformException(...);
    return ClipPreviewData(
      peaks: (result['peaks'] as List<dynamic>).map((p) => (p as num).toDouble()).toList(),
      length: Duration(milliseconds: (result['lengthMs'] as num).toInt()),
    );
  }
  ```
- `native_bridge/effects_bridge.cpp` *(or equivalent native bridge file)* — add `fetchClipPreview` handler that:
  - Parses `itemId` to determine clip type (MIDI / automation)
  - Locates clip data in the project state
  - Computes amplitude envelope peaks from the clip's note velocity (MIDI) or curve points (automation)
  - Returns JSON `{peaks: [...], lengthMs: N}`

**Canonical names used**: `fetchClipPreview`, `ClipPreviewData`.

**API contracts used**: `ClipPreviewData.peaks`, `ClipPreviewData.length`.

**Dependencies**: None — independent bridge work. Stub can be used by UI prior to native implementation.

**Acceptance criteria**:
1. `EngineBridge.fetchClipPreview(itemId)` is defined and callable from Dart.
2. Calling with a valid MIDI clip ID returns a `ClipPreviewData` with non‑empty peaks array.
3. Calling with a valid automation clip ID returns a `ClipPreviewData` with non‑empty peaks array.
4. Calling with an unknown ID returns `ClipPreviewData(peaks: [], length: Duration.zero)`.
5. The native side does not block the audio thread.
6. MethodChannel method name is `fetchClipPreview`.

**Parallel‑safe**: YES — fully independent bridge work. WP‑2 and WP‑3 can stub `fetchClipPreview` in tests while this is implemented.

---

## Package WP‑7: Widget tests

**User‑visibility**: CI validates all new library UI behaviour.

**Assigned files**:
- `app_flutter/test/library_ui_test.dart` *(new)* — comprehensive widget tests for:
  - WP‑1: compact tile rendering, play button present
  - WP‑2: MIDI waveform shows instead of badge
  - WP‑3: automation waveform shows instead of icon
  - WP‑4: selection highlight, global insert, selection cleared on filter change
  - WP‑5: device preset filter chips, filtering logic
- `app_flutter/test/library_preset_filter_test.dart` — extend with device preset filter chip tests
- `app_flutter/test/library_fly_in_panel_test.dart` — extend with selection/insert flow tests

**Canonical names used**: All canonical names from WP‑1 through WP‑6.

**API contracts used**: All data contracts from `04-data-contracts.md`.

**Dependencies**: WP‑1 through WP‑6 must have their contracts settled; tests may use stubs.

**Acceptance criteria**:
1. All tests pass: `cd app_flutter && flutter test`.
2. Compact tile tests verify 48 dp leading visual height.
3. MIDI preview tests verify waveform `CustomPaint` exists and badge does not.
4. Automation preview tests verify waveform replaces `show_chart` icon.
5. Selection tests: tap selects, tap different moves highlight, global insert calls correct callback.
6. Filter tests: device preset chip selection filters items correctly.
7. At least 70 % line coverage for new/modified library UI code.

**Parallel‑safe**: YES after all WP‑1 through WP‑6 data contracts are finalised.

---

## Package WP‑INT: Integration & manual verification

**User‑visibility**: Final end‑to‑end verification on a physical device (or emulator).

**Tasks**:
1. Build the Flutter APK: `cd app_flutter && flutter build apk --debug`.
2. Install on a connected Android device.
3. Run the demo script from the feature brief (`00-feature-brief.md` § Success Criteria):
   - Open library → all tile sizes are compact (48 dp)
   - MIDI items show waveform preview
   - Automation items show waveform preview
   - Play‑preview button works for non‑automation items
   - Tap item → it selects (highlighted); tap another → selection moves
   - Global "Insert" button inserts the selected item
   - Switch to presets → filter chips appear and filter correctly
   - Preset filter selection clears item selection when applicable
4. Verify no crashes, no visual regressions, correct bridge round‑trip for preview.
5. Fix any integration issues uncovered.

**Dependencies**: All work packages WP‑1 through WP‑7.

**Parallel‑safe**: NO — last step after everything else.