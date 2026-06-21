# Library UI Refinements — Feature Brief

## Goals

Deliver four refinements on the existing content library UI to close the gap between item browsing and immediate audio feedback:

1. **Click-on-item plays preview** — Every tap on a library item produces immediate audio feedback (audio play, MIDI live play, automation playback, or preset preview load), removing the current no-op behavior on re-selection.
2. **MIDI preview → live polyphonic play** — MIDI items play notes live on the selected track via a polyphonic fallback oscillator, looped until the user navigates away.
3. **Preset preview bar** — A mini arrangement strip at the bottom of the library panel showing the current track's clips with scrubbing and 8-bar loop for real-time preset auditioning.
4. **Preview data caching** — LRU cache for `ClipPreviewData` to eliminate spinner flash on rebuilds, capped at 50 entries with session lifetime.

## Scope

### In scope

- Modifying `_onItemTap` in `LibraryContentPane` to trigger preview per item type
- Extending `SimpleOscillator` (or `LivePerformanceMixer`) to support polyphonic (8+ voice) MIDI preview in the engine
- New bridge methods: `previewMidi`, `stopPreview`, `previewPreset`, `stopPresetPreview`
- New widget: `PresetPreviewBar` in library panel
- In-memory LRU cache for clip preview data (Flutter-only)
- Updates to `daw_shell.dart` to wire new callbacks

### Out of scope

- Implementing `fetchClipPreview` on the native bridge side (separate feature)
- Full arrangement view reuse (`PresetPreviewBar` is a simplified widget, not a full arrangement)
- Audio preview for presets (presets are heard via the arrangement loop, not standalone)
- Automation curve playback engine (the engine previews it via existing infrastructure)
- Persisting preview state across library open/close
- Integration tests (unit tests only)

## Success criteria

- **C1:** Tap on an audio clip, MIDI clip, automation clip, or preset item produces immediate audio feedback
- **C2:** MIDI notes play polyphonically (8+ voices) on the selected track instrument or fallback oscillator
- **C3:** MIDI preview loops continuously until user selects a different item or closes the library
- **C4:** Automation tap triggers playback of the automation curve on the selected track
- **C5:** Preset tap opens a mini arrangement bar at the bottom with scrubbing and 8-bar loop
- **C6:** Preview widget never flashes loading spinner on rebuild when data is cached
- **C7:** Cached data evicts oldest entries when limit (50) is reached
- **C8:** Same-item re-tap restarts the preview (no-op removed)

## Non-goals (explicit)

- No native bridge implementation of `fetchClipPreview`
- No full arrangement view reuse
- No preset audio-only preview (presets preview via arrangement loop)
- No state persistence across library close/reopen