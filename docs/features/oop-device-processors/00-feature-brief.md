# OOP Device Processors — Feature Brief

## Summary

Refactor the monolithic 720-line `DeviceChainProcessor.cpp` file—which contains a massive switch-case statement handling all 22 device types, manual sub-blocking, parameter conversions, and custom local variables—into a clean, modular, and class-based/OOP processing architecture (e.g. `FilterProcessor`, `DelayProcessor`, `OscillatorProcessor`, etc.) while strictly obeying real-time safety constraints, preserving zero-allocation guarantees on the audio thread, and maintaining absolute backward compatibility (producing byte-identical rendering output).

Instead of executing giant switch branches directly, `processDeviceNode` in `DeviceChainProcessor.cpp` will act as a lightweight, high-level dispatcher that delegates to device-specific processors (e.g., `audioapp::DelayProcessor::process(...)`).

## User Story
As an audio developer, I want a modular, extensible, and clean codebase for audio device DSP processing so that I can easily maintain existing devices, debug DSP bugs in isolation, and add new audio effect or synthesizer device types without touching or enlarging a giant, monolithic switch-case file.

## Business Value
- **Scalability**: Adding new device processors (such as the PhaseModSynth or BassSynth) will no longer expand a massive central file. This prevents compile-time bottlenecks and merge conflicts.
- **Maintainability**: Lowers the file size of `DeviceChainProcessor.cpp` from 720 LOC to a lightweight dispatcher (expected ~150-200 LOC), satisfying the codebase srp size rules (<300 LOC hard trigger).
- **Testability**: Individual device processors can be unit-tested in isolation without dragging in the entire device chain environment.
- **Robustness**: Reduces cognitive load during debugging. If there is a bug in the delay DSP, we look in `DelayProcessor.cpp`, not in a massive 720-line file.

## Current Problems in `DeviceChainProcessor.cpp`
1. **SRP Violation**: It acts as the DSP processor for 22 different devices, containing code for envelope tracking, sine wave generation, biquad filtering, allpass filtering, delays, gain calculations, and voice mixers.
2. **Hard Review Trigger Exceeded**: At 720 LOC, it far exceeds the 300 LOC hard review limit specified in `srp-and-file-size.mdc`.
3. **High Coupling**: Adding or modifying a parameter for a single device requires modifying `DeviceChainProcessor.cpp`.
4. **Local Variable Shadowing/Mixing**: The massive switch-case uses separate local blocks, making it easy to introduce variable definition conflicts or accidental state pollution.

## Success Metrics
- **Size Compliance**: `DeviceChainProcessor.cpp` is reduced to <250 LOC.
- **Individual Files**: Each newly created device processor file is <250 LOC (well below the 300 LOC hard trigger).
- **Behavioral Identity**: Passes the existing baseline tests and `snapshot_test.py` with byte-identical rendering outputs.
- **Real-Time Safety**: Zero allocations (`new`, `malloc`, `std::vector` resize, etc.) or lock operations in any of the processing functions.
- **Backward Compatibility**: No changes to public APIs like `processDeviceChain` or the overall performance profiles.
