# Frequency FX Suite — File Ownership

## New Files

| File | Owner Package | Allowed Changes | Forbidden Changes |
|------|--------------|-----------------|-------------------|
| `engine_juce/include/audioapp/FrequencyFxProcessor.hpp` | WP-1 | Add runtime structs, params structs, processing function declarations | Business logic in device types |
| `engine_juce/src/FrequencyFxProcessor.cpp` | WP-1 | Implement processing functions | Device type registration |
| `engine_juce/include/audioapp/devices/instances/FrequencyFxInstance.hpp` | WP-2/3/4 | Add FilterInstance, FourBandEqInstance, FrequencyShifterInstance | Anything outside instance structs |
| `engine_juce/include/audioapp/devices/FilterDeviceType.hpp` | WP-2 | FilterDeviceType class declaration | EQ or shifter code |
| `engine_juce/src/devices/FilterDeviceType.cpp` | WP-2 | FilterDeviceType implementation | EQ or shifter code |
| `engine_juce/include/audioapp/devices/FourBandEqDeviceType.hpp` | WP-3 | FourBandEqDeviceType class declaration | Filter or shifter code |
| `engine_juce/src/devices/FourBandEqDeviceType.cpp` | WP-3 | FourBandEqDeviceType implementation | Filter or shifter code |
| `engine_juce/include/audioapp/devices/FrequencyShifterDeviceType.hpp` | WP-4 | FrequencyShifterDeviceType class declaration | Filter or EQ code |
| `engine_juce/src/devices/FrequencyShifterDeviceType.cpp` | WP-4 | FrequencyShifterDeviceType implementation | Filter or EQ code |
| `app_flutter/lib/features/device_strip/frequency_fx_panels.dart` | WP-6 | FilterPanel, FourBandEqPanel, FreqShifterPanel widgets | Engine-side code |
| `app_flutter/lib/features/device_strip/filter_preview.dart` | WP-6 | Filter preview CustomPainter | |
| `app_flutter/lib/features/device_strip/eq_preview.dart` | WP-6 | EQ curve CustomPainter | |

## Existing Files to Modify

| File | Owner Package | Allowed Changes | Forbidden Changes |
|------|--------------|-----------------|-------------------|
| `engine_juce/CMakeLists.txt` | WP-5 | Add new .cpp files, add juce::juce_dsp link | Anything not related to build |
| `engine_juce/include/audioapp/DeviceChain.hpp` | WP-5 | Add DeviceNodeKind entries, DeviceVariantParams entries, runtime ptr params | |
| `engine_juce/src/DeviceChain.cpp` | WP-5 | Add switch cases, applyModulation overloads, `isFrequencyFxDeviceNodeKind` | |
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | WP-5 | Add `FrequencyFxInstance.hpp` include + variant entries | |
| `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp` | WP-5 | Add `kFilter`, `kFourBandEq`, `kFrequencyShifter` constants | |
| `engine_juce/src/devices/DeviceRegistry.cpp` | WP-5 | Add includes, `findTypeForSlot` checks, `createBuiltIn` registrations | |
| `app_flutter/lib/bridge/device_snapshots.dart` | WP-7 | Add `FrequencyFxDeviceSnapshot` sealed class + 3 concrete subclasses + `fromMap` factory cases | |
| `app_flutter/lib/features/device_strip/device_strip_slot.dart` | WP-7 | Add 3 switch cases (`final dev = widget.device as FilterDeviceSnapshot;` etc.), import `frequency_fx_panels.dart` | |
| `app_flutter/lib/features/device_strip/device_strip_chrome.dart` | WP-7 | Add types to `_dynamicsTypes` set (or new `_frequencyFxTypes` set if cleaner) | |
| `app_flutter/lib/features/device_strip/device_strip_metrics.dart` | WP-7 | Add `designWidthFor`, `inputPanelWidthFor`, `outputPanelWidthFor` entries | |
| `app_flutter/lib/features/device_strip/device_strip_theme.dart` | WP-7 | Add accent colors and labels | |
| `app_flutter/lib/features/device_strip/device_strip_device_kind.dart` | WP-7 | (Optional) add new `frequencyFxDeviceTypes` set for `isFrequencyFxDevice` extension | |
| `app_flutter/lib/features/device_strip/device_container_tabs.dart` | WP-7 | Add entries returning empty tab lists | |
| `app_flutter/lib/features/device_strip/device_picker_sheet.dart` | WP-7 | Add "Frequency Effects" section header + 3 device entries between "Effects" and "Time-Based Effects" | |

## Flutter Side Note: `project_snapshot.dart` is now a thin wrapper

`app_flutter/lib/bridge/project_snapshot.dart` no longer contains the `DeviceSnapshot` class. It now `export`s from `device_snapshots.dart`:

```dart
export 'device_snapshots.dart';
```

**Therefore WP-7 edits `device_snapshots.dart`, not `project_snapshot.dart`.**