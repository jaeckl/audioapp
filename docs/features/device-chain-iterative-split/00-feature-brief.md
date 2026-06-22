# DeviceChain Iterative Split — Feature Brief

## Goal

Refactor `engine_juce/src/DeviceChain.cpp` (1261 LOC monolith) and the
`DeviceChainScratch` block plus automation/modulation helpers currently in its
anonymous namespace into 4 small, SRP-focused TUs, delivered as 4 independently
compilable, independently testable steps.

Each step is a **pure refactor** that ends with:

1. `cmake --build build/engine --target audioapp_engine` succeeding.
2. `engine_juce/tests/device_chain_test.cpp` (and all other existing tests that
   call `processDeviceChain`) producing **byte-identical** output to HEAD.

The end state has `DeviceChain.cpp` reduced to ≤50 LOC of orchestration glue and
5 focused files carrying the moved logic.

## Non-goals (binding)

- **Zero behavior change.** No DSP math changes, no clamping ranges change, no
  control-flow reorder. The audio output of any test must match HEAD bit-for-bit.
- **Zero public API change.** `audioapp::processDeviceChain(...)` keeps its
  exact signature in `engine_juce/include/audioapp/DeviceChain.hpp` so every
  existing caller (BridgeHost, EngineHost, tests) compiles and links unchanged.
- **No new features.** No new device kinds, no new modulation sources, no new
  automation types.
- **No `inline` definitions in new headers.** No `using namespace` in headers.
- **No `static` mutable state outside `thread_local`.** Plain `static` in a
  header causes data races across multiple AudioThreads; the existing
  `thread_local DeviceChainScratch gScratch` is fine and is preserved as the
  owner of the scratch instance (it lives in exactly one `.cpp`).
- **No `new`/`malloc`/STL container construction on the audio thread.** Only
  POD struct member access; the scratch is a value-typed stack/global.
- **No reduction in real-time safety.** Every moved function preserves its
  `noexcept` and avoids heap allocation, locks, and blocking I/O.
- **No redefinition of existing symbols.** `evaluateAutomationEnvelope`,
  `nodeHasDspAutomation`, `ModulationEdgePlayback`, `AutomationClipPlayback`,
  `kEncodedCommonGain`, `kEncodedCommonPan` stay where they live
  (`AutomationTypes.hpp` / `AutomationPlayback.hpp`).

## Existing code to reuse (must not be moved or renamed)

| Header / TU                         | Symbols we depend on                                                     |
|-------------------------------------|--------------------------------------------------------------------------|
| `audioapp/AutomationTypes.hpp`      | `ModulationEdgePlayback`, `AutomationClipPlayback`, `kEncodedCommonGain`, `kEncodedCommonPan`, `AutomationPointPlayback` |
| `audioapp/AutomationPlayback.hpp`   | `evaluateAutomationEnvelope`, `nodeHasDspAutomation`, `applyDspAutomationAtBeat`, `applyAutomationValue`, `paramIdFromString`, `paramDescriptorsForKind` |
| `audioapp/DeviceChain.hpp`          | `processDeviceChain` (signature owner), `DeviceNodePlayback`, `DeviceNodeKind`, `MidiPlaybackNote`, all `*Params` structs, `DeviceMeterAtomic`, `*Runtime` types, `kMaxInstrumentRegions`, `kInstrumentOutputGain` |
| `audioapp/SamplePlayback.hpp`       | `addSineBlock`, `mixSamplerMidiNotesBlock`, `SamplerMidiNoteRegion`, `SamplerInstrumentPlayback`, `BiquadState` |
| `audioapp/SubtractiveSynth.hpp`     | `mixSubtractiveMidiNotesBlock`, `SubtractiveMidiNoteRegion`, `SubtractiveSynthRuntime`, `SubtractiveSynthParams`, `SubtractiveParam`, `unpackParamId` |
| `audioapp/PhaseModSynth.hpp`        | `mixPhaseModMidiNotesBlock`, `PhaseModSynthMidiNoteRegion`, `PhaseModSynthRuntime`, `PhaseModSynthParams`, `PhaseModSynthParam` |
| `audioapp/KickGenerator.hpp`        | `mixKickMidiNotesBlock`, `KickMidiNoteRegion`, `KickGeneratorRuntime`, `KickGeneratorParams`, `KickParam` |
| `audioapp/SnareGenerator.hpp`       | `mixSnareMidiNotesBlock`, `SnareMidiNoteRegion`, `SnareGeneratorRuntime`, `SnareGeneratorParams`, `SnareParam` |
| `audioapp/ClapGenerator.hpp`        | `mixClapMidiNotesBlock`, `ClapMidiNoteRegion`, `ClapGeneratorRuntime`, `ClapGeneratorParams`, `ClapParam` |
| `audioapp/CymbalGenerator.hpp`      | `mixCymbalMidiNotesBlockStereo`, `CymbalMidiNoteRegion`, `CymbalGeneratorRuntime`, `CymbalGeneratorParams`, `CymbalParam` |
| `audioapp/CrashGenerator.hpp`       | `mixCrashMidiNotesBlockStereo`, `CrashMidiNoteRegion`, `CrashGeneratorRuntime`, `CrashGeneratorParams`, `CrashParam` |
| `audioapp/DynamicsProcessor.hpp`    | `processGateStereoBlock`, `processCompressorStereoBlock`, `processExpanderStereoBlock`, `processLimiterStereoBlock`, `GateParams`/`CompressorParams`/`ExpanderParams`/`LimiterParams` and their `*Param` enums, `DynamicsRuntime` |
| `audioapp/FrequencyFxProcessor.hpp` | `processFilterStereoBlock`, `processFourBandEqStereoBlock`, `processFrequencyShifterStereoBlock`, `FilterParams`/`FourBandEqParams`/`FrequencyShifterParams` and their `*Param` enums, `FilterRuntime`/`FourBandEqRuntime`/`FrequencyShifterRuntime` |
| `audioapp/MidiUtils.hpp`            | `midiNoteToHz`, `isMidiNoteActive` (private)                             |
| `audioapp/LfoTypes.hpp`             | Any LFO value type used by `lfoValues` layout (already pulled in via `DeviceChain.hpp`) |
| `audioapp/SamplerFilter.hpp`        | `BiquadState`                                                            |

The previous attempt failed because workers invented synonyms (e.g. `Sine` for
`addSineBlock`) or redefined automation helpers. **None of the above may be
moved, renamed, or redefined.**

## Risk

- **Regression if any step skips the test gate.** Each step is gated on
  `device_chain_test` and any sibling that calls `processDeviceChain`; if a
  step's worker forgets to run the gate, a behaviour drift in step 2 will
  contaminate step 3 and the bug becomes invisible.
- **Scratch layout drift.** The `DeviceChainScratch` POD layout (member order,
  array sizes) must remain identical when moved; any change in size or order
  changes the value of `gScratch.samplerRegions[0]` and the byte-identical
  test will fail.
- **Realtime-safety regression in moved code.** A worker that re-introduces a
  heap allocation in `processDeviceNode` will cause undefined behavior in
  production. The contract pins this: no `new`/`malloc`/STL containers in the
  new files' audio-thread entry points.
- **Header bloat.** Putting the `applyModulation` overloads in a header
  (e.g. as `inline`) would force every TU that includes the header to compile
  them. The contract keeps definitions in a `.cpp` and only declares in the
  header.
