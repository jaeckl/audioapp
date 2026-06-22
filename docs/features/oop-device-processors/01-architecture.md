# OOP Device Processors — Architecture Contract

This document describes the architectural decisions, design patterns, folder structure, and real-time safety constraints for refactoring `DeviceChainProcessor.cpp` into modular, OOP-style device processors.

## Architectural Goal

To isolate the DSP logic of each of the 22 device types into dedicated class-based or namespace-based processors.
The central `DeviceChainProcessor::processDeviceNode` acts solely as a high-level router/dispatcher.

## Design Patterns & Core Decisions

### 1. The Stateless Processor Pattern

To maintain absolute real-time safety and prevent any memory allocation/deallocation on the audio thread:
- **No state is held inside the Processor classes.** The processors do not contain member variables that change during rendering (like buffers, phase accumulators, filter states, etc.).
- **All runtime state is passed as arguments.** The parent caller (`processDeviceChain` and `processDeviceNode`) passes pointers to the preallocated runtime arrays (`DynamicsRuntime*`, `TimeBasedEffectRuntime*`, etc.) and the thread-local scratchpad (`DeviceChainScratch&`).
- Processors contain static methods or namespace-level functions to avoid the overhead of dynamic dispatch (v-tables) or object construction on the stack.
- This represents a **Stateless Processor Class Pattern** or **Lightweight Stack Adapter Pattern**. It provides the modular organization of OOP without the runtime/real-time safety risks of dynamic object allocation or v-table lookups on the audio thread.

### 2. Threading & Real-Time Safety Constraints

The refactored code will execute on the **audio thread** and must strictly adhere to the following rules:
1. **Zero Allocations**: Absolutely no calls to `new`, `delete`, `malloc`, `free`, `std::realloc`, or any operations that resize containers (`std::vector::push_back`, etc.).
2. **No Lock Operations**: Absolutely no calls to mutex locks, semaphores, or condition variables. Atomic stores and loads (with relaxed memory order, e.g., in `publishDynamicsMeters`) are allowed as they are lock-free.
3. **No I/O or Logging**: No console logging (`std::cout`, `printf`), disk I/O, or network sockets.
4. **No JSON Parsing or String Manipulation**: All parameters must remain pre-converted and pre-calculated or evaluated on the control thread or stack-evaluated. No string parsing or regex matching.
5. **No V-Table Overhead**: No virtual method calls or inheritance hierarchies used dynamically in the process loop. Direct, static dispatch via function templates or static class methods is used to maintain optimal compiler optimization (inlining, vectorization).

### 3. Folder & Directory Structure

To keep the codebase clean and avoid cluttering the parent directories, all newly created device files will be located in dedicated subdirectories:

- Headers: `engine_juce/include/audioapp/devices/processors/`
- Implementations: `engine_juce/src/devices/processors/`

Each device family will have its own header and source file:
1. **Utility & Gain**: `TrackGainProcessor.hpp` / `.cpp`
2. **Synthesizers**: `OscillatorProcessor.hpp`/`.cpp`, `SamplerProcessor.hpp`/`.cpp`, `SubtractiveSynthProcessor.hpp`/`.cpp`, `PhaseModSynthProcessor.hpp`/`.cpp`
3. **Percussion**: `KickProcessor.hpp`/`.cpp`, `SnareProcessor.hpp`/`.cpp`, `ClapProcessor.hpp`/`.cpp`, `CymbalProcessor.hpp`/`.cpp`, `CrashProcessor.hpp`/`.cpp`
4. **Dynamics**: `GateProcessor.hpp`/`.cpp`, `CompressorProcessor.hpp`/`.cpp`, `ExpanderProcessor.hpp`/`.cpp`, `LimiterProcessor.hpp`/`.cpp`
5. **Time-Based**: `DelayProcessor.hpp`/`.cpp`, `ReverbProcessor.hpp`/`.cpp`, `ChorusProcessor.hpp`/`.cpp`, `PhaserProcessor.hpp`/`.cpp`
6. **Frequency FX**: `FilterProcessor.hpp`/`.cpp`, `FourBandEqProcessor.hpp`/`.cpp`, `FrequencyShifterProcessor.hpp`/`.cpp`

### 4. Code Organization & SRP Rules

- Each processor file must be **focused and cohesive**.
- File sizes must be kept strictly below **250 lines of code** (target: 100-200 LOC per file), complying with `srp-and-file-size.mdc`.
- Each file must include only the necessary headers to perform its specific DSP task, reducing header-inclusion pollution.

### 5. Backward Compatibility & Verification

- No changes to public APIs like `processDeviceChain` in `DeviceChain.hpp`.
- Binary equivalence of the audio output must be preserved. We will use `tools/step_gate.py` to compile and link the `device_chain_test.exe` binary.
- We will use `tools/snapshot_test.py` to capture and compare baseline outputs to ensure zero-regression on a bitwise level.
