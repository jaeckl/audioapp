# Library UI Refinements — Architecture

## Architecture decisions

### AD-1: Click-to-preview is a callback dispatch in `_onItemTap`
The existing `_onItemTap` in `LibraryContentPane` currently sets `_selectedItemId` and calls `onItemSelected`. The refinement adds item-type-specific preview dispatch. No new architectural layer — just extending the existing callback flow.

- Audio items → call `onPreviewAudio` (already exists)
- MIDI items → call `onMidiPreviewTap` (new callback, replaces `onMidiClipTap` play action)
- Automation items → call `onAutomationPreviewTap` (new callback, triggers engine playback)
- Preset items → call `onPresetTap` → shows `PresetPreviewBar` (preset preview mode)
- `onInsert` button in header remains as explicit Insert action

### AD-2: MIDI preview uses `LivePerformanceMixer` with polyphonic fallback
The existing `LivePerformanceMixer` already supports `kLiveMaxVoices = 16` voice slots with polyphonic rendering for all instrument types. The fallback oscillator needs no separate polyphonic implementation — we add an `Oscillator` instrument kind to `LivePerformanceMixer` and wire MIDI note-on/note-off from the library preview. This avoids duplicating voice management.

- Engine-side: New `previewMidi` bridge method copies `MidiClipSnapshot` notes into a preview buffer, starts looping playback through the selected track's device chain (or fallback oscillator)
- The existing `noteOn`/`noteOff` bridge methods can be reused, or a dedicated `previewMidi` method starts a scheduled sequence
- Decision: Use `previewMidi(MidiClipSnapshot)` + `stopPreview()` as dedicated methods, keeping them separate from `noteOn`/`noteOff` (which are for live MIDI input)

### AD-3: Preset preview is a temporary device clone with arrangement loop
When a preset is selected:
1. Engine creates a snapshot of the current device state (save restore point)
2. Applies preset params to a **temporary clone** device slot (not the main chain)
3. Plays the arrangement loop (8-bar, default) through the clone
4. `stopPreview` reverts the clone state

The `PresetPreviewBar` widget at the bottom of the library panel:
- Reads clip positions from `ProjectSnapshot` (already available)
- Shows clips as mini blocks on a timeline
- Has a scrub handle (drag to set playhead position)
- Loop toggle (default on, 8 bars)
- No play/pause — preview is always playing while preset is selected

### AD-4: LRU cache is a Flutter-only utility class
`ClipPreviewCache` is a simple generic LRU cache using `LinkedHashMap` (Dart's insertion-ordered map, which also supports reordering on access via `_entries` manipulation or a dedicated library). It sits in `LibraryContentPane` and wraps the `fetchClipPreview` call.

- Cache key: `itemId` (String)
- Max entries: 50
- Eviction policy: LRU (remove least recently accessed when full)
- TTL: Session lifetime (no expiry, cleared on widget dispose or library close)
- Stale-while-revalidate: Show cached data immediately, re-fetch in background, update on response

### AD-5: Preview state lives in `LibraryFlyInPanelState`
Preview state (which item is currently being previewed, whether preview is active, preset preview mode) lives in the panel's state, not in `LibraryContentPane`. This allows the `PresetPreviewBar` to exist at the panel level (below the content pane) and allows stopping preview when the panel is closed.

- `_previewingItemId` — currently previewing item (null = none)
- `_previewState` — enum: { none, audio, midi, automation, preset }
- `_presetPreviewEnabled` — bool, loop on/off (default true)

### AD-6: Same-item re-tap restarts preview
The current code has `if (_selectedItemId == item.id) return;` which is a no-op. This is changed to:
- If same item and currently previewing → restart the preview (stop + start)
- If same item and NOT previewing (shouldn't happen, but defensive) → start preview
- If different item → stop current preview, start new one

## Module boundaries

```
┌─────────────────────────────────────────────┐
│               DAWShell                       │
│  Orchestrates callbacks, owns bridge,        │
│  manages preview lifecycle                   │
├─────────────────────────────────────────────┤
│          LibraryFlyInPanel                   │
│  Owns: panel state, preview state,           │
│  PresetPreviewBar dispatching                │
├────────────────┬────────────────────────────┤
│ LibraryContentPane │ PresetPreviewBar        │
│ - items list       │ - mini arrangement      │
│ - tap→preview      │ - scrub handle           │
│ - ClipPreviewCache │ - loop toggle            │
│ - LeadingVisual    │                          │
├────────────────┴────────────────────────────┤
│             EngineBridge                      │
│  previewMidi / stopPreview                   │
│  previewPreset / stopPresetPreview           │
│  fetchClipPreview (existing)                 │
├─────────────────────────────────────────────┤
│            Engine (C++)                       │
│  LivePerformanceMixer (polyphonic)            │
│  PreviewVoice (audio)                         │
│  Temporary preset device slot                 │
└─────────────────────────────────────────────┘
```

## Threading/async boundaries

- All preview methods are async (bridge calls) — called from control thread
- Engine audio processing is on the audio thread (unchanged)
- Cache reads/writes are synchronous, in-memory — no threading concerns
- `PresetPreviewBar` reads from `ProjectSnapshot` — already available, no additional async

## Error model

- Bridge errors: `PlatformException` caught in `DAWShell` handler, snackbar shown
- Cache miss: fall through to bridge fetch (current behavior), show shimmer
- Engine failure (e.g., no selected track, no instrument): return gracefully, show snackbar
- MIDI preview on track without instrument: fallback oscillator activated automatically
- Preset preview on track without matching device type: show snackbar "No matching device"

## Persistence model

- No new persistence. Preview state is ephemeral (session-only).
- Cache is in-memory, cleared on library close.
- Preset preview temporary device slot is engine-side, reverted on stop.