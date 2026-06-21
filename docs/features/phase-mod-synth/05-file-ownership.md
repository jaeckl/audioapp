# File Ownership: Phase Modulation Synth Device

## Engine files — New DSP core

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `engine_juce/include/audioapp/PhaseModSynth.hpp` | WP-1 | Create new file | — |
| `engine_juce/src/PhaseModSynth.cpp` | WP-1 | Create new file | — |

## Engine files — Device type registration

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp` | WP-2 | Add `kPhaseModSynth` constant | Change existing constants |
| `engine_juce/include/audioapp/devices/PhaseModSynthDeviceType.hpp` | WP-2 | Create new file | — |
| `engine_juce/include/audioapp/devices/instances/PhaseModSynthInstance.hpp` | WP-2 | Create new file | — |
| `engine_juce/src/devices/PhaseModSynthDeviceType.cpp` | WP-2 | Create new file | — |
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | WP-2 | Add `#include "PhaseModSynthInstance.hpp"` + variant entry | Touch existing instance includes |
| `engine_juce/src/devices/DeviceRegistry.cpp` | WP-2 | Add `#include "PhaseModSynthDeviceType.hpp"` + registration + variant check | Touch existing registrations |
| `engine_juce/include/audioapp/DeviceChain.hpp` | WP-2 | Add `DeviceNodeKind::PhaseModSynth` + `PhaseModSynthParams` to `DeviceVariantParams` | Touch existing variant entries |
| `engine_juce/include/audioapp/LivePerformance.hpp` | WP-2 | Add `LiveInstrumentKind::PhaseModSynth` + `phaseMod` field to `LiveInstrumentSnapshot` | Touch existing fields |

## Engine files — Automation and audio chain

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `engine_juce/include/audioapp/AutomationTypes.hpp` | WP-3 | Add `ParamKind::PhaseModSynth` + `PhaseModSynthParam` enum + pack/unpack | Change existing param enums |
| `engine_juce/src/AutomationPlayback.cpp` | WP-3 | Add `PhaseModSynth` cases in all dispatch tables | Change existing switch cases |
| `engine_juce/src/DeviceChain.cpp` | WP-4 | Add `case DeviceNodeKind::PhaseModSynth:` in `processDeviceChain`, `nodeHasDspAutomation`, `isInstrumentDeviceNodeKind` | Touch existing device type cases |
| `engine_juce/src/LivePerformance.cpp` | WP-4 | Add `LiveInstrumentKind::PhaseModSynth` handling, add `phaseMod` field set in `noteOn`/render | Touch existing instrument cases |

## Flutter files

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `app_flutter/lib/features/device_strip/phase_mod_synth_device_panel.dart` | WP-5 | Create new file | — |
| `app_flutter/lib/features/device_strip/phase_mod_synth_device_strip.dart` | WP-5 | Create new file | — |
| `app_flutter/lib/features/device_strip/phase_mod_synth_editor_screen.dart` | WP-5 | Create new file | — |
| `app_flutter/lib/features/device_strip/phase_mod_synth_presets.dart` | WP-5 | Create new file | — |
| `app_flutter/lib/features/device_strip/device_picker_sheet.dart` | WP-5 | Add Phase Mod Synth `ListTile` entry | Touch existing list tiles |
| `app_flutter/lib/features/device_strip/device_strip_slot.dart` | WP-5 | Add import + `'phase_mod_synth'` case + tab callbacks + subtitle | Touch existing device type cases |
| `app_flutter/lib/features/device_strip/device_strip_theme.dart` | WP-5 | Add `phaseModSynthAccent` + `'phase_mod_synth'` → accent + label | Change existing accent colors |
| `app_flutter/lib/features/device_strip/device_strip_metrics.dart` | WP-5 | Add `phaseModSynthDesignWidth` + `'phase_mod_synth'` case in `designWidthFor` | Change existing design widths |
| `app_flutter/lib/features/device_strip/device_container_tabs.dart` | WP-5 | Add `'phase_mod_synth'` case → `PhaseModSynthDevicePanel.containerTabs` | Change existing tab defs |
| `app_flutter/lib/bridge/project_snapshot.dart` | WP-5 | Add 54 PM fields to `DeviceSnapshot` (constructor, `fromMap`, `copyWith`, `withParameter`) | Change existing fields |

## Test files

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `engine_juce/tests/phase_mod_synth_test.cpp` | WP-6 | Create new file | — |
| `app_flutter/test/phase_mod_synth_snapshot_test.dart` | WP-6 | Create new file | — |