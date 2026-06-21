# Architecture – Library UI Improvements

## User‑visible Goal
Provide a consistent, compact, and preview‑rich library UI where users can select items, preview them, and insert via a global command.

## Non‑Goals
- Changing the underlying audio engine or file formats.
- Adding new library item types beyond existing audio, MIDI, automation, and device preset items.

## Existing Code Reuse
- `LibraryContentPane`, `_LibraryItemTile`, `_LeadingVisual` in `app_flutter/lib/features/content_library/`.
- Bridge callbacks `onPreviewAudio`, `onInsertAudio` defined in `app_flutter/lib/bridge/engine_bridge.dart`.
- Theme utilities in `library_theme.dart`.

## Architecture Decisions
- Introduce a **selection model** (`selectedItemId`) stored in the `LibraryContentPane` state; UI updates highlight the selected tile.
- Add a **global insert button** in the page header (`LibraryHeader`) that reads the current selection and invokes `onInsertAudio` (or appropriate insert callback).
- Replace existing insert buttons on each tile (except automation) with a **play preview button** only; insertion is handled globally.
- For MIDI and automation items, replace left‑side badge/icon with a **clip waveform preview** generated from the bridge (expose waveform data via a new preview API).
- Add a **Presets filter list** in the left rail (`DevicePresetFilterList`) that lists device types and filters `LibraryPresetItem`s.
- All UI changes stay within the Flutter layer; bridge only gets a new method `fetchClipPreview(String itemId)` returning waveform data.

## Module Boundaries
- **UI Module** (`app_flutter/lib/features/content_library/`): owns all visual components, selection state, and global insert action.
- **Bridge Module** (`app_flutter/lib/bridge/`): provides `fetchClipPreview` and existing preview/insert callbacks.
- **Engine Module** (`engine_juce/`): unchanged; continues to supply audio data for preview via existing bridge.

## Threading / Async Model
- UI interactions are on the Flutter main thread.
- Bridge calls are async `Future` returning waveform data; UI shows a loading placeholder while awaiting.

## Ownership Boundaries
- UI developers own all Flutter files under `content_library/`.
- Bridge developers own the new `fetchClipPreview` implementation in `engine_bridge.dart`.

## Error Model
- Preview fetch failures surface as a toast and fallback to a default placeholder.
- Selection of an unavailable item disables the global insert button.

## Persistence Model
- No persistence needed; selection is transient.

## UI/State Synchronization
- `selectedItemId` stored in `LibraryContentPaneState`; changes trigger `setState`.
- Global insert button reads this state via a callback.
- When filters change, selection is cleared if the selected item becomes hidden.
