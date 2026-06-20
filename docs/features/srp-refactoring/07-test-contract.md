# Test Contract

## 7.1 Pre-Existing Tests (Must Continue to Pass)

These tests exercise serialization and round-trip behavior:
- `project_serialization_test.cpp`
- `project_engine_test.cpp`
- `project_archive_test.cpp`
- `device_chain_test.cpp`
- `device_registry_test.cpp`
- `device_types_test.cpp`

These tests exercise audio processing:
- `oscillator_output_test.cpp`
- `subtractive_synth_test.cpp`
- `kick_generator_test.cpp`
- `snare_generator_test.cpp`
- `clap_generator_test.cpp`
- `cymbal_generator_test.cpp`
- `crash_generator_test.cpp`
- `dynamics_processor_test.cpp`
- `gate_device_test.cpp`
- `bass_synth_test.cpp`
- `track_gain_test.cpp`
- `lfo_modulation_test.cpp`
- `lfo_polarity_test.cpp`
- `lfo_sync_bpm_test.cpp`
- `subtractive_lfo_filter_test.cpp`
- `effect_device_automation_test.cpp`
- `effect_device_modulation_test.cpp`
- `gain_pan_mod_auto_test.cpp`
- `modulation_e2e_test.cpp`
- `stacked_lfo_modulation_test.cpp`
- `automation_filter_sweep_test.cpp`
- `automation_sampler_filter_sweep_test.cpp`
- `common_param_modulation_test.cpp`
- `percussion_modulation_test.cpp`

## 7.2 New Tests Required

### WP1: "All devices round-trip" test

Add to `project_serialization_test.cpp`:
- Construct a `DeviceState` for each of the 14 device types with non-default values
- Serialize with `deviceToVar()`
- Deserialize with `deviceFromVar()`
- Assert all fields match

### WP2: Bit-exact output verification

Run existing audio generation tests (oscillator_output_test, subtractive_synth_test,
etc.) and verify they produce identical numeric output. If any test compares
rendered output, it must still pass.

For extra safety (optional): render a WAV before and after WP2 using
`EngineHost::renderOffline()`, compare with `/opt/audio-tools-venv/bin/python`:
```bash
/opt/audio-tools-venv/bin/python -c "
import numpy as np, soundfile as sf
before, sr = sf.read('before.wav')
after, _ = sf.read('after.wav')
print('Max diff:', np.max(np.abs(before - after)))
assert np.allclose(before, after, atol=1e-15), 'Output changed!'
"
```

### WP3: No new tests needed

Existing tests cover bridge response format through
`project_serialization_test.cpp` and `engine_smoke_test.cpp`.

### WP4: No new tests needed

LFO math coverage already exists in `lfo_modulation_test.cpp`,
`lfo_polarity_test.cpp`, and `lfo_sync_bpm_test.cpp`.

## 7.3 Flutter Tests

```bash
cd app_flutter && flutter test
```

Must pass after all WPs. The Dart side parses JSON snapshots; changes to C++
serialization must not break the JSON contract.

## 7.4 Build Verification

```bash
cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++
cmake --build build/engine --target audioapp_engine
```

Both commands must succeed after each WP commit.

## 7.5 Regression Detection

If any test fails after a WP, the WP is incorrect. Roll back and re-examine
before proceeding.
