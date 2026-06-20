# Canonical Vocabulary

## Test IDs

| Concept | Canonical name | File | Notes |
| ------- | -------------- | ---- | ----- |
| Stacked LFO modulation | US-16-01 | `engine_juce/tests/stacked_lfo_modulation_test.cpp` | Two LFOs on same param |
| Effect device modulation | US-16-02 | `engine_juce/tests/effect_device_modulation_test.cpp` | Compressor/Gate/Expander/Limiter |
| Common gain/pan modulation | US-16-03 | `engine_juce/tests/common_param_modulation_test.cpp` | LFO → gain, LFO → pan |
| Percussion generator modulation | US-16-04 | `engine_juce/tests/percussion_modulation_test.cpp` | Kick/Snare/Clap/Crash/Cymbal generator params |
| ADSR envelope modulator | US-16-05 | `engine_juce/tests/adsr_modulator_test.cpp` | Envelope modulator on filter |
| LFO polarity test | US-16-06 | `engine_juce/tests/lfo_polarity_test.cpp` | Unipolar vs bipolar |
| LFO sync-to-BPM | US-16-07 | `engine_juce/tests/lfo_sync_bpm_test.cpp` | Sync division in audio path |
| Combined mod+auto on gain/pan | US-16-08 | `engine_juce/tests/gain_pan_mod_auto_test.cpp` | Modulation + automation together |
| Effect device automation | US-16-09 | `engine_juce/tests/effect_device_automation_test.cpp` | Compressor threshold, Gate range, etc. |
| Flutter LFO bridge CRUD | US-16-10 | `app_flutter/test/lfo_bridge_test.dart` | createLfo/removeLfo/updateLfoParam/assignModulation/removeModulation |
| Flutter modulation widget tests | US-16-11 | `app_flutter/test/modulation_widget_test.dart` | ModulationGrid, ModulationStrip, LfoPropertiesPanel, ModulatableSpinnerShell |
| Flutter snapshot JSON parsing | US-16-12 | `app_flutter/test/lfo_snapshot_parsing_test.dart` | LfoSnapshot/ModulationEdgeSnapshot fromMap |
| Flutter modulation persistence | US-16-13 | `app_flutter/test/modulation_persistence_test.dart` | Save/load with lfos and modEdges |

## Engine concepts

| Concept | Canonical name | Type/File | Notes |
| ------- | -------------- | --------- | ----- |
| Engine host | `audioapp::EngineHost` | `engine_juce/include/audioapp/EngineHost.hpp` | Test entry point |
| Offline render | `EngineHost::renderOffline(lengthBeats, sampleRate)` | `EngineHost.hpp` | Returns `std::vector<float>` mono |
| Create LFO | `EngineHost::createLfo(modulatorType)` | `EngineHost.hpp` | Returns int LFO id |
| Remove LFO | `EngineHost::removeLfo(lfoId)` | `EngineHost.hpp` | Returns bool |
| Update LFO param | `EngineHost::updateLfoParam(lfoId, param, value)` | `EngineHost.hpp` | Returns bool |
| Assign modulation | `EngineHost::assignModulation(lfoId, deviceId, paramId, amount)` | `EngineHost.hpp` | Returns bool |
| Remove modulation | `EngineHost::removeModulation(lfoId, paramId)` | `EngineHost.hpp` | Returns bool |
| Create automation clip | `EngineHost::createAutomationClip(trackId, startBeat, lengthBeats)` | `EngineHost.hpp` | Returns clip id string |
| Assign automation target | `EngineHost::assignAutomationTarget(clipId, deviceId, paramId)` | `EngineHost.hpp` | Returns bool |
| Set automation points | `EngineHost::setAutomationPoints(clipId, points)` | `EngineHost.hpp` | Returns bool |
| Project JSON | `EngineHost::getProjectFileJson()` | `EngineHost.hpp` | Returns JSON string |
| Load project JSON | `EngineHost::loadProjectFileJson(json)` | `EngineHost.hpp` | Returns bool |
| Set device parameter | `EngineHost::setDeviceParameter(deviceId, paramId, value)` | `EngineHost.hpp` | Returns bool |
| rms | `rms(samples, start, count)` | inline in tests | Audio analysis |
| highFrequencyEnergy | `highFrequencyEnergy(samples, start, count)` | inline in tests | Audio analysis |
| filterSweepDetected | `filterSweepDetected(block, windows, minRatio)` | inline in tests | Audio analysis |

## Flutter concepts

| Concept | Canonical name | File | Notes |
| ------- | -------------- | ---- | ----- |
| Engine bridge | `EngineBridge` | `app_flutter/lib/bridge/engine_bridge.dart` | Flutter → C++ |
| Project snapshot | `ProjectSnapshot` | `app_flutter/lib/bridge/project_snapshot.dart` | Parsed snapshot |
| Lfo snapshot | `LfoSnapshot` | `app_flutter/lib/bridge/project_snapshot.dart` | LFO state |
| Modulation edge snapshot | `ModulationEdgeSnapshot` | `app_flutter/lib/bridge/project_snapshot.dart` | Modulation edge state |
| Modulation grid | `ModulationGrid` | `app_flutter/lib/features/device_strip/modulation_grid.dart` | Widget |
| Modulation strip | `ModulationStrip` | `app_flutter/lib/features/device_strip/modulation_strip.dart` | Widget |
| LFO properties panel | `LfoPropertiesPanel` | `app_flutter/lib/features/device_strip/lfo_properties_panel.dart` | Widget |
| Modulatable spinner shell | `ModulatableSpinnerShell` | `app_flutter/lib/features/device_strip/modulatable_spinner_shell.dart` | Widget |

## Device types (engine)

| Device type string | `DeviceNodeKind` | Param enum |
| ----------------- | ---------------- | ---------- |
| `"subtractive_synth"` | `SubtractiveSynth` | `SubtractiveParam` |
| `"simple_oscillator"` | `Oscillator` | `OscillatorParam` |
| `"simple_sampler"` | `Sampler` | `SamplerParam` |
| `"kick_generator"` | `KickGenerator` | `KickParam` |
| `"snare_generator"` | `SnareGenerator` | `SnareParam` |
| `"clap_generator"` | `ClapGenerator` | `ClapParam` |
| `"cymbal_generator"` | `CymbalGenerator` | `CymbalParam` |
| `"crash_generator"` | `CrashGenerator` | `CrashParam` |
| `"compressor"` | `Compressor` | `CompressorParam` |
| `"gate"` | `Gate` | `GateParam` |
| `"expander"` | `Expander` | `ExpanderParam` |
| `"limiter"` | `Limiter` | `LimiterParam` |
| `"track_gain"` | `TrackGain` | (CommonParam only) |

## Common parameter strings

- `"gain"` — maps to `CommonParam::Gain`
- `"pan"` — maps to `CommonParam::Pan`