# File Ownership: Bass Synth Device

## Engine files

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp` | WP-1 | Add `kBasSynth` constant | Change any existing constant |
| `engine_juce/include/audioapp/devices/BassSynthDeviceType.hpp` | WP-1 | Create new file | — |
| `engine_juce/include/audioapp/devices/instances/BassSynthInstance.hpp` | WP-1 | Create new file | — |
| `engine_juce/src/devices/BassSynthDeviceType.cpp` | WP-1 | Create new file | — |
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | WP-1 | Add `#include "BassSynthInstance.hpp"` + `BassSynthInstance` variant entry | Touch any existing instance include |
| `engine_juce/src/devices/DeviceRegistry.cpp` | WP-1 | Add `#include "BassSynthDeviceType.hpp"` + `#include "instances/BassSynthInstance.hpp"`, register + variant check | Touch any existing registration |
| `engine_juce/include/audioapp/DeviceChain.hpp` | WP-1 | Add `BassSynth` to `DeviceNodeKind` enum | Touch existing DSP structs |
| `engine_juce/include/audioapp/LivePerformance.hpp` | WP-1 | Add `BassSynth` to `LiveInstrumentKind` enum | Touch existing voice/runtime structs |
| `engine_juce/include/audioapp/DeviceState.hpp` | WP-2 | Add 9 bass-specific fields | Change existing field names/defaults |
| `engine_juce/include/audioapp/AutomationTypes.hpp` | WP-3 | Add `ParamKind::BassSynth` to enum, add `BassSynthParam` enum, add to `packParamId`/`unpackParamId` | Change existing param enums |
| `engine_juce/src/AutomationPlayback.cpp` | WP-3 | Add `BassSynth` case to `paramKindFromDeviceNodeKind`, `paramIdFromString`, `paramIdToString`, `applyAutomationValue`, `paramDescriptorsForKind` | Change existing switch cases |
| `engine_juce/src/DeviceChain.cpp` | WP-4 | Add `case DeviceNodeKind::BassSynth:` — same logic as `SubtractiveSynth` | Touch the `SubtractiveSynth` case |
| `engine_juce/src/LivePerformance.cpp` | WP-4 | Add `LiveInstrumentKind::BassSynth` handling — same logic as `SubtractiveSynth` | Touch existing instrument kind cases |

## Flutter files

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `app_flutter/lib/features/device_strip/bass_synth_device_panel.dart` | WP-5 | Create new file | — |
| `app_flutter/lib/features/device_strip/bass_synth_device_strip.dart` | WP-5 | Create new file | — |
| `app_flutter/lib/features/device_strip/device_picker_sheet.dart` | WP-5 | Add Bass Synth `ListTile` entry | Touch existing list tiles |
| `app_flutter/lib/features/device_strip/device_strip_slot.dart` | WP-5 | Add import + `'bass_synth'` case in `_buildDevice()` switch, `_initialTabIndex()`, `_onTabSelected()`, `_cardSubtitle`, `onSynthTabChanged` | Touch existing device type cases |
| `app_flutter/lib/features/device_strip/device_strip_theme.dart` | WP-5 | Add `bassSynthAccent` constant + add `'bass_synth'` → `bassSynthAccent` + `'Bass Synth'` in `accentForDeviceType`/`labelForDeviceType` | Change existing accent colors |
| `app_flutter/lib/features/device_strip/device_strip_metrics.dart` | WP-5 | Add `bassSynthDesignWidth` + `'bass_synth'` case in `designWidthFor` | Change existing design widths |
| `app_flutter/lib/features/device_strip/device_container_tabs.dart` | WP-5 | Add `'bass_synth'` case → `BassSynthDevicePanel.containerTabs` | Change existing tab defs |
| `app_flutter/lib/bridge/project_snapshot.dart` | WP-5 | Add 9 bass fields to `DeviceSnapshot` (constructor, `fromMap`, `copyWith`, `withParameter`) | Change existing fields |

## Test files

| File | Owner | Allowed changes | Forbidden changes |
|------|-------|----------------|-------------------|
| `engine_juce/tests/bass_synth_test.cpp` | WP-6 | Create new file | — |
| `app_flutter/test/bass_synth_snapshot_test.dart` | WP-6 | Create new file | — |