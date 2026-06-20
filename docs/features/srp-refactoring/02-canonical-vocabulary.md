# Canonical Vocabulary

| Concept | Canonical Name | Type/File | Notes |
|---------|---------------|-----------|-------|
| Control thread | `control thread` | any `.cpp` outside audio callback | model mutations, serialization, bridge dispatch, snapshot building. Uses strings, vectors, heap, mutexes, JSON |
| Audio thread | `audio thread` | `DeviceChain.cpp`, DSP generators, `LfoEngine` | realtime-safe: no allocations, no strings, no locking, no JSON, no file I/O |
| Device type descriptor | `IDeviceType` | `devices/IDeviceType.hpp` | control-thread interface. One instance per built-in kind |
| Device slot | `DeviceSlot` | `devices/DeviceSlot.hpp` | control-thread model: id, gain, pan, bypassed, `DeviceInstance` variant |
| Device instance | `*Instance` (e.g. `OscillatorInstance`) | `devices/instances/*Instance.hpp` | control-thread per-device value struct. Minimal fields |
| Device state | `DeviceState` | `DeviceState.hpp` | **MONOLITHIC — target for decomposition.** Serializable DTO with ~100 fields |
| Device node playback | `DeviceNodePlayback` | `DeviceChain.hpp` | audio-thread read-only snapshot: kind, deviceId, bypassed, gain, pan, `DeviceVariantParams` |
| Device variant params | `DeviceVariantParams` | `DeviceChain.hpp` | `std::variant<14 *Params structs>` — DSP-only, no strings |
| DSP generator function | `SubtractiveSynth::mixSubtractiveMidiNotesBlock()`, etc. | `SubtractiveSynth.hpp`, `KickGenerator.hpp` etc. | free functions on audio thread |
| Project file | `ProjectFileData` | `ProjectJson.hpp` | control-thread serialization DTO |
| Project snapshot | `ProjectSnapshot` | `ProjectEngine.hpp` | control-thread snapshot DTO (includes all tracks, devices, LFOs, etc.) |
| Project engine | `ProjectEngine` | `ProjectEngine.hpp` | control-thread authoritative model |
| Track playback snapshot | `TrackPlaybackSnapshot` | `ProjectEngine.hpp` (private) | audio-thread fixed-size array built from model |
| Bridge host | `BridgeHost` | `bridge/BridgeHost.hpp` | platform-thread command dispatch. Delegates to `EngineHost` |
| Engine host | `EngineHost` | `EngineHost.hpp` | facade over `ProjectEngine` + `SampleBank` |
| Bridge utility functions | `jsonGetStringArg`, `buildBridgeOkWithSnapshot` etc. | **NEW: `BridgeUtil.hpp`** | extracted from `ProjectJson.hpp` |
| LFO evaluation | `lfoEvaluate`, `lfoSyncBeats`, `modulatorEvaluateSynced` etc. | `LfoEngine.cpp` / `LfoTypes.hpp` | declarations move to `LfoTypes.hpp` |
| Per-device serializer | `oscillatorToVar`, `oscillatorFromVar` etc. | **NEW: `devices/serialization/*Serializer.hpp`** | extracted from `ProjectJson.cpp` |
| Per-device process | `processOscillatorNode` etc. | **NEW: `src/*Process.cpp`** | extracted from `DeviceChain.cpp` switch |
| Automation playback | `AutomationClipPlayback` | `AutomationTypes.hpp` | audio-thread fixed-size array |
| Modulation edge playback | `ModulationEdgePlayback` | `AutomationTypes.hpp` | audio-thread fixed-size array |
| Device type string | `"simple_oscillator"`, `"simple_sampler"`, etc. | `DeviceTypeIds.hpp` | canonical string names used in JSON |
| Device node kind | `DeviceNodeKind::Oscillator`, etc. | `DeviceChain.hpp` | enum for audio-thread dispatch |
| Param kind | `ParamKind::Oscillator`, etc. | `AutomationTypes.hpp` | 4-bit tag for local param ID encoding |
