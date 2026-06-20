# File Ownership

| File | Owner Package | Allowed Changes | Forbidden Changes |
|------|--------------|----------------|------------------|
| `engine_juce/src/AutomationPlayback.cpp` | P1: Debug trace | Add temporary logging for `paramIdFromString`, `applyAutomationValue`; no logic changes | Changing param mappings, enum values |
| `engine_juce/src/DeviceChain.cpp` | P2: Modulation fix | Add debug trace in `applyModulation(SubtractiveSynthParams)` and `processDeviceChain` SubtractiveSynth section | Changing routing logic, enum dispatch |
| `engine_juce/src/SubtractiveSynth.cpp` | P2: Modulation fix | Add debug trace in `applySubtractiveModulation` and `mixSubtractiveMidiNotesBlock` per-frame loop | Changing synth DSP logic |
| `engine_juce/src/ProjectEngine.cpp` | P1: Debug trace | Add debug trace in `rebuildTrackPlaybackLocked` for localParamId resolution; check amount values | Changing snapshot build logic |
| `engine_juce/src/modulation/ModulationGraph.cpp` | P3: Amount validation | Validate `assignModulation` amount values | Changing modulation graph architecture |
| `engine_juce/include/audioapp/AutomationTypes.hpp` | None | Read-only | No changes without explicit instruction |
| `engine_juce/include/audioapp/SubtractiveSynth.hpp` | None | Read-only | No changes without explicit instruction |
| `engine_juce/include/audioapp/DeviceChain.hpp` | None | Read-only | No changes without explicit instruction |
| `engine_juce/include/audioapp/AutomationPlayback.hpp` | None | Read-only | No changes without explicit instruction |
| `engine_juce/include/audioapp/devices/SubtractiveSynthDeviceType.hpp` | None | Read-only | No changes without explicit instruction |
| `engine_juce/src/devices/SubtractiveSynthDeviceType.cpp` | None | Read-only | No changes without explicit instruction |
| `app_flutter/lib/bridge/` | P4: Flutter bridge | Bridge layer validation of amount values | Changing param ID strings |
| `app_flutter/lib/features/device_strip/` | P4: Flutter UI | Ensure LFO modulation depth knob sends non-zero amounts | Changing param names |
| `engine_juce/tests/` | P5: Tests | Add automation + modulation integration tests | No production code changes |