# Library UI Refinements — Vertical Work Packages

## Package 1: Preview data cache (WP-CACHE)

### Behavior
Add in-memory LRU cache for `ClipPreviewData` to eliminate spinner flash on rebuild. No bridge changes.

### Vertically: Fully contained in Flutter
User-visible: When items are shown with preview wave, cached data shows immediately instead of spinner.

### Assigned files
| File | Access |
|---|---|
| `app_flutter/lib/features/content_library/library_preview_cache.dart` | C |
| `app_flutter/lib/features/content_library/library_content_pane.dart` | W |
| `app_flutter/lib/features/content_library/library_fly_in_panel.dart` | W |
| `app_flutter/test/library_cache_test.dart` | C |

### Allowed changes
- Create `library_preview_cache.dart` with `ClipPreviewCache` class
- Modify `_LeadingVisual` in `library_content_pane.dart` to use cache before calling `fetchClipPreview`
- Add cache lifecycle in `LibraryFlyInPanelState` (clear on close)

### Forbidden changes
- No changes to engine, bridge, or other library UI files
- No changes to `LibraryPreviewWidget` (cache wraps fetch, widget stays same)

### Canonical names used
- `ClipPreviewCache`
- `kMaxCacheEntries`

### Dependencies
None. Parallel-safe.

### Acceptance criteria
1. First build of a MIDI/automation item shows shimmer (cache miss → fetch → store)
2. Subsequent builds show cached data immediately (no shimmer flash)
3. Cache evicts oldest entry when 51st unique item is fetched
4. Cache cleared on library close → next open shows shimmer again
5. Cache size never exceeds 50 entries

### Required tests
- Unit tests in `library_cache_test.dart`:
  - Basic put/get
  - LRU eviction on overflow
  - `clear()` empties all entries
  - `remove()` removes single entry
  - `containsKey` returns correct values

### Manual verification steps
1. Open library, switch to MIDI category
2. Observe shimmer on first display of each item
3. Switch to Audio, switch back to MIDI
4. Observe cached items show waveform immediately (no shimmer)

### Integration risk
Low. Isolated to Flutter-only cache class. No bridge/engine changes needed.

### Parallelization
**Parallel-safe.** Can run alongside WP2, WP3 — but needs to merge with WP1 (same files).

---

## Package 2: Click-on-item plays preview (WP-CLICK)

### Behavior
Every tap on a library item produces immediate audio feedback. Removes no-op on same-item re-tap (replaces with restart). New callbacks `onMidiPreviewTap` and `onAutomationPreviewTap` dispatched from `_onItemTap`.

### Vertically: Tap → preview dispatch in DAWShell
User-visible: Tapping any library item produces immediate audio.

### Assigned files
| File | Access |
|---|---|
| `app_flutter/lib/features/content_library/library_content_pane.dart` | W |
| `app_flutter/lib/features/content_library/library_fly_in_panel.dart` | W |
| `app_flutter/lib/app/daw_shell.dart` | W |
| `app_flutter/test/library_click_test.dart` | C |

### Allowed changes
- Add `onMidiPreviewTap` and `onAutomationPreviewTap` callbacks to `LibraryContentPane`
- Modify `_onItemTap` to dispatch preview per item type (audio, MIDI, automation, preset)
- Remove `if (_selectedItemId == item.id) return;` → restart preview instead
- Wire new callbacks in `LibraryFlyInPanel`
- Wire new callbacks in `DAWShell`
- `DAWShell` handlers call bridge methods (see WP2/WP3 for bridge method details)

### Forbidden changes
- No engine changes
- No changes to `library_catalog.dart`, `library_category.dart`, or other read-only library files
- Do not change the Insert button behavior in `library_header.dart`

### Canonical names used
- `onMidiPreviewTap`
- `onAutomationPreviewTap`
- `_previewingItemId`
- `_previewState`

### Dependencies
Depends on WP-BRIDGE existing (bridge methods need to exist for DAWShell handlers). Can proceed in parallel with WP2-ENGINE and WP3-ENGINE if stub handlers are used (no-op stubs).

### Acceptance criteria
1. Tap audio clip → preview audio plays via `onPreviewAudio`
2. Tap MIDI clip → `onMidiPreviewTap` called with `LibraryMidiItem`
3. Tap automation clip → `onAutomationPreviewTap` called with `LibraryAutomationItem`
4. Tap preset → `onPresetTap` called, preset preview mode enters
5. Same-item re-tap → stops current preview, restarts it
6. Different item tap → stops current preview, starts new one
7. Play button action changes from insert to preview (align with tap behavior)

### Required tests
- Widget tests in `library_click_test.dart`:
  - Tap on audio item calls `onPreviewAudio`
  - Tap on MIDI item calls `onMidiPreviewTap`
  - Tap on automation item calls `onAutomationPreviewTap`
  - Tap on preset item calls `onPresetTap`
  - Same-item re-tap calls preview callback twice (restart)
  - Different-item tap stops first preview, starts second

### Manual verification steps
1. Open library, tap an audio clip → hear preview
2. Tap a MIDI clip → hear MIDI playing
3. Tap the same MIDI clip again → playback restarts from beginning
4. Tap different MIDI clip → stops first, starts second

### Integration risk
Medium. Depends on WP2-ENGINE and WP3-ENGINE for actual bridge method implementation. With stubs, the UI dispatch can be verified independently.

### Parallelization
**Parallel-safe after bridge stubs exist.** Needs bridge method contracts from WP2-ENGINE/WP3-ENGINE but can use no-op stubs for UI development.

---

## Package 3: MIDI polyphonic preview (WP-MIDI)

### Behavior
MIDI items play polyphonically (8+ voices) on the selected track's instrument or fallback oscillator. Loops continuously. Tempo-accurate at project BPM.

### Vertically: Tap → engine MIDI playback loop
User-visible: MIDI items produce correct polyphonic playback when tapped.

### Assigned files
| File | Access |
|---|---|
| `engine_juce/include/audioapp/FallbackPreviewOscillator.hpp` | C |
| `engine_juce/src/FallbackPreviewOscillator.cpp` | C |
| `engine_juce/include/audioapp/EngineHost.hpp` | W |
| `engine_juce/src/EngineHost_commands.cpp` | W |
| `engine_juce/include/audioapp/LivePerformance.hpp` | R |
| `app_flutter/lib/bridge/engine_bridge.dart` | W |
| `app_flutter/android/.../NativeBridge.cpp` | W |
| `engine_juce/tests/fallback_oscillator_test.cpp` | C |

### Allowed changes
- Create `FallbackPreviewOscillator` (polyphonic sine oscillator, 8 voices, voice stealing)
- Declare `previewMidi` and `stopPreview` in `EngineHost.hpp`
- Implement `previewMidi` and `stopPreview` in `EngineHost_commands.cpp`
- Add Dart bridge methods `previewMidi` and `stopPreview`
- Map method channel in Android JNI bridge

### Forbidden changes
- No changes to existing `DeviceChain.hpp`, `SubtractiveSynth`, other existing device types
- No changes to Flutter library UI files (callbacks handled by WP-CLICK)
- Do not modify `TestOscillator` — this is a new class

### Canonical names used
- `previewMidi` (bridge)
- `stopPreview` (bridge)
- `FallbackPreviewOscillator`
- `MidiClipState` / `MidiClipSnapshot`

### Dependencies
None at engine level. The bridge methods exist before WP-CLICK wires them.

### Acceptance criteria
1. 8+ voices play simultaneously from a multi-note MIDI clip
2. Voice stealing works when >8 notes are active (oldest voice stolen)
3. Fallback oscillator produces correct pitches (MIDI→Hz conversion)
4. Loops at clip length, tempo-synced to BPM
5. `stopPreview` silences all voices immediately
6. New `previewMidi` call stops any previous preview before starting

### Required tests
- `fallback_oscillator_test.cpp`:
  - Single note produces correct frequency
  - 8 concurrent notes each produce correct frequencies
  - Voice stealing: 9th note replaces oldest
  - `allNotesOff` silences all
  - Process block with no active voices produces silence

### Manual verification steps
1. Open library, select MIDI category
2. Tap a factory MIDI item with multiple notes
3. Hear polyphonic playback (multiple pitches simultaneously)
4. Tap another MIDI item → playback switches to new pattern
5. Close library → playback stops

### Integration risk
Low-medium. New class isolated from existing engine code. Bridge method channel mapping requires JNI work.

### Parallelization
**Sequential** with WP3 (preset preview) at engine level — both add to `EngineHost.hpp` and `EngineHost_commands.cpp`. Can run in parallel with WP-CACHE and WP-CLICK (Flutter side).

---

## Package 4: Preset preview bar (WP-PRESET)

### Behavior
When a preset is tapped, a mini arrangement bar appears at the bottom of the library panel. Shows clips, scrubbing, 8-bar loop toggle. Temp device slot for auditioning.

### Vertically: Tap preset → preview bar + engine preset preview
User-visible: Tapping a preset shows a mini arrangement and applies preset parameters to the selected track's arrangement loop.

### Assigned files
| File | Access |
|---|---|
| `app_flutter/lib/features/content_library/library_preset_preview_bar.dart` | C |
| `app_flutter/lib/features/content_library/library_fly_in_panel.dart` | W |
| `app_flutter/lib/features/content_library/library_theme.dart` | W |
| `app_flutter/lib/app/daw_shell.dart` | W |
| `app_flutter/lib/bridge/engine_bridge.dart` | W |
| `engine_juce/include/audioapp/EngineHost.hpp` | W |
| `engine_juce/src/EngineHost_commands.cpp` | W |
| `engine_juce/src/PresetPreviewSlot.cpp` | C |
| `app_flutter/android/.../NativeBridge.cpp` | W |

### Allowed changes
- Create `PresetPreviewBar` widget (mini arrangement, scrub handle, loop toggle)
- Add `PresetPreviewBar` to `LibraryFlyInPanel` layout (below content pane)
- Add `_previewingItemId` / `_previewState` / `_presetPreviewLoopEnabled` state
- Declare `previewPreset` and `stopPresetPreview` in `EngineHost.hpp`
- Implement `previewPreset` / `stopPresetPreview` engine side
- Add Dart bridge methods
- Map method channel in Android JNI
- Add `PresetPreviewBar`-specific theme colors in `library_theme.dart` if needed

### Forbidden changes
- No changes to arrangement view components
- No changes to `LibraryContentPane` item tap logic (handled by WP-CLICK)
- Do not modify existing device type files

### Canonical names used
- `PresetPreviewBar`
- `previewPreset` (bridge)
- `stopPresetPreview` (bridge)
- `PresetPreviewSlot`
- `_previewingItemId`, `_previewState`, `_presetPreviewLoopEnabled`

### Dependencies
Depends on project snapshot being available (already is). Engine preset preview methods need to exist for full demo.

### Acceptance criteria
1. Tap a preset item → `PresetPreviewBar` appears at bottom of panel
2. Bar shows clips for the selected track as mini blocks
3. User can scrub by dragging on the bar
4. Loop toggle button switches 8-bar loop on/off
5. Preset parameters applied audibly to the arrangement
6. Tap a different category → bar hides, preview stops
7. Tap same preset again → restarts preview
8. Close library → bar hides, preview stops

### Required tests
- Widget test for `PresetPreviewBar`:
  - Renders clip blocks from `TrackSnapshot`
  - Scrub drag updates playhead
  - Loop toggle calls `onLoopToggled`
- Widget test for panel integration:
  - Preset tap shows `PresetPreviewBar`
  - Category switch hides bar
  - Library close hides bar

### Manual verification steps
1. Open library, select a track with clips in arrangement
2. Switch to Presets category
3. Tap a preset → see bar appear with clips
4. Drag scrub handle → playhead position updates
5. Toggle loop on/off → loop state changes
6. Hear preset applied to arrangement playback

### Integration risk
Medium. Engine-side `previewPreset` requires `DeviceSlot` clone logic. Multiple files modified.

### Parallelization
**Sequential** with WP-MIDI at engine level (same files: `EngineHost.hpp`, `EngineHost_commands.cpp`). Flutter side (PresetPreviewBar widget) is parallel-safe with WP-CACHE and WP-CLICK.

---

## Package 5: Bridge method channel wiring (WP-BRIDGE)

### Behavior
Wires all new engine methods through the Android JNI method channel. Handles JSON serialization for `MidiClipSnapshot` and preset parameters.

### Vertically: Flutter bridge → JNI → EngineHost
User-visible: None directly (plumbing).

### Assigned files
| File | Access |
|---|---|
| `app_flutter/lib/bridge/engine_bridge.dart` | W |
| `app_flutter/android/.../NativeBridge.cpp` | W |
| `engine_juce/include/audioapp/EngineHost.hpp` | W |
| `engine_juce/src/EngineHost_commands.cpp` | W |

### Allowed changes
- All four bridge methods: `previewMidi`, `stopPreview`, `previewPreset`, `stopPresetPreview`
- Dart-to-JSON serialization of `MidiClipSnapshot` notes
- Engine command handler implementations

### Forbidden changes
- No Flutter UI changes
- No engine audio processing changes beyond command handlers

### Canonical names used
All bridge methods from sections above.

### Dependencies
Depends on WP-MIDI and WP-PRESET engine implementations being available (or at least stubbed).

### Acceptance criteria
1. All four methods invoke through method channel without PlatformException
2. Engine-side handlers accept the JSON arguments correctly
3. Return `{ ok: true }` on success
4. Return `{ ok: false, error: ... }` on failure

### Required tests
- Integration test (Android emulator): Call each method, verify no exception

### Integration risk
Low (plumbing). All four methods follow existing patterns.

### Parallelization
**Sequential** — must happen after WP-MIDI and WP-PRESET engine code is in place, or at minimum after their `EngineHost.hpp` declarations.

---

## Integration order

```
Phase 1 (Parallel):
  WP-CACHE  ─────────────────────────────────┐
  WP-MIDI (engine)  ───────┐                 │
  WP-PRESET (widget only) ──┤                │
                            │                │
Phase 2 (Sequential):       │                │
  WP-BRIDGE  ◄──────────────┘                │
                                              │
Phase 3 (Sequential):                         │
  WP-CLICK  ◄────────── WP-BRIDGE exists ────┤
                                              │
Phase 4 (Integration):                        │
  Merge WP-CLICK + WP-PRESET widget ──────────┘
  (library_fly_in_panel.dart merge)
```

### Rationale
- **WP-CACHE** is fully independent — can be done anytime
- **WP-MIDI engine** and **WP-PRESET widget** are independent of each other (engine vs UI)
- **WP-BRIDGE** needs engine declarations from WP-MIDI and WP-PRESET
- **WP-CLICK** needs bridge methods to exist (can use stubs for testing)
- **Integration merge** in `library_fly_in_panel.dart` requires WP-CLICK (preview state) + WP-PRESET (bar placement)