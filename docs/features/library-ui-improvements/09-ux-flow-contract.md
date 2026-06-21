# UX Flow Contract – Library UI Improvements

## UX Summary
- **User Goal**: Browse the audio library, preview items quickly, and insert a selected item into the project using a single global action.
- **Main Flow**: User filters presets → scrolls list → selects an item → (optional) taps Play preview button → clicks **Insert** in the page header to add the selected item.
- **Secondary Flows**: 
  - User changes filter list, which clears selection if the current item is hidden.
  - User taps a preview widget to enlarge a waveform (mobile only).
- **Non‑Goals**: Changing engine data formats, adding new library item types, persisting selection.

## Screen Map
| Screen/Area | Purpose | Entry point | Exit / Next action |
|-------------|---------|-------------|--------------------|
| Library Page (root) | Shows full library content pane with left‑rail filter list and header controls. | Navigation drawer or app home. | User selects an item or changes filter.
| Left‑Rail Presets Filter List (`DevicePresetFilterList`) | Quick filter of device preset items. | Visible on page load. | Updates library view, may clear selection.
| Library Content Pane (`LibraryContentPane`) | Grid/list of compact preview widgets (`LibraryPreviewWidget`). | After filter applied or page load. | Item selection, preview playback.
| Page Header (`LibraryHeader`) | Holds global **Insert** button and page title. | Always visible. | Triggers `globalInsertAction`.

## User Flows
### 1. Select‑Preview‑Insert Flow
- **Trigger**: User taps a library item tile.
- **Steps**:
  1. Tile becomes highlighted; `selectedItemId` stored in `LibraryContentPaneState`.
  2. Preview widget shows compact waveform (audio) or clip preview (MIDI/automation).
  3. User may tap the **Play** button (`previewPlayButton`) on the tile.
  4. Bridge `fetchClipPreview(itemId)` returns `ClipPreviewData`; UI shows loading placeholder, then waveform preview.
  5. Play button invokes `onPreviewAudio(itemId)` – audio plays without inserting.
  6. User taps **Insert** button in the header.
  7. Header reads `selectedItemId` and calls `onInsertAudio(selectedItemId)`.
- **Expected Feedback**: Highlighted selection, loading spinner while fetching preview, toast on preview error, enabled/disabled state of Insert button.
- **Success State**: Item is inserted into the project; toast "Inserted" appears.
- **Error State**: Preview fetch fails → toast “Preview unavailable”; Insert button disabled.

### 2. Filter‑Change Flow
- **Trigger**: User selects a device type in `DevicePresetFilterList`.
- **Steps**:
  1. Filter list emits filter change event.
  2. `LibraryContentPane` recomputes visible items.
  3. If `selectedItemId` is no longer visible, it is cleared and Insert button disables.
- **Feedback**: Filter list highlights chosen device; library grid animates to new layout.

### 3. Mobile‑Only Waveform Expand Flow
- **Trigger**: User taps the waveform preview area on a compact widget.
- **Steps**:
  1. Modal sheet slides up showing enlarged `ClipPreviewData`.
  2. User can scrub or tap Play inside modal.
  3. Dismiss modal returns to library view.
- **Feedback**: Smooth transition, focus trap inside modal.

## Layout Contract
### Library Page
- **Header** (top): Title left, **Insert** button right (primary action). Height 56dp, background from `library_theme.dart`.
- **Left‑Rail** (desktop / tablet): Fixed width 200dp, vertical list of device presets (`DevicePresetFilterList`). Collapsible on narrow screens.
- **Content Area**: Grid of `LibraryPreviewWidget` tiles, 2‑column on phone, 3‑4 on tablet, 5+ on desktop. Uniform padding 8dp.
- **Tile** (`_LibraryItemTile`):
  - Leading visual: compact waveform preview (audio) or `ClipPreviewData` waveform (MIDI/automation). Size 48×48dp.
  - Center: item name, duration.
  - Trailing: **Play** button (icon) – primary interaction for preview.
  - No per‑tile Insert button (removed).
- **Selection Highlight**: Colored border (`accentColor`) and subtle background overlay.

### Forbidden Layout Choices
- Full‑width list view (must stay grid).
- Per‑tile Insert button.
- Overly large preview widgets (must stay compact 48dp visual).

## Component Contract
| UI need | Component / pattern | Data required | Notes |
|---------|--------------------|---------------|-------|
| Compact preview visual | `LibraryPreviewWidget` (Flutter) | `ClipPreviewData` (waveform points) | Renders waveform or static placeholder.
| Play preview action | `previewPlayButton` (IconButton) | `itemId` | Calls `onPreviewAudio(itemId)` async.
| Global insertion | Header `Insert` button (`globalInsertAction`) | `selectedItemId` | Disabled when no selection.
| Device preset filter | `DevicePresetFilterList` (ListView) | List of device preset types (static enum) | Highlights active filter.
| Loading placeholder | `CircularProgressIndicator` inside widget | – | Shown while `fetchClipPreview` resolves.
| Error toast | `ScaffoldMessenger.showSnackBar` | error message string | Same pattern as existing UI.

## State Contract
### LibraryContentPane
- **empty**: No items (show “No library items” message).
- **loading**: Initial load spinner.
- **ready**: Grid displayed, selection possible.
- **selection**: `selectedItemId` set, tile highlighted, Insert button enabled.
- **previewLoading** (per tile): shows loading spinner inside tile.
- **previewError**: toast, placeholder image.
- **insertDisabled**: when no selection or item hidden.

### DevicePresetFilterList
- **idle**: No filter chosen (shows all).
- **active**: One filter highlighted.
- **filterApplying**: brief fade‑out/in animation.

## Responsive Behavior
- **Compact (mobile portrait)**: Left‑rail collapses into a hamburger drawer; header remains full‑width; grid = 2 columns.
- **Normal (tablet)**: Left‑rail visible, grid = 3‑4 columns.
- **Wide (desktop)**: Left‑rail fixed, grid = 5+ columns; hover effects for tile preview.
- **Overflow**: Horizontal scrolling disabled; vertical scroll works for content area.

## Accessibility Expectations
- All interactive elements have meaningful `semanticLabel` (e.g., "Play preview of {itemName}", "Insert selected item").
- Keyboard navigation: Tab moves focus to filter list, then to grid tiles, then to header Insert button.
- Focus order respects visual order.
- Touch target size ≥48dp for Play button and tile tap.
- Contrast ratio ≥4.5:1 for text against background (uses existing theme colors).
- Screen reader announces selection change and button states.

## UX Risks & Mitigations
| Risk | Description | Mitigation |
|------|-------------|------------|
| Confusion between preview and insert | Users may think Play button inserts. | Clear icon (play triangle) and tooltip; Insert button only in header.
| Lost selection after filter change | Selection clears silently. | Show toast "Selection cleared due to filter".
| Overcrowded grid on small screens | Tiles may become too small. | Minimum tile size 80dp; collapse to single column on very narrow widths.
| Missing preview data | Bridge may fail to fetch waveform. | Show placeholder waveform, toast error, keep Insert button disabled.
| Inconsistent naming | Use canonical vocabulary (`LibraryPreviewWidget`, `globalInsertAction`). | Enforce names in component contract.

## Implementation Notes
- **Binding decisions**: Header placement of `globalInsertAction`, removal of per‑tile Insert, addition of `DevicePresetFilterList`, compact size of `LibraryPreviewWidget`, and Play button location are immutable for implementation agents.
- **Adjustable decisions**: Exact grid column count can be tuned per breakpoint; colors follow existing `library_theme.dart`.
- **Contract‑related changes**: If bridge cannot provide `ClipPreviewData` for a type, request addition of that method from the architect.
- **Testing hints**: Verify that Insert button enables only when a tile is highlighted; ensure preview loading indicator appears during async fetch.
- **Performance**: Keep preview fetch lightweight; cache waveform data per session.
