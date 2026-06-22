# OOP Device Processors — Vertical Work Packages

This document defines the 6 vertical work packages needed to refactor `DeviceChainProcessor.cpp` into clean OOP-style processors.

## Package 1: Base Setup & TrackGain (Parallel-Safe)

- **Behavior**: Set up folder structures, create base directory, update CMake build target lists, extract simple local utilities (such as `stereoBlockPeak`, `publishDynamicsMeters`, etc.), and implement `TrackGainProcessor`.
- **Files Assigned**: 
  - `engine_juce/CMakeLists.txt`
  - `engine_juce/include/audioapp/devices/processors/TrackGainProcessor.hpp`
  - `engine_juce/src/devices/processors/TrackGainProcessor.cpp`
  - `engine_juce/include/audioapp/DeviceChainProcessor.hpp`
  - `engine_juce/src/DeviceChainProcessor.cpp` (Utility block and `TrackGain` case only)
- **Forbidden Files**: All other processor files.
- **Acceptance Criteria**:
  - Code builds without errors using `tools/step_gate.py`.
  - `TrackGain` works correctly, and baseline tests pass.
- **Parallel-Safe**: Yes, first package to execute.

---

## Package 2: Synthesizers & Generators (Parallel-Safe)

- **Behavior**: Migrate `Oscillator`, `Sampler`, `SubtractiveSynth`, `BassSynth`, and `PhaseModSynth` case logic to their respective modular files.
- **Files Assigned**:
  - `engine_juce/include/audioapp/devices/processors/OscillatorProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/SamplerProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/SubtractiveSynthProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/PhaseModSynthProcessor.hpp` / `.cpp`
  - `engine_juce/src/DeviceChainProcessor.cpp` (switch statements for synts)
- **Forbidden Files**: All other processor files.
- **Acceptance Criteria**:
  - All synth voices render correctly and sustain envelope releases as expected.
  - Passes baseline compilation and runs tests.
- **Parallel-Safe**: Yes.

---

## Package 3: Percussion Generators (Parallel-Safe)

- **Behavior**: Migrate `KickGenerator`, `SnareGenerator`, `ClapGenerator`, `CymbalGenerator`, and `CrashGenerator` case logic to their respective modular files.
- **Files Assigned**:
  - `engine_juce/include/audioapp/devices/processors/KickProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/SnareProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/ClapProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/CymbalProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/CrashProcessor.hpp` / `.cpp`
  - `engine_juce/src/DeviceChainProcessor.cpp` (switch statements for percussion)
- **Forbidden Files**: All other processor files.
- **Acceptance Criteria**:
  - Drums and noise-generators render cleanly, and stereophonic drum sounds (Cymbal/Crash) output correct left-to-right panning balances.
- **Parallel-Safe**: Yes.

---

## Package 4: Dynamics Effects (Parallel-Safe)

- **Behavior**: Migrate `Gate`, `Compressor`, `Expander`, and `Limiter` case logic to their respective modular files.
- **Files Assigned**:
  - `engine_juce/include/audioapp/devices/processors/GateProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/CompressorProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/ExpanderProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/LimiterProcessor.hpp` / `.cpp`
  - `engine_juce/src/DeviceChainProcessor.cpp` (switch statements for dynamics)
- **Forbidden Files**: All other processor files.
- **Acceptance Criteria**:
  - Gate, Compressor, Expander, and Limiter correctly evaluate gain reduction and publish updates to the meters slot arrays using relaxed atomic writes.
- **Parallel-Safe**: Yes.

---

## Package 5: Time-Based Effects (Parallel-Safe)

- **Behavior**: Migrate `Delay`, `Reverb`, `Chorus`, and `Phaser` case logic to their respective modular files.
- **Files Assigned**:
  - `engine_juce/include/audioapp/devices/processors/DelayProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/ReverbProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/ChorusProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/PhaserProcessor.hpp` / `.cpp`
  - `engine_juce/src/DeviceChainProcessor.cpp` (switch statements for effects)
- **Forbidden Files**: All other processor files.
- **Acceptance Criteria**:
  - Audio delays and reverberations decay naturally without introducing clicks or index overflows on the circular buffers.
- **Parallel-Safe**: Yes.

---

## Package 6: Frequency FX (Parallel-Safe)

- **Behavior**: Migrate `Filter`, `FourBandEq`, and `FrequencyShifter` case logic to their respective modular files.
- **Files Assigned**:
  - `engine_juce/include/audioapp/devices/processors/FilterProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/FourBandEqProcessor.hpp` / `.cpp`
  - `engine_juce/include/audioapp/devices/processors/FrequencyShifterProcessor.hpp` / `.cpp`
  - `engine_juce/src/DeviceChainProcessor.cpp` (switch statements for frequency FX)
- **Forbidden Files**: All other processor files.
- **Acceptance Criteria**:
  - Audio spectrum shifts and filter coefficients modulate cleanly without introducing phase distortion or audio dropouts.
- **Parallel-Safe**: Yes.

---

## Worker Instructions

Implementation workers must:
- Obey canonical names and signatures specified in the contracts.
- Limit edits exclusively to assigned files.
- Ensure zero allocations on the audio thread.
- Halt and ask questions if any contract details appear ambiguous.
- Run `tools/step_gate.py` immediately after making modifications.
