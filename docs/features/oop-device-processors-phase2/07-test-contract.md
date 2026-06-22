# OOP Device Processors Phase 2 — Test Contract

## Testing Strategy

Phase 2 is a pure refactoring within the existing processor files — the DSP math is unchanged. All existing tests must pass with **byte-identical output** after the conversion.

## Test Levels

### Level 1: Compilation Gate

After each package:
```bash
cmake --build build/engine --target audioapp_engine
```

All packages must compile cleanly. P0 adds new files to `CMakeLists.txt`; P1-P6 touch only their assigned files. P7 may require linking the full engine.

### Level 2: Existing Unit Tests

```bash
cmake --build build/engine --target audioapp_juce_tests
./build/engine/audioapp_juce_tests
```

All ~52 tests in `engine_juce/tests/` must pass. Particularly critical:

| Test file | Covers |
|-----------|--------|
| `device_chain_test.cpp` | Full chain processing, all 22 device types |
| `oscillator_output_test.cpp` | Oscillator waveform + phase continuity |
| `sampler_midi_playback_test.cpp` | Sampler with filter states |
| `subtractive_synth_test.cpp` | Subtractive synth runtime |
| `phase_mod_synth_test.cpp` | Phase mod synth runtime |
| `dynamics_processor_test.cpp` | All 4 dynamics types |
| `effect_delay_test.cpp` | Delay with ring buffer |
| `effect_reverb_test.cpp` | Reverb |
| `effect_chorus_test.cpp` | Chorus |
| `effect_phaser_test.cpp` | Phaser |
| `frequency_fx_test.cpp` | Filter, EQ, Frequency Shifter |
| `gate_device_test.cpp` | Gate |
| `kick_generator_test.cpp` | Kick |
| `snare_generator_test.cpp` | Snare |
| `clap_generator_test.cpp` | Clap |
| `cymbal_generator_test.cpp` | Cymbal |
| `crash_generator_test.cpp` | Crash |
| `track_gain_test.cpp` | TrackGain |
| `gain_pan_mod_auto_test.cpp` | Gain/pan modulation |
| `project_engine_test.cpp` | Full engine integration |

### Level 3: Snapshot Equivalence

After P7 (full integration), capture a snapshot and compare to Phase 1 baseline:

```bash
# Capture baseline (from Phase 1, before any Phase 2 changes)
python tools/snapshot_test.py docs/features/oop-device-processors-phase2/baseline.txt

# After Phase 2 complete, capture new snapshot
python tools/snapshot_test.py docs/features/oop-device-processors-phase2/final.txt

# Compare — must show zero differences
powershell Compare-Object (Get-Content baseline.txt) (Get-Content final.txt)
```

### Level 4: Memory Safety Verification

- Grep for `new`, `delete`, `malloc`, `free`, `std::vector` inside `process()` methods — must be zero hits.
- Grep for `std::mutex`, `std::lock_guard`, `pthread_mutex` in processor source files — must be zero hits.
- Verify that `TimeBasedEffectRuntime` no longer appears as a heap allocator.

## Test File Update Rules

- **No new test files needed** for Phase 2 — existing tests exercise all 22 processor types.
- If a test directly instantiates a processor class (e.g., `FilterProcessor::process(...)`), its call signature must be updated to match the new OOP form.
- Most tests call `processDeviceChain(...)` or `processDeviceNode(...)` — these are backward-compatible via the thin wrapper.

## Regression Detection

If any test fails after a package:

1. Check whether the package's processors produce bit-identical intermediate output
2. Check whether gain/pan ordering changed (orchestrator applies perFrameGain after process())
3. Check whether the processor's `initParams()` stores the correct initial state
4. Check whether ring buffer arena allocation succeeds (time-based processors)

## Test Code for Individual Processor Verification

For manual verification of a single processor:

```cpp
// Test a FilterProcessor in isolation:
#include "audioapp/devices/processors/DeviceProcessor.hpp"
#include "audioapp/devices/processors/FilterProcessor.hpp"
#include "audioapp/devices/processors/AudioBlock.hpp"
#include "audioapp/devices/processors/ProcessContext.hpp"

void testFilterOop() {
    FilterProcessor fp;
    float left[64] = {0.5f};
    float right[64] = {0.5f};
    AudioBlock block{left, right, 64};
    DeviceChainScratch scratch;
    ProcessContext ctx(scratch);
    ctx.sampleRate = 48000.0;
    ctx.deviceIndex = 0;

    // Initialize params
    DeviceVariantParams params = FilterParams{1000.0f, 0.707f, 0};
    fp.initParams(params);
    ctx.modulatedParams = &params;

    // Process
    fp.process(block, ctx);

    // Verify output
    // (compare to Phase 1 FilterProcessor::process() output)
}
```