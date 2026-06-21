# Library UI Refinements — Canonical Vocabulary

| Concept | Canonical name | Type/file | Notes |
| ------- | -------------- | --------- | ----- |
| MIDI preview trigger | `onMidiPreviewTap` | `LibraryContentPane` callback | Replaces `onMidiClipTap` for preview-only (insert still uses separate button) |
| Automation preview trigger | `onAutomationPreviewTap` | `LibraryContentPane` callback | New callback for automation playback |
| Preview audio callback | `onPreviewAudio` | `LibraryContentPane` callback | Existing, unchanged |
| Preset tap callback | `onPresetTap` | `LibraryContentPane` callback | Existing, unchanged (now opens PresetPreviewBar) |
| Currently previewing item ID | `_previewingItemId` | `LibraryFlyInPanelState` | Tracks which item has active audio preview |
| Preview state enum | `_previewState` / `LibraryPreviewState` | `LibraryFlyInPanelState` | Values: `none`, `audio`, `midi`, `automation`, `preset` |
| PresetPreviewBar | `PresetPreviewBar` | New file `library_preset_preview_bar.dart` | Mini arrangement at bottom of panel |
| Preset preview enabled | `_presetPreviewLoopEnabled` | `PresetPreviewBar` state | Default true, 8-bar loop |
| Scrub notifier | `_scrubPlayheadBeats` | `PresetPreviewBar` state | Drag-adjusted playhead position |
| Cache class | `ClipPreviewCache` | New shared utility file | Generic LRU cache, max 50 entries |
| Cache key | `itemId` | String | Matches `LibraryItem.id` |
| Cache max entries | `kMaxCacheEntries` | `ClipPreviewCache` constant | 50 |
| Bridge: preview MIDI | `previewMidi` | `EngineBridge` method | Takes `MidiClipSnapshot`, loops playback |
| Bridge: stop preview | `stopPreview` | `EngineBridge` method | Stops any active preview |
| Bridge: preview preset | `previewPreset` | `EngineBridge` method | Takes `String presetId`, applies to temp slot |
| Bridge: stop preset | `stopPresetPreview` | `EngineBridge` method | Reverts temporary device slot |
| Fallback oscillator | `FallbackPreviewOscillator` | Engine (C++) | Polyphonic oscillator (8+ voices) used when track has no instrument |
| Preview voice slot | `PreviewMidiVoice` | Engine internal | Runtime state for each MIDI preview voice |
| Preset preview temp slot | `PresetPreviewSlot` | Engine internal | Temporary device clone for preset auditioning |
| Same-item re-tap restart | — | `_onItemTap` behavior | Changes from no-op to restart-preview |