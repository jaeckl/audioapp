# File Ownership

## Existing Files (Modify)

| File | Owner WP | Allowed Changes | Forbidden Changes |
|------|----------|----------------|------------------|
| `engine_juce/src/ProjectJson.cpp` | WP1, WP3 | Extract serialization to per-device files; remove bridge helpers | Any audio-thread code |
| `engine_juce/include/audioapp/ProjectJson.hpp` | WP3, WP4 | Remove bridge helper declarations; remove LFO math declarations | Any audio-thread code |
| `engine_juce/src/DeviceChain.cpp` | WP2 | Extract process switch cases to per-device functions | Project serialization, bridge helpers |
| `engine_juce/include/audioapp/DeviceChain.hpp` | WP2 | Add extracted process function declarations | DeviceState format, serialization helpers |
| `engine_juce/include/audioapp/DeviceState.hpp` | WP5 (future) | Decompose monolithic struct | Audio-thread params |
| `engine_juce/src/LfoEngine.cpp` | WP4 | None (already correct) | Any changes |
| `native_bridge/src/BridgeHost.cpp` | WP3 | Update `#include` from `ProjectJson.hpp` to `BridgeUtil.hpp` | Bridge command logic |
| `engine_juce/src/EngineHost_commands.cpp` | WP3 | Update `#include` from `ProjectJson.hpp` to `BridgeUtil.hpp` | Engine logic |

## New Files (Create)

| File | Owner WP | Contents |
|------|----------|----------|
| `engine_juce/include/audioapp/BridgeUtil.hpp` | WP3 | Bridge JSON helpers and argument parsers |
| `engine_juce/src/BridgeUtil.cpp` | WP3 | Implementation of bridge helpers |
| `engine_juce/include/audioapp/devices/serialization/OscillatorSerializer.hpp` | WP1 | `oscillatorToVar` / `oscillatorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/SamplerSerializer.hpp` | WP1 | `samplerToVar` / `samplerFromVar` |
| `engine_juce/include/audioapp/devices/serialization/SubtractiveSynthSerializer.hpp` | WP1 | `subtractiveSynthToVar` / `subtractiveSynthFromVar` |
| `engine_juce/include/audioapp/devices/serialization/BassSynthSerializer.hpp` | WP1 | `bassSynthToVar` / `bassSynthFromVar` |
| `engine_juce/include/audioapp/devices/serialization/KickGeneratorSerializer.hpp` | WP1 | `kickGeneratorToVar` / `kickGeneratorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/SnareGeneratorSerializer.hpp` | WP1 | `snareGeneratorToVar` / `snareGeneratorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/ClapGeneratorSerializer.hpp` | WP1 | `clapGeneratorToVar` / `clapGeneratorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/CymbalGeneratorSerializer.hpp` | WP1 | `cymbalGeneratorToVar` / `cymbalGeneratorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/CrashGeneratorSerializer.hpp` | WP1 | `crashGeneratorToVar` / `crashGeneratorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/GateSerializer.hpp` | WP1 | `gateToVar` / `gateFromVar` |
| `engine_juce/include/audioapp/devices/serialization/CompressorSerializer.hpp` | WP1 | `compressorToVar` / `compressorFromVar` |
| `engine_juce/include/audioapp/devices/serialization/ExpanderSerializer.hpp` | WP1 | `expanderToVar` / `expanderFromVar` |
| `engine_juce/include/audioapp/devices/serialization/LimiterSerializer.hpp` | WP1 | `limiterToVar` / `limiterFromVar` |
| `engine_juce/include/audioapp/devices/serialization/TrackGainSerializer.hpp` | WP1 | `trackGainToVar` / `trackGainFromVar` |
| `engine_juce/src/OscillatorProcess.cpp` | WP2 | `processOscillatorNode` |
| `engine_juce/src/SamplerProcess.cpp` | WP2 | `processSamplerNode` |
| `engine_juce/src/SubtractiveSynthProcess.cpp` | WP2 | `processSubtractiveSynthNode` |
| `engine_juce/src/BassSynthProcess.cpp` | WP2 | `processBassSynthNode` |
| `engine_juce/src/KickGeneratorProcess.cpp` | WP2 | `processKickGeneratorNode` |
| `engine_juce/src/SnareGeneratorProcess.cpp` | WP2 | `processSnareGeneratorNode` |
| `engine_juce/src/ClapGeneratorProcess.cpp` | WP2 | `processClapGeneratorNode` |
| `engine_juce/src/CymbalGeneratorProcess.cpp` | WP2 | `processCymbalGeneratorNode` |
| `engine_juce/src/CrashGeneratorProcess.cpp` | WP2 | `processCrashGeneratorNode` |
| `engine_juce/src/GateProcess.cpp` | WP2 | `processGateNode` |
| `engine_juce/src/CompressorProcess.cpp` | WP2 | `processCompressorNode` |
| `engine_juce/src/ExpanderProcess.cpp` | WP2 | `processExpanderNode` |
| `engine_juce/src/LimiterProcess.cpp` | WP2 | `processLimiterNode` |
| `engine_juce/src/TrackGainProcess.cpp` | WP2 | `processTrackGainNode` |

## Forbidden Cross-Package Edits

- WP1 implementation workers must NOT touch `DeviceChain.cpp`, any `*DeviceType.cpp`,
  any Instance struct, or any DSP generator file.
- WP2 implementation workers must NOT touch `ProjectJson.cpp`/`.hpp`, any
  `*DeviceType.cpp`, or any test file.
- WP3 implementation workers must NOT touch `DeviceChain.cpp`, any `*Process.cpp`,
  or any `*Serializer.hpp`.
- WP4 implementation workers only touch header files — no .cpp changes.

## Test Files (Read-Only)

All files in `engine_juce/tests/` are read-only during refactoring. Tests
must pass before and after each WP commit. If a test fails, the WP is
incorrect.
