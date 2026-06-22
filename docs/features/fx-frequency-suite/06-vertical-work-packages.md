# Frequency FX Suite — Vertical Work Packages

## WP-1: C++ DSP Infrastructure

**Behavior**: Core processing functions and data types shared by all three frequency FX devices.

**Assigned files**:
- CREATE `engine_juce/include/audioapp/FrequencyFxProcessor.hpp`
- CREATE `engine_juce/src/FrequencyFxProcessor.cpp`

**Forbidden files**: Any device type files, any Flutter files

**Canonical names used**: All from vocabulary table

**Contracts used**:
- FilterParams, FilterRuntime, FourBandEqBandParams, FourBandEqParams, FourBandEqRuntime, FrequencyShifterParams, FrequencyShifterRuntime
- `processFilterStereoBlock`, `processFourBandEqStereoBlock`, `processFrequencyShifterStereoBlock`
- Helper functions: `normalizedToFrequency`, `normalizedToQ`, `normalizedToDb`

**Dependencies**: None (prerequisite for WP-2/3/4)

**Acceptance criteria**:
- All structs defined with correct defaults
- Processing functions use `juce::dsp` for shelf EQ (band 1/4) and `juce::dsp::IIR::Coefficients` for peak EQ (band 2/3)
- Filter processing uses existing `cookSamplerBiquad` / `processBiquadSample` from `SamplerFilter.hpp` for LP/HP/BP/Notch
- Frequency shifter uses SSB modulation (Hilbert transform pair approach)
- All functions are `noexcept`
- Files compile standalone

**Required tests**: C++ unit tests for each processing block with known inputs

**Manual verification**: N/A (infrastructure only)

**Integration risk**: Low — pure functions with no external state

**Parallel**: Prerequisite (must complete before WP-2/3/4 start)

---

## WP-2: Filter DeviceType (C++)

**Behavior**: Full `IDeviceType` implementation for the Filter device. Create defaults, set parameters, serialize/deserialize, build playback node.

**Assigned files**:
- CREATE `engine_juce/include/audioapp/devices/instances/FrequencyFxInstance.hpp` (FilterInstance portion)
- CREATE `engine_juce/include/audioapp/devices/FilterDeviceType.hpp`
- CREATE `engine_juce/src/devices/FilterDeviceType.cpp`

**Forbidden files**: EQ or shifter device type files, DeviceChain.hpp edits, DeviceRegistry.cpp edits

**Canonical names used**: FilterInstance, FilterDeviceType, `ffxCutoff`, `ffxResonance`, `ffxFilterMode`, `"filter"`

**Contracts used**:
- `FilterInstance::toPlaybackParams()` converts normalized → real values
- `setParameter` clamps normalized 0-1
- `slotToVar`/`varToSlot` follow JSON schema
- `buildPlaybackNode` sets `out.kind = DeviceNodeKind::Filter`

**Dependencies**: WP-1 (FrequencyFxProcessor.hpp must exist)

**Acceptance criteria**:
- `createDefault` returns slot with default FilterInstance values
- `setParameter` handles all 5 params (`gain`, `pan`, `bypass` delegated to `device_strip` + `ffxCutoff`, `ffxResonance`, `ffxFilterMode`)
- `buildPlaybackNode` sets correct `DeviceNodeKind::Filter` and converted params
- `slotToVar` produces valid JSON with meters stub
- `varToSlot` roundtrips correctly
- `buildLiveInstrument` returns `false`

**Required tests**:
- `device_registry_test.cpp`: verify filter can be created, parameters roundtrip
- `device_slot_serialization_test.cpp`: verify filter JSON roundtrip
- New `filter_device_test.cpp`: verify `toPlaybackParams` conversion, `setParameter` bounds

**Manual verification**: N/A

**Integration risk**: Low — follows exact pattern from CompressorDeviceType

**Parallel**: Safe after WP-1

---

## WP-3: 4-Band EQ DeviceType (C++)

**Behavior**: Full `IDeviceType` implementation for the 4-Band EQ device.

**Assigned files**:
- `engine_juce/include/audioapp/devices/instances/FrequencyFxInstance.hpp` (FourBandEqInstance portion)
- CREATE `engine_juce/include/audioapp/devices/FourBandEqDeviceType.hpp`
- CREATE `engine_juce/src/devices/FourBandEqDeviceType.cpp`

**Forbidden files**: Filter or shifter device type files

**Canonical names used**: FourBandEqInstance, FourBandEqDeviceType, `ffxBand{N}{Freq,Gain,Q}` for N=1..4

**Contracts used**: FourBandEqInstance, normalized helper functions

**Dependencies**: WP-1

**Acceptance criteria**: Same pattern as WP-2 but for 15 params (gain + pan + bypass + 12 band params)

**Required tests**: Serialization roundtrip, parameter bounds

**Manual verification**: N/A

**Integration risk**: Medium — many parameters, careful about field mapping

**Parallel**: Safe after WP-1 (parallel with WP-2, WP-4)

---

## WP-4: Frequency Shifter DeviceType (C++)

**Behavior**: Full `IDeviceType` implementation for the Frequency Shifter device.

**Assigned files**:
- `engine_juce/include/audioapp/devices/instances/FrequencyFxInstance.hpp` (FrequencyShifterInstance portion)
- CREATE `engine_juce/include/audioapp/devices/FrequencyShifterDeviceType.hpp`
- CREATE `engine_juce/src/devices/FrequencyShifterDeviceType.cpp`

**Forbidden files**: Filter or EQ device type files

**Canonical names used**: FrequencyShifterInstance, FrequencyShifterDeviceType, `ffxShift`

**Contracts used**: FrequencyShifterInstance

**Dependencies**: WP-1

**Acceptance criteria**: Single parameter `ffxShift` (0-1, 0.5=center), correct `buildPlaybackNode`

**Required tests**: Serialization roundtrip, center detection

**Manual verification**: N/A

**Integration risk**: Low — simplest device

**Parallel**: Safe after WP-1 (parallel with WP-2, WP-3)

---

## WP-5: Registration and Wiring (C++)

**Behavior**: Wire all three devices into the engine: type IDs, DeviceNodeKind entries, DeviceVariantParams, DeviceSlot variant, DeviceRegistry registration, DeviceChain.cpp processing, CMakeLists.txt.

**Assigned files**:
- MODIFY `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp`
- MODIFY `engine_juce/include/audioapp/devices/DeviceSlot.hpp`
- MODIFY `engine_juce/include/audioapp/DeviceChain.hpp`
- MODIFY `engine_juce/src/DeviceChain.cpp`
- MODIFY `engine_juce/src/devices/DeviceRegistry.cpp`
- MODIFY `engine_juce/CMakeLists.txt`

**Forbidden files**: Device type hpp/cpp files (already created by WP-2/3/4)

**Canonical names used**: All DeviceNodeKind entries, all runtime type names

**Contracts used**:
- `DeviceNodeKind::{Filter, FourBandEq, FrequencyShifter}`
- `DeviceVariantParams` includes `FilterParams`, `FourBandEqParams`, `FrequencyShifterParams`
- `processDeviceChain` has new runtime pointer parameters
- CMakeLists.txt adds new .cpp files and `juce::juce_dsp`

**Dependencies**: WP-2, WP-3, WP-4 (must have complete device type implementations)

**Acceptance criteria**:
- All three kind enum values exist
- Variant includes all three params types
- DeviceSlot variant includes all three instance types
- `findTypeForSlot` handles all three
- `createBuiltIn` registers all three
- `processDeviceChain` processes all three types
- `applyModulation` overloads for all three params types
- `isFrequencyFxDeviceNodeKind` helper function
- CMake builds and links
- Engine compiles and doesn't crash on device chain containing new devices

**Required tests**: `device_chain_test.cpp`, `device_registry_test.cpp` updated

**Manual verification**: Build engine, verify no linking errors

**Integration risk**: HIGH — must coordinate with all WP-2/3/4 outputs, must not break existing devices

**Parallel**: Sequential after WP-2/3/4 complete

---

## WP-6: Flutter Panels (UI)

**Behavior**: Three Flutter device panels with knob grids and preview graphs, plus the preview painters.

**Assigned files**:
- CREATE `app_flutter/lib/features/device_strip/frequency_fx_panels.dart`
- CREATE `app_flutter/lib/features/device_strip/filter_preview.dart`
- CREATE `app_flutter/lib/features/device_strip/eq_preview.dart`

**Forbidden files**: Engine-side files, existing Flutter files (panel widgets only — routing is WP-7)

**Canonical names used**: `ffxCutoff`, `ffxResonance`, `ffxFilterMode`, `ffxBand{N}{Freq,Gain,Q}`, `ffxShift`

**Contracts used**: The `FilterDeviceSnapshot`, `FourBandEqDeviceSnapshot`, `FrequencyShifterDeviceSnapshot` types defined by WP-7 in `device_snapshots.dart`. **WP-6 must use the field names defined in `04-data-contracts.md`**.

**Dependencies**: WP-7 must define the sealed subclasses first (or WP-6/7 can run in parallel if field names are agreed — they are, see `04-data-contracts.md`).

**Panel designs**:
- **FilterPanel**: knob grid layout (no preview per the user's request for a graph — wait, user asked for filter curve preview) — uses the existing `_timeFxSinglePage`-style layout with a filter-curve CustomPainter in the preview box, then 2 knob grid rows
  - Row 1: Cutoff, Resonance, FilterMode (4-position selector)
  - Uses `_knob()` helper from `time_fx_panels.dart` pattern (or extracts a shared helper)
- **FourBandEqPanel**: knob grid with EQ curve CustomPainter in preview box
  - 4 rows, one per band: Freq, Gain, Q knobs
- **FrequencyShifterPanel**: single Shift knob with display value showing Hz

**FilterPreview**: CustomPainter that draws the magnitude response curve for the selected filter mode at given cutoff/Q. Uses same frequency grid as spectrum analyzers. LP = low-pass curve, HP = high-pass curve, BP = band-pass peak, Notch = notch dip.

**FourBandEqPreview**: CustomPainter that draws the cumulative magnitude response of all 4 bands. Computes response at ~200 frequency points using biquad transfer function.

**Acceptance criteria**:
- All three panels follow the dynamics/time-FX panel layout conventions
- Knobs properly read/write via `onParameterChanged` with correct parameter IDs
- Preview graphs render correctly for different parameter values
- Widgets work inside `DeviceStripViewport`

**Required tests**: Dart widget tests rendering each panel

**Manual verification**: Visual inspection of panels in device chain

**Integration risk**: Medium — tightly coupled to DeviceSnapshot field names

**Parallel**: Safe after WP-7 defines sealed subclasses, or parallel with WP-7 if field names are agreed (they are)

---

## WP-7: Flutter Integration

**Behavior**: Wire the three new devices into all Flutter routing files. Create the sealed `DeviceSnapshot` subclasses.

**Assigned files**:
- MODIFY `app_flutter/lib/bridge/device_snapshots.dart` (add `FrequencyFxDeviceSnapshot` sealed class + 3 concrete subclasses + factory dispatch cases)
- MODIFY `app_flutter/lib/features/device_strip/device_strip_slot.dart`
- MODIFY `app_flutter/lib/features/device_strip/device_strip_chrome.dart`
- MODIFY `app_flutter/lib/features/device_strip/device_strip_metrics.dart`
- MODIFY `app_flutter/lib/features/device_strip/device_strip_theme.dart`
- MODIFY `app_flutter/lib/features/device_strip/device_container_tabs.dart`
- MODIFY `app_flutter/lib/features/device_strip/device_picker_sheet.dart`
- MODIFY `app_flutter/lib/features/device_strip/device_strip_device_kind.dart` (optional, add `frequencyFxDeviceTypes` set)

**Forbidden files**: Engine-side files

**Canonical names used**: `"filter"`, `"four_band_eq"`, `"frequency_shifter"`

**Contracts used**: All file-specific additions below

**Changes**:

1. **device_snapshots.dart**: Add sealed `FrequencyFxDeviceSnapshot` + 3 concrete classes (FilterDeviceSnapshot, FourBandEqDeviceSnapshot, FrequencyShifterDeviceSnapshot) + 3 cases in `DeviceSnapshot.fromMap` factory
2. **device_strip_slot.dart**: Add 3 switch cases routing to new panels, import `frequency_fx_panels.dart`. Use `final dev = widget.device as FilterDeviceSnapshot;` pattern (matches existing time-based FX routing)
3. **device_strip_chrome.dart**: Add types to `_dynamicsTypes` set (so they get DynamicsInputPanel + DynamicsOutputPanel) — OR introduce a new `_frequencyFxTypes` set
4. **device_strip_metrics.dart**: Add design widths, input/output widths (use `dynamicsFxDesignWidth`)
5. **device_strip_theme.dart**: Add accent colors and labels
6. **device_container_tabs.dart**: Add entries returning empty tab lists
7. **device_picker_sheet.dart**: Add "Frequency Effects" section header + 3 device entries between "Effects" and "Time-Based Effects"
8. **device_strip_device_kind.dart**: (optional) add `frequencyFxDeviceTypes` set with `isFrequencyFxDevice` extension

**Accent colors** (chosen):
- Filter: `Color(0xFF5BC0EB)` (teal/cyan)
- 4-Band EQ: `Color(0xFF78C091)` (sage green)
- Frequency Shifter: `Color(0xFFC77DFF)` (purple/lavender)

**Design widths**: Use `dynamicsFxDesignWidth` (same as dynamics + time-based FX devices, ~216px)

**Dependencies**: WP-6 (frequency_fx_panels.dart must exist for imports in `device_strip_slot.dart`)

**Acceptance criteria**:
- Flutter project compiles
- All new devices appear in device picker under "Frequency Effects" section
- Device strip shows correct chrome (dynamics-style input/output)
- Panels render with correct field values

**Required tests**: `flutter analyze` passes with 0 errors

**Manual verification**: Launch app, add each device type, verify appearance

**Integration risk**: Medium — many files to modify consistently

**Parallel**: Sequential after WP-6 (or in parallel with WP-6 since field names are agreed)

---

## WP-8: Tests

**Behavior**: Comprehensive tests for all three devices.

**Assigned files**:
- CREATE `engine_juce/tests/frequency_fx_test.cpp`
- CREATE `engine_juce/tests/filter_device_test.cpp`
- CREATE `engine_juce/tests/four_band_eq_test.cpp`
- CREATE `engine_juce/tests/frequency_shifter_test.cpp`
- MODIFY `engine_juce/CMakeLists.txt` (add test sources)

**Forbidden files**: Production source files

**Contracts used**: All parameter names, JSON schemas, processing functions

**Required coverage**:
- Processing: verify silence in = silence out
- Processing: verify non-zero input produces non-zero output (no crash)
- Processing: verify different filter modes produce different output
- Serialization: verify JSON roundtrip for each device
- Parameter: verify clamp behavior
- Parameter: verify setParameter recognized/handled

**Dependencies**: WP-5 complete (engine builds with new devices)

**Acceptance criteria**: All tests pass

**Integration risk**: Low

**Parallel**: Safe after WP-5