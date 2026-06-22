# DeviceChain Iterative Split — Canonical Vocabulary

These names are **binding**. Implementation workers must not invent synonyms or
rename concepts. If a name below collides with an existing symbol in the
codebase, the implementation worker must stop and report — do not pick a
different name.

| Concept | Canonical name | Type / file | Notes |
|---|---|---|---|
| Audio-thread scratch buffer (mono) | `scratch` | `float[4096]` field on `DeviceChainScratch` | Lives in `DeviceChainScratch.hpp` (Step 1). |
| Audio-thread scratch buffer (stereo L) | `tempStereoL` | `float[4096]` field on `DeviceChainScratch` | Used by Cymbal/Crash (stereo-output generators). |
| Audio-thread scratch buffer (stereo R) | `tempStereoR` | `float[4096]` field on `DeviceChainScratch` | Used by Cymbal/Crash. |
| Per-frame gain envelope | `perFrameGain` | `float[4096]` field on `DeviceChainScratch` | Resolved common-gain automation for the current block. |
| Per-frame pan envelope | `perFramePan` | `float[4096]` field on `DeviceChainScratch` | Resolved common-pan automation for the current block. |
| Sampler per-note regions | `samplerRegions` | `SamplerMidiNoteRegion[32]` on `DeviceChainScratch` | Sampler only. |
| Subtractive per-note regions | `subtractiveRegions` | `SubtractiveMidiNoteRegion[32]` on `DeviceChainScratch` | Subtractive/Bass only. |
| Kick per-note regions | `kickRegions` | `KickMidiNoteRegion[32]` on `DeviceChainScratch` | Kick only. |
| Snare per-note regions | `snareRegions` | `SnareMidiNoteRegion[32]` on `DeviceChainScratch` | Snare only. |
| Clap per-note regions | `clapRegions` | `ClapMidiNoteRegion[32]` on `DeviceChainScratch` | Clap only. |
| Cymbal per-note regions | `cymbalRegions` | `CymbalMidiNoteRegion[32]` on `DeviceChainScratch` | Cymbal only. |
| Crash per-note regions | `crashRegions` | `CrashMidiNoteRegion[32]` on `DeviceChainScratch` | Crash only. |
| PhaseMod per-note regions | `phaseModRegions` | `PhaseModSynthMidiNoteRegion[32]` on `DeviceChainScratch` | PhaseMod only. |
| Sampler per-note filter states (fallback) | `samplerNoteFilterStates` | `BiquadState[32]` on `DeviceChainScratch` | Used when `samplerFilterStates==nullptr`. |
| Scratch struct (POD) | `DeviceChainScratch` | `struct` in `audioapp` namespace, header `DeviceChainScratch.hpp` | **Move-to-header**; no constructors/destructors/methods. |
| Scratch size constant | `kScratchFrames` | `constexpr int` = 4096 in `DeviceChainScratch.hpp` | Keep name; move file. |
| Automation sub-block size | `kAutomationSubBlockFrames` | `constexpr int` = 64 in `DeviceChainScratch.hpp` | Keep name; move file. |
| Per-AudioThread scratch instance | `gScratch` | `thread_local DeviceChainScratch` in `DeviceChain.cpp` | One definition. Stays in `DeviceChain.cpp` (the only place that includes the runtime dispatch logic). |
| Per-type modulation overloads | `applyModulation` | Free functions in `audioapp::DeviceChainAutomationModulation` | All 22 overloads move as-is (signatures, no-op bodies, math). |
| Apply LFO modulation at one frame | `applyDspModulationAtFrame` | `audioapp::DeviceChainAutomationModulation` | Move-as-is. |
| Resolve DSP params at a sub-block | `dspParamsAtFrame` | `audioapp::DeviceChainAutomationModulation` | Move-as-is. |
| "Does this node need 64-frame sub-blocks?" | `nodeNeedsSubBlocks` | `audioapp::DeviceChainAutomationModulation` | Move-as-is. |
| "Does this node use sub-block DSP automation?" | `nodeUsesDspAutomationSubBlocks` | `audioapp::DeviceChainAutomationModulation` | Move-as-is. |
| "Does this node have LFO modulation?" | `nodeHasDspModulation` | `audioapp::DeviceChainAutomationModulation` | Move-as-is. |
| Apply automation at a beat (existing) | `applyDspAutomationAtBeat` | `audioapp` (AutomationPlayback.hpp) | **Do not move.** Just call it from `dspParamsAtFrame`. |
| Test if any DSP automation exists (existing) | `nodeHasDspAutomation` | `audioapp` (AutomationPlayback.hpp) | **Do not move.** Distinct from `nodeUsesDspAutomationSubBlocks` and from `nodeHasDspModulation`. |
| Apply one absolute automation value (existing) | `applyAutomationValue` | `audioapp` (AutomationPlayback.hpp) | **Do not move.** |
| Evaluate envelope (existing) | `evaluateAutomationEnvelope` | `audioapp` (AutomationPlayback.hpp) | **Do not move.** |
| Process one device node | `processDeviceNode` | `audioapp::DeviceChainProcessor` (new, Step 3) | Orchestrator-facing dispatcher; switches on `DeviceNodeKind`. |
| Process the whole chain | `processDeviceChain` | `audioapp` (DeviceChain.cpp) | Original signature, original behavior. Step 4 reduces to orchestration glue. |
| Stereo block peak helper | `stereoBlockPeak` | anonymous-namespace in `DeviceChain.cpp` | Stays in `DeviceChain.cpp` (used by 2 effects, no SRP win from moving). |
| Dynamics meter publisher | `publishDynamicsMeters` | anonymous-namespace in `DeviceChain.cpp` | Stays in `DeviceChain.cpp` (used by 4 dynamics cases). |
| MIDI-note active test (private) | `isMidiNoteActive` | anonymous-namespace in `DeviceChain.cpp` | Stays in `DeviceChain.cpp`. |
| Common-gain encoded param id (existing) | `kEncodedCommonGain` | `audioapp` (AutomationTypes.hpp) | **Do not move or rename.** |
| Common-pan encoded param id (existing) | `kEncodedCommonPan` | `audioapp` (AutomationTypes.hpp) | **Do not move or rename.** |
| Device kind enum (existing) | `DeviceNodeKind` | `audioapp` (DeviceChain.hpp) | **Do not move.** |
| Per-device node playback struct (existing) | `DeviceNodePlayback` | `audioapp` (DeviceChain.hpp) | **Do not move.** |
| Variant of per-device params (existing) | `DeviceVariantParams` | `audioapp` (DeviceChain.hpp) | **Do not move.** |
| Per-device meter atomics (existing) | `DeviceMeterAtomic` | `audioapp` (DeviceChain.hpp) | **Do not move.** |
| Time-based effect runtime (existing) | `TimeBasedEffectRuntime` | `audioapp` (DeviceChain.hpp) | **Do not move.** |
| Max instrument regions | `kMaxInstrumentRegions` | `audioapp` (DeviceChain.hpp) = 32 | **Do not move.** |
| Instrument output gain | `kInstrumentOutputGain` | `audioapp` (DeviceChain.hpp) = 0.2f | **Do not move.** |

## Forbidden name changes (workers must stop, not invent)

- ❌ `SineBlock` (must remain `addSineBlock`)
- ❌ `ModulationEdge` (must remain `ModulationEdgePlayback`)
- ❌ `AutoClip` (must remain `AutomationClipPlayback`)
- ❌ `CommonGain` / `CommonPan` (must remain `kEncodedCommonGain` / `kEncodedCommonPan`)
- ❌ `ScratchBuffer` (must remain `DeviceChainScratch`)
- ❌ `SineParams` (must remain `OscillatorParams`)
- ❌ `getOscillatorFrequency` (must remain `midiActiveFrequencyHz`)
- ❌ `applyAutoValue` (must remain `applyAutomationValue`)
- ❌ `processNode` (must remain `processDeviceNode` if a new dispatcher is added)
- ❌ Moving `evaluateAutomationEnvelope`, `applyAutomationValue`,
  `applyDspAutomationAtBeat`, `nodeHasDspAutomation` out of `AutomationPlayback.hpp`
  / `AutomationPlayback.cpp`
