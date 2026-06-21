# Frequency FX Suite — Test Contract

## C++ Unit Tests

### Processing Tests (frequency_fx_test.cpp)

| Test | Input | Expected Behavior |
|------|-------|-------------------|
| `filter_silence_in_silence_out` | Zero buffer, any params | Output is all zero |
| `filter_lp_preserves_low_freq` | 100 Hz sine wave, LP@1000Hz | Output amplitude > 0.9× input |
| `filter_hp_attenuates_low_freq` | 100 Hz sine wave, HP@500Hz | Output amplitude < 0.1× input |
| `filter_bp_passes_center` | 500 Hz sine wave, BP@500Hz | Output amplitude > 0.9× input |
| `filter_notch_attenuates_center` | 500 Hz sine wave, Notch@500Hz | Output amplitude < 0.1× input |
| `filter_different_modes` | Same input, different modes | Outputs differ |
| `eq_all_bands_flat_identity` | All gains at 0 dB | Output ≈ input (within FP tolerance) |
| `eq_band1_boost` | Low shelf boost, 100 Hz input | Output > input amplitude |
| `eq_band4_cut` | High shelf cut, 10 kHz input | Output < input amplitude |
| `freq_shifter_center_no_shift` | Shift at 0 Hz | Output ≈ input |
| `freq_shifter_positive_shift` | Shift > 0 | Output spectrum shifted up |
| `freq_shifter_negative_shift` | Shift < 0 | Output spectrum shifted down |
| `ffx_no_crash_any_params` | Random params, any input | No crash, no NaN |

### Serialization Tests (device_slot_serialization_test.cpp)

| Test | Behavior |
|------|----------|
| `filter_slot_roundtrip` | Create default slot → serialize to JSON → deserialize → compare fields |
| `filter_slot_roundtrip_modified` | Set all params → serialize → deserialize → all fields match |
| `four_band_eq_slot_roundtrip` | Same pattern |
| `frequency_shifter_slot_roundtrip` | Same pattern |

### Device Type Tests (device_types_test.cpp)

| Test | Behavior |
|------|----------|
| `filter_type_id` | typeId() returns "filter" |
| `four_band_eq_type_id` | typeId() returns "four_band_eq" |
| `frequency_shifter_type_id` | typeId() returns "frequency_shifter" |
| `filter_set_parameter_handled` | All valid param IDs return handled=true |
| `filter_set_parameter_unhandled` | Unknown param ID returns handled=false |
| `filter_set_parameter_clamp` | Values >1.0 are clamped to 1.0, values <0 clamped to 0 |
| `filter_build_playback_node_kind` | buildPlaybackNode sets out.kind = DeviceNodeKind::Filter |
| `filter_modulatable_params` | Contains expected param IDs |
| `filter_live_instrument` | buildLiveInstrument returns false |

### Device Chain Tests (device_chain_test.cpp)

| Test | Behavior |
|------|----------|
| `device_chain_with_filter` | Chain with filter device processes without crash |
| `device_chain_with_eq` | Chain with EQ device processes without crash |
| `device_chain_with_shifter` | Chain with shifter device processes without crash |
| `device_chain_filter_does_not_destroy_audio` | Audio passes through filter (may be modified, but not destroyed) |

## Flutter Widget Tests

| Test | File | Behavior |
|------|------|----------|
| `FilterPanel renders` | frequency_fx_test.dart | Panel builds, knobs are present |
| `FourBandEqPanel renders` | frequency_fx_test.dart | Panel builds, knobs are present |
| `FreqShifterPanel renders` | frequency_fx_test.dart | Panel builds, knob is present |
| `FilterPreview paints` | filter_preview_test.dart | CustomPainter renders without error |
| `FourBandEqPreview paints` | eq_preview_test.dart | CustomPainter renders without error |

## Manual Verification Steps

1. Build engine on Linux: `cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ && cmake --build build/engine`
2. Build engine tests: `cmake --build build/engine --target audioapp_juce_tests` (if linkable; otherwise test individual files)
3. Run Flutter tests: `cd app_flutter && flutter test`
4. Run Flutter analyze: `cd app_flutter && flutter analyze` (0 errors expected)
5. On-device verification: insert each new device type, verify UI renders, knobs work, sound processes