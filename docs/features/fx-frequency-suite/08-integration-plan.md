# Frequency FX Suite — Integration Plan

## Recommended Implementation Order

```
Step 1: WP-1 (C++ DSP Infrastructure) — PREREQUISITE
Step 2: WP-2 (Filter DeviceType), WP-3 (EQ DeviceType), WP-4 (FreqShifter DeviceType) — PARALLEL
Step 3: WP-5 (Registration and Wiring) — SEQUENTIAL, after WP-2/3/4
Step 4: WP-6 (Flutter Panels) + WP-7 (Flutter Integration) — PARALLEL (field names are agreed in 04-data-contracts.md)
Step 5: WP-8 (Tests) — AFTER WP-5 (can overlap WP-6/7)
```

## Packages That Can Run in Parallel

- **WP-2, WP-3, WP-4**: All three device types are fully independent once WP-1 is done. No shared files (`FrequencyFxInstance.hpp` is shared but each only touches its own struct).
- **WP-6 and WP-7**: Can run in parallel because the sealed subclass field names are specified in `04-data-contracts.md` and don't change. WP-7 creates the sealed classes + `fromMap` cases; WP-6 imports them.
- **WP-8 subtests**: Filter tests can run in parallel with EQ tests, etc.

## Packages That Must Be Sequential

- **WP-1 → WP-2/3/4**: WP-1 must exist first since all device types depend on FrequencyFxProcessor.hpp
- **WP-2/3/4 → WP-5**: Registration and wiring requires all device types to be fully implemented
- **WP-6 → WP-7 (slot routing)**: Device strip slot imports panel widgets, so panel file must exist before slot routing. But WP-7's other edits (sealed subclass creation, picker, theme, metrics) can run in parallel with WP-6.

## Shared Files Requiring Care

| File | Accessed By | Risk |
|------|-------------|------|
| `FrequencyFxInstance.hpp` | WP-2, WP-3, WP-4 (writers), WP-5 (reader) | All three packages write to the same file. **Recommendation**: WP-1 creates an empty `FrequencyFxInstance.hpp` with just a comment, WP-2 fills in `FilterInstance`, WP-3 adds `FourBandEqInstance`, WP-4 adds `FrequencyShifterInstance`. |
| `device_snapshots.dart` | WP-7 (writer), WP-6 (reader) | WP-7 owns; WP-6 imports the new types. WP-6 may also write small imports in this file (e.g. `export 'device_snapshots.dart';` is already in `project_snapshot.dart`). |
| `DeviceChain.hpp` | WP-5 (writer) | Single-writer, safe |
| `DeviceChain.cpp` | WP-5 (writer) | Single-writer, safe (large switch, merge conflicts possible) |
| `DeviceRegistry.cpp` | WP-5 (writer) | Single-writer, safe |
| `device_strip_slot.dart` | WP-7 (writer) | Single-writer, safe |
| `CMakeLists.txt` | WP-5 + WP-8 (writers) | Single-writer per package; WP-8's edit is in the `AUDIOAPP_TEST_SOURCES` list, WP-5's edit is in `add_library(audioapp_engine STATIC ...)` |

## Contract Gaps and Risks

1. **juce::dsp dependency**: Need to add `juce::juce_dsp` to `CMakeLists.txt` `target_link_libraries` for the host build. Risk: may need different handling for Android cross-compile (juce_dsp may not be fully available without certain flags). **Mitigation**: Test build on Android NDK path.

2. **Frequency Shifter algorithm**: SSB modulation requires a Hilbert transform (90-degree phase shift). Can use `juce::dsp::Oscillator<float>` with a Hilbert filter, or implement a simple phasor-based approach with a small Hilbert delay-line. **Fallback**: Simple ring modulation (multiply by complex sinusoid) with analytic signal via JUCE's Hilbert filter.

3. **4-Band EQ shelf filters**: The existing biquad `cookSamplerBiquad` only supports LP/HP/BP/Notch. Need to add shelf filter coefficient calculation (low shelf and high shelf). **Decision**: Use `juce::dsp::IIR::Coefficients<float>::makeLowShelf()`, `makePeakFilter()`, `makeHighShelf()` which are available in `juce_dsp`.

4. **Frequency FX category routing**: In `DeviceStripChrome`, the existing sets are:
   - `_dynamicsTypes` = `{gate, compressor, expander, limiter}` — routes to `DynamicsInputPanel` + `DynamicsOutputPanel`
   - `_timeFxTypes` = `{delay, reverb, chorus, phaser}` — ALSO routes to `DynamicsInputPanel` + `DynamicsOutputPanel` (per commit `2edd2bb`)
   - `_drumTypes` = `{kick_generator, ...}` — routes to `DrumMonoOutputPanel` (no input)
   
   Time-based effects already use the dynamics-style chrome, so adding frequency FX to either `_dynamicsTypes` or `_timeFxTypes` works. **Decision**: introduce a new `_frequencyFxTypes` set for clarity, and update the routing to use it (`_dynamicsTypes.contains(deviceType) || _frequencyFxTypes.contains(deviceType)` etc.). This keeps the intent clear.

5. ~~DeviceSnapshot field density~~ (RESOLVED): The `DeviceSnapshot sealed hierarchy` refactor (`89fab48`) means we add new sealed subclasses, not flat fields. The contract is updated to reflect this.

6. **Meters on non-dynamics devices**: `DynamicsOutputPanel` shows a GR meter + Gain knob. For frequency FX, GR meter will show 0 (no gain reduction). This matches the existing time-FX UX (delay/reverb/chorus/phaser also show GR=0). Consistent and acceptable.

## Build Verification Steps

After WP-5 (engine builds with new devices):

1. Configure engine build on Linux:
   ```
   cmake -S engine_juce -B build/engine -G Ninja \
     -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++
   ```
2. Build:
   ```
   cmake --build build/engine --target audioapp_engine
   ```
3. Build tests (may not link due to pre-existing test issues per AGENTS.md):
   ```
   cmake --build build/engine --target audioapp_juce_tests
   ```
4. Run Flutter tests:
   ```
   cd app_flutter && flutter test
   ```
5. Run Flutter analyze (0 errors expected):
   ```
   cd app_flutter && flutter analyze
   ```