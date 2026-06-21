# Frequency FX Suite — Integration Plan

## Recommended Implementation Order

```
Step 1: WP-1 (C++ DSP Infrastructure) — PREREQUISITE
Step 2: WP-2 (Filter DeviceType), WP-3 (EQ DeviceType), WP-4 (FreqShifter DeviceType) — PARALLEL
Step 3: WP-5 (Registration and Wiring) — SEQUENTIAL, after WP-2/3/4
Step 4: WP-6 (Flutter Panels) — PARALLEL with WP-7 (or sequential)
Step 5: WP-7 (Flutter Integration) — AFTER or PARALLEL WITH WP-6
Step 6: WP-8 (Tests) — AFTER WP-5 (can overlap WP-6/7)
```

## Packages That Can Run in Parallel

- **WP-2, WP-3, WP-4**: All three device types are fully independent once WP-1 is done. No shared files (FrequencyFxInstance.hpp is shared but each only touches its own struct).
- **WP-6 and WP-7**: Can run in parallel if WP-6 uses the agreed DeviceSnapshot field names and WP-7 adds them. Small risk if field names drift.
- **WP-8 subtests**: Filter tests can run in parallel with EQ tests, etc.

## Packages That Must Be Sequential

- **WP-1 → WP-2/3/4**: WP-1 must exist first since all device types depend on FrequencyFxProcessor.hpp
- **WP-2/3/4 → WP-5**: Registration and wiring requires all device types to be fully implemented
- **WP-6 → WP-7**: Device strip slot imports panel widgets, so panels must exist before shell routing

## Shared Files Requiring Care

| File | Accessed By | Risk |
|------|-------------|------|
| `FrequencyFxInstance.hpp` | WP-2, WP-3, WP-4 (writers), WP-5 (reader) | All three packages write to the same file. Must coordinate — either make WP-2 write the whole file, or create a contract-first stub in WP-1. **Recommendation**: WP-1 creates an empty FrequencyFxInstance.hpp with just a comment, WP-2 fills in FilterInstance, WP-3 adds EqInstance, WP-4 adds ShifterInstance. |
| `DeviceChain.hpp` | WP-5 (writer) | Single-writer, safe |
| `DeviceChain.cpp` | WP-5 (writer) | Single-writer, safe (large switch, merge conflicts possible) |
| `DeviceRegistry.cpp` | WP-5 (writer) | Single-writer, safe |
| `project_snapshot.dart` | WP-7 (writer) | Single-writer, safe |
| `device_strip_slot.dart` | WP-7 (writer) | Single-writer, safe |
| `CMakeLists.txt` | WP-5 (writer) | Single-writer, safe |

## Contract Gaps and Risks

1. **juce::dsp dependency**: Need to add `juce::juce_dsp` to `CMakeLists.txt` target_link_libraries for the host build. Risk: may need different handling for Android cross-compile (juce_dsp may not be fully available without certain flags). **Mitigation**: Test build on Android NDK path.

2. **Frequency Shifter algorithm**: SSB modulation requires a Hilbert transform (90-degree phase shift). Can use `juce::dsp::FrequencyShifter` if available, or implement a simple phasor-based approach. **Fallback**: Simple ring modulation (multiply by complex sinusoid) with analytic signal via JUCE's Hilbert filter.

3. **4-Band EQ shelf filters**: The existing biquad `cookSamplerBiquad` only supports LP/HP/BP/Notch. Need to add shelf filter coefficient calculation (low shelf and high shelf) — either extend cookSamplerBiquad or use juce::dsp::IIR::Coefficients. **Decision**: Use `juce::dsp::IIR::Coefficients::makeLowShelf()`, `makePeakFilter()`, `makeHighShelf()` which are available in juce_dsp.

4. **Frequency FX category routing**: In `DeviceStripChrome`, the `_dynamicsTypes` set is used to route DynamicsInputPanel/DynamicsOutputPanel. Adding our types to this set is a pragmatic choice but semantically odd (they aren't dynamics). **Decision**: Renaming would be scope creep — just add to `_dynamicsTypes` and note the intent in a comment. If a dedicated `_frequencyFxTypes` set is preferred, this is a one-line change.

5. **DeviceSnapshot field density**: Adding 15 new fields to the already-large DeviceSnapshot continues the flat-field pattern. This is consistent but the class is becoming unwieldy. **Decision**: Follow existing pattern for consistency; a future refactor could introduce nested parameter objects.

6. **Meters on non-dynamics devices**: The DynamicsOutputPanel shows a gain-reduction meter. For frequency FX devices, there's no gain reduction. The output panel will show gain knob (DynamicsOutputPanel with GR meter showing 0 always, or StereoGainPanPanel). **Decision**: Use StereoGainPanPanel for output on frequency FX instead of DynamicsOutputPanel, since there's no gain reduction to meter. But the user specifically requested DynamicsInputPanel + DynamicsOutputPanel... 

Re-reading the requirements: "Use DynamicsInputPanel + DynamicsOutputPanel". The DynamicsOutputPanel shows GR meter + Gain knob. For frequency FX, the GR meter would just show 0 and the gain knob works. This is acceptable UX since the device simply has no gain reduction to display — the meter stays at zero. 

**Updated Decision**: Use DynamicsInputPanel + DynamicsOutputPanel as requested. The GR meter will remain at 0 for frequency FX devices. If this is undesirable, a future enhancement could modify the output panel to hide the GR meter for non-dynamics types.