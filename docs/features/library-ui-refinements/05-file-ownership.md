# Library UI Refinements — File Ownership

## Legend
- **R**: Read only
- **W**: Write / modify
- **C**: Create new
- **—**: No access

| File path | WP1: Click→preview | WP2: MIDI poly | WP3: Preset preview bar | WP4: Cache | Notes |
|---|---|---|---|---|---|
| **Flutter** | | | | | |
| `app_flutter/lib/features/content_library/library_content_pane.dart` | W | — | — | W | Modify `_onItemTap`, add `onMidiPreviewTap`/`onAutomationPreviewTap` callbacks, wire cache |
| `app_flutter/lib/features/content_library/library_fly_in_panel.dart` | W | — | W | W | Add preview state, PresetPreviewBar placement, cache lifecycle |
| `app_flutter/lib/features/content_library/library_preview_widget.dart` | — | — | — | W | No changes needed for cache (cache wraps fetch, widget stays same) |
| `app_flutter/lib/features/content_library/library_catalog.dart` | R | R | R | R | Read-only, no changes |
| `app_flutter/lib/features/content_library/library_category.dart` | R | R | R | R | Read-only, no changes |
| `app_flutter/lib/features/content_library/library_category_menu.dart` | R | R | R | R | Read-only, no changes |
| `app_flutter/lib/features/content_library/library_tag_filter_bar.dart` | R | R | R | R | Read-only, no changes |
| `app_flutter/lib/features/content_library/library_header.dart` | R | R | R | R | Read-only, no changes |
| `app_flutter/lib/features/content_library/library_manifest.dart` | R | R | R | R | Read-only, no changes |
| `app_flutter/lib/features/content_library/library_theme.dart` | R | R | W | — | May add PresetPreviewBar-specific theme colors |
| `app_flutter/lib/features/content_library/library_preview_cache.dart` | — | — | — | C | **New file**: `ClipPreviewCache` class |
| `app_flutter/lib/features/content_library/library_preset_preview_bar.dart` | — | — | C | — | **New file**: `PresetPreviewBar` widget |
| `app_flutter/lib/app/daw_shell.dart` | W | W | W | — | Wire new callbacks, implement preview handlers |
| `app_flutter/lib/bridge/engine_bridge.dart` | — | W | W | — | Add `previewMidi`, `stopPreview`, `previewPreset`, `stopPresetPreview` |
| `app_flutter/lib/bridge/project_snapshot.dart` | R | R | R | R | Read-only, no changes needed |
| `app_flutter/lib/bridge/clip_snapshots.dart` | R | R | R | R | Read-only, no changes needed |
| `app_flutter/lib/bridge/transport_state.dart` | R | R | R | R | Read-only, no changes needed |
| **Engine (C++)** | | | | | |
| `engine_juce/include/audioapp/EngineHost.hpp` | — | W | W | — | Add `previewMidi`, `stopPreview`, `previewPreset`, `stopPresetPreview` declarations |
| `engine_juce/src/EngineHost_commands.cpp` | — | W | W | — | Implement new bridge command handlers |
| `engine_juce/include/audioapp/DeviceChain.hpp` | — | R | R | — | Existing oscillator is monophonic (read for reference) |
| `engine_juce/include/audioapp/LivePerformance.hpp` | — | W | — | — | Add `Oscillator` kind to `LiveInstrumentKind`, or reference `FallbackPreviewOscillator` |
| `engine_juce/include/audioapp/FallbackPreviewOscillator.hpp` | — | C | — | — | **New file**: Polyphonic fallback oscillator |
| `engine_juce/src/FallbackPreviewOscillator.cpp` | — | C | — | — | **New file**: Implementation |
| `engine_juce/src/PresetPreviewSlot.cpp` | — | — | C | — | **New file**: Preset temp slot management (may inline in EngineHost) |
| `engine_juce/include/audioapp/SubtractiveSynth.hpp` | — | R | R | — | Reference for polyphonic voice implementation pattern |
| `engine_juce/include/audioapp/MidiClipPlayback.hpp` | — | R | R | — | Existing MIDI playback structures (read for reference) |
| **Android JNI** | | | | | |
| `app_flutter/android/.../NativeBridge.cpp` | — | W | W | — | Map new method channel methods to engine calls |
| **Tests** | | | | | |
| `app_flutter/test/library_cache_test.dart` | — | — | — | C | **New file**: Cache unit tests |
| `app_flutter/test/library_click_test.dart` | C | W | W | W | **New/update**: Click behavior, preview dispatch tests |
| `engine_juce/tests/fallback_oscillator_test.cpp` | — | C | — | — | **New file**: Oscillator polyphony tests |

## Shared files requiring care

| File | Packages accessing | Coordination needed |
|---|---|---|
| `library_content_pane.dart` | WP1, WP4 | WP4 adds cache integration, WP1 modifies callbacks — must merge carefully |
| `library_fly_in_panel.dart` | WP1, WP3, WP4 | WP1 adds preview state, WP3 adds PresetPreviewBar placement, WP4 adds cache lifecycle — most coordination needed |
| `daw_shell.dart` | WP1, WP2, WP3 | WP1 wires new callbacks, WP2 implements MIDI preview handler, WP3 implements preset preview handler — sequential dependency |
| `engine_bridge.dart` | WP2, WP3 | Both add methods to the same class — merge conflict risk |
| `EngineHost.hpp` / `EngineHost_commands.cpp` | WP2, WP3 | Both add declarations and command handlers — sequential dependency |