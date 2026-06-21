# Canonical Vocabulary – Library UI Improvements

| Concept | Canonical Name | Type / File | Notes |
|---------|----------------|-------------|-------|
| Preview widget | `LibraryPreviewWidget` | Flutter UI (`library_content_pane.dart`, `_LibraryItemTile`) | Compact visual representation of an audio/MIDI/automation clip.
| Clip preview | `ClipPreviewData` | Bridge (`engine_bridge.dart`) | Waveform peaks data used to render a miniature preview.
| Insert action | `globalInsertAction` | Flutter UI (header button) | Inserts the currently selected library item.
| Selection model | `selectedItemId` | Flutter UI (`library_content_pane.dart` state) | Holds the ID of the currently selected library item.
| Presets filter list | `DevicePresetFilterList` | New Flutter widget (`device_preset_filter_list.dart`) | Sub‑list under the left rail for quick device preset filtering.
| Play preview button | `previewPlayButton` | Flutter UI (`_LibraryItemTile`) | Button that triggers playback of the item without inserting.
| Size indicator (MIDI) | `midiSizeBadge` | Existing UI (badge) – to be replaced.
| Automation left icon | `automationIcon` | Existing UI – to be replaced with clip preview.
