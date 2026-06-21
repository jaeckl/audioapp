# Feature Brief: Phase Modulation Synthesizer

## User-visible goal

Add a professional **Phase Modulation Synthesis** instrument device (4-operator PM synth in the spirit of Ableton Operator / Bitwig FM-4 / Yamaha DX7). The user picks "Phase Mod Synth" from the device picker, sees a mobile-optimized 4-tab UI (ALGO, OP, MOD, TONE), designs PM sounds by configuring operators, algorithms, envelopes, LFOs, and filter, then plays expressive FM/PM tones — from classic electric pianos and bells to aggressive basses, pads, and brass.

## Demo script (PO acceptance)

1. User opens device picker → sees "Phase Mod Synth" entry
2. Taps "Phase Mod Synth" → device appears in chain with header showing "Phase Mod Synth · 4-OP"
3. Card shows four tabs: ALGO, OP, MOD, TONE
4. Tab ALGO: user picks algorithm #3 (a classic FM routing), sees visual routing matrix with operator boxes and arrows
5. Tab OP: user selects operator 2, adjusts frequency ratio (coarse + fine cents), level, and ADSR envelope
6. Tab MOD: user sets global LFO rate and shape (triangle), routes to pitch
7. Tab TONE: user adjusts filter cutoff, resonance, amp envelope, master volume, pan
8. User plays MIDI notes → rich PM/FM tone is heard (e.g. classic FM electric piano)
9. User can select algorithm → routing instantly changes
10. User saves project → reload → all PM synth parameters restored, including algorithm, operator configs, LFO settings
11. User records automation on filter cutoff → plays back correctly
12. User loads a factory preset → all operator params, algorithm, mod settings load instantly

## Non-goals

- Do not support loading external DX7 SysEx patches (MVP only: 16 factory presets stored as JSON in `phase_mod_synth_presets.dart`)
- Do not add a built-in arpeggiator or sequencer (future feature)
- Do not add feedback routing visualization beyond the algorithm matrix
- Do not implement multi-timbral (4 operators within one voice only)
- Do not add MIDI learn or external controller mapping
- Do not implement FM with arbitrary waveforms (operators are morph sine/tri/saw/square/noise within specified shapes, PM core is sine-based)
- Do not attempt to replicate the full DX7 complexity (8+ algorithms, not 32)
- Do not add a graphical envelope editor (envelopes are knob-based ADSR for MVP)
- Do not add preset management UI beyond the 16 factory presets (user preset saving = future)

## Existing code to reuse

- `DeviceRegistry` registration pattern
- `IDeviceType` interface
- `DeviceSlot` variant pattern
- `DeviceNodePlayback` / `DeviceVariantParams` dispatch pattern (will need new `PhaseModSynthParams` variant entry)
- `LiveInstrumentSnapshot` / `LiveInstrumentKind` dispatch pattern
- `DeviceStripSlot` / `DeviceStripMetrics` / `DeviceStripTheme` routing in Flutter
- `DeviceTabBar` / `RotaryKnob` / `PanelVariant` / `_panelBox` / `_knob` UI helpers
- `DeviceLandscapeShell` for fullscreen editor
- `SamplerDevicePanel.formatPercent` / `formatCutoffHz` / `formatQ` formatting helpers
- `DraggableIntValueBox` for integer controls (ratio selection, operator select)
- Existing `SubtractiveSynth` filter (the PM synth output passes through the same filter section: filter type, cutoff, resonance, envelope amount, key track)
- Existing `DeviceState` DTO (shared filter/amp fields reused, PM-specific fields added with `pm*` prefix)
- Existing project snapshot serialization via bridge

## New code required

- New audio DSP engine: `engine_juce/include/audioapp/PhaseModSynth.hpp` / `engine_juce/src/PhaseModSynth.cpp`
  - PhaseModSynthParams struct (4 operators, algorithm, filter, amp, LFO, global)
  - PhaseModSynthVoiceRuntime struct (per-voice state)
  - PhaseModSynthRuntime (voice pool)
  - `renderPhaseModVoice()` per-sample function
  - `mixPhaseModMidiNotesBlock()` block renderer
  - `renderPhaseModLiveVoice()` live renderer
- New instance struct: `engine_juce/include/audioapp/devices/instances/PhaseModSynthInstance.hpp`
- New device type: `engine_juce/include/audioapp/devices/PhaseModSynthDeviceType.hpp` / `engine_juce/src/devices/PhaseModSynthDeviceType.cpp`
- New DeviceNodeKind entry: `PhaseModSynth`
- New LiveInstrumentKind entry: `PhaseModSynth`
- New Flutter panel: `phase_mod_synth_device_panel.dart` (4 tabs: ALGO, OP, MOD, TONE)
- New Flutter strip: `phase_mod_synth_device_strip.dart`
- New Flutter editor screen: `phase_mod_synth_editor_screen.dart`
- New presets file: `phase_mod_synth_presets.dart`
- Modifications to: `DeviceTypeIds.hpp`, `DeviceSlot.hpp`, `DeviceRegistry.cpp`, `DeviceChain.hpp`, `LivePerformance.hpp`, `DeviceChain.cpp`, `LivePerformance.cpp`, `DeviceState.hpp`, `AutomationTypes.hpp`, `AutomationPlayback.cpp`, `DeviceVariantParams`, `project_snapshot.dart`, `device_strip_slot.dart`, `device_strip_metrics.dart`, `device_strip_theme.dart`, `device_container_tabs.dart`, `device_picker_sheet.dart`
