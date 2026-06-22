# OOP Device Processors — File Ownership

This document details the exact file-level modifications, file creations, and deletions associated with refactoring `DeviceChainProcessor.cpp` into modular processors.

## File Ownership Table

Each file is assigned to specific work packages. Subagents must only modify files assigned to their work packages.

| File / Path | Action | Owner Work Package | Allowed Changes | Forbidden Changes |
| :--- | :--- | :--- | :--- | :--- |
| `engine_juce/include/audioapp/DeviceChainProcessor.hpp` | Modify | Package 1 | Adding `#include` statements for the modular headers. | Modifying `processDeviceNode` or `applyCommonGainPanLfo` public signatures. |
| `engine_juce/src/DeviceChainProcessor.cpp` | Modify | All Packages (1-6) | Replacing the giant switch case with static function calls to the modular processors, and pruning local helpers. | Removing common gain/pan LFO processing or meter validation. |
| `engine_juce/CMakeLists.txt` | Modify | Package 1 | Adding files to the compilation list or adding source globs if necessary. | Modifying standard compile definitions or compiler flags. |
| `engine_juce/include/audioapp/devices/processors/TrackGainProcessor.hpp` | Create | Package 1 | Defining the `TrackGainProcessor` class. | None |
| `engine_juce/src/devices/processors/TrackGainProcessor.cpp` | Create | Package 1 | Implementing the `TrackGainProcessor` class. | None |
| `engine_juce/include/audioapp/devices/processors/OscillatorProcessor.hpp` | Create | Package 2 | Defining the `OscillatorProcessor` class. | None |
| `engine_juce/src/devices/processors/OscillatorProcessor.cpp` | Create | Package 2 | Implementing the `OscillatorProcessor` class. | None |
| `engine_juce/include/audioapp/devices/processors/SamplerProcessor.hpp` | Create | Package 2 | Defining the `SamplerProcessor` class. | None |
| `engine_juce/src/devices/processors/SamplerProcessor.cpp` | Create | Package 2 | Implementing the `SamplerProcessor` class. | None |
| `engine_juce/include/audioapp/devices/processors/SubtractiveSynthProcessor.hpp` | Create | Package 2 | Defining `SubtractiveSynthProcessor` and `BassSynthProcessor`. | None |
| `engine_juce/src/devices/processors/SubtractiveSynthProcessor.cpp` | Create | Package 2 | Implementing `SubtractiveSynthProcessor` and `BassSynthProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/PhaseModSynthProcessor.hpp`| Create | Package 2 | Defining `PhaseModSynthProcessor`. | None |
| `engine_juce/src/devices/processors/PhaseModSynthProcessor.cpp`| Create | Package 2 | Implementing `PhaseModSynthProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/KickProcessor.hpp` | Create | Package 3 | Defining `KickProcessor`. | None |
| `engine_juce/src/devices/processors/KickProcessor.cpp` | Create | Package 3 | Implementing `KickProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/SnareProcessor.hpp` | Create | Package 3 | Defining `SnareProcessor`. | None |
| `engine_juce/src/devices/processors/SnareProcessor.cpp` | Create | Package 3 | Implementing `SnareProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/ClapProcessor.hpp` | Create | Package 3 | Defining `ClapProcessor`. | None |
| `engine_juce/src/devices/processors/ClapProcessor.cpp` | Create | Package 3 | Implementing `ClapProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/CymbalProcessor.hpp` | Create | Package 3 | Defining `CymbalProcessor`. | None |
| `engine_juce/src/devices/processors/CymbalProcessor.cpp` | Create | Package 3 | Implementing `CymbalProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/CrashProcessor.hpp` | Create | Package 3 | Defining `CrashProcessor`. | None |
| `engine_juce/src/devices/processors/CrashProcessor.cpp` | Create | Package 3 | Implementing `CrashProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/GateProcessor.hpp` | Create | Package 4 | Defining `GateProcessor`. | None |
| `engine_juce/src/devices/processors/GateProcessor.cpp` | Create | Package 4 | Implementing `GateProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/CompressorProcessor.hpp` | Create | Package 4 | Defining `CompressorProcessor`. | None |
| `engine_juce/src/devices/processors/CompressorProcessor.cpp` | Create | Package 4 | Implementing `CompressorProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/ExpanderProcessor.hpp` | Create | Package 4 | Defining `ExpanderProcessor`. | None |
| `engine_juce/src/devices/processors/ExpanderProcessor.cpp` | Create | Package 4 | Implementing `ExpanderProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/LimiterProcessor.hpp` | Create | Package 4 | Defining `LimiterProcessor`. | None |
| `engine_juce/src/devices/processors/LimiterProcessor.cpp` | Create | Package 4 | Implementing `LimiterProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/DelayProcessor.hpp` | Create | Package 5 | Defining `DelayProcessor`. | None |
| `engine_juce/src/devices/processors/DelayProcessor.cpp` | Create | Package 5 | Implementing `DelayProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/ReverbProcessor.hpp` | Create | Package 5 | Defining `ReverbProcessor`. | None |
| `engine_juce/src/devices/processors/ReverbProcessor.cpp` | Create | Package 5 | Implementing `ReverbProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/ChorusProcessor.hpp` | Create | Package 5 | Defining `ChorusProcessor`. | None |
| `engine_juce/src/devices/processors/ChorusProcessor.cpp` | Create | Package 5 | Implementing `ChorusProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/PhaserProcessor.hpp` | Create | Package 5 | Defining `PhaserProcessor`. | None |
| `engine_juce/src/devices/processors/PhaserProcessor.cpp` | Create | Package 5 | Implementing `PhaserProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/FilterProcessor.hpp` | Create | Package 6 | Defining `FilterProcessor`. | None |
| `engine_juce/src/devices/processors/FilterProcessor.cpp` | Create | Package 6 | Implementing `FilterProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/FourBandEqProcessor.hpp` | Create | Package 6 | Defining `FourBandEqProcessor`. | None |
| `engine_juce/src/devices/processors/FourBandEqProcessor.cpp` | Create | Package 6 | Implementing `FourBandEqProcessor`. | None |
| `engine_juce/include/audioapp/devices/processors/FrequencyShifterProcessor.hpp`| Create | Package 6 | Defining `FrequencyShifterProcessor`. | None |
| `engine_juce/src/devices/processors/FrequencyShifterProcessor.cpp`| Create | Package 6 | Implementing `FrequencyShifterProcessor`. | None |

## Strict Parallel Edit Controls

To prevent git conflicts while running subagents in parallel:
- Multiple subagents are allowed to add their files simultaneously since each work package is fully mapped to separate processor files under `processors/`.
- Modification of `DeviceChainProcessor.cpp` is a potential point of conflict. Therefore, each subagent must only edit the `switch` block statement segment corresponding to their own devices. Alternatively, packages can be run sequentially or fully integrated by the orchestrator at the end to completely avoid parallel conflict inside `DeviceChainProcessor.cpp`.
- To enable true parallel worker isolation, **the orchestrator will prepare stub classes first** for all 22 devices (empty classes with dummy implementations), or workers will be dispatched in a clear integration order.
