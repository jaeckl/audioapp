# DeviceChain Iterative Split — API Contracts

This document pins the exact public surface added in each step. Workers must
match the signatures, `noexcept` annotations, default arguments, parameter
names, and order verbatim.

## Step 1 — `DeviceChainScratch.hpp`

This header is a **struct-only, header-only, no-inline** declaration. It
introduces no new free functions. It moves the existing anonymous-namespace
declarations verbatim into the public header.

### Type: `DeviceChainScratch` (POD)

**Owner:** `engine_juce/include/audioapp/DeviceChainScratch.hpp` (new)
**Visibility:** public (other TUs include this header to receive a
`DeviceChainScratch&` argument from the orchestrator in Steps 2–3)
**Threading:** every instance lives on the audio thread
**Allocation:** none — value-typed, no constructors, no destructors

| Field | Type | Default | Notes |
|---|---|---|---|
| `scratch` | `float[4096]` | uninitialized | Mono scratch. |
| `tempStereoL` | `float[4096]` | uninitialized | Stereo-out L. |
| `tempStereoR` | `float[4096]` | uninitialized | Stereo-out R. |
| `perFrameGain` | `float[4096]` | uninitialized | Resolved gain envelope. |
| `perFramePan` | `float[4096]` | uninitialized | Resolved pan envelope. |
| `samplerRegions` | `SamplerMidiNoteRegion[32]` | default-constructed | Sampler. |
| `subtractiveRegions` | `SubtractiveMidiNoteRegion[32]` | default-constructed | Subtractive/Bass. |
| `kickRegions` | `KickMidiNoteRegion[32]` | default-constructed | Kick. |
| `snareRegions` | `SnareMidiNoteRegion[32]` | default-constructed | Snare. |
| `clapRegions` | `ClapMidiNoteRegion[32]` | default-constructed | Clap. |
| `cymbalRegions` | `CymbalMidiNoteRegion[32]` | default-constructed | Cymbal. |
| `crashRegions` | `CrashMidiNoteRegion[32]` | default-constructed | Crash. |
| `phaseModRegions` | `PhaseModSynthMidiNoteRegion[32]` | default-constructed | PhaseMod. |
| `samplerNoteFilterStates` | `BiquadState[32]` | zero-initialized | Sampler per-note filter fallback. |

**Note on `samplerNoteFilterStates`:** the existing `DeviceChain.cpp` line
`std::memset(s.samplerNoteFilterStates, 0, sizeof(s.samplerNoteFilterStates));`
clears the array every call. The `BiquadState` struct in
`SamplerFilter.hpp` is itself a POD (no constructors), so a value-initialized
array gives the same zero state — workers do **not** need to add a
constructor to `DeviceChainScratch`. If `BiquadState` is later changed to
non-POD, Step 1 will fail to compile and the worker must report (not invent
constructors).

### Constants: `kScratchFrames`, `kAutomationSubBlockFrames`

| Name | Type | Value | Owner |
|---|---|---|---|
| `kScratchFrames` | `constexpr int` | 4096 | `DeviceChainScratch.hpp` (moved) |
| `kAutomationSubBlockFrames` | `constexpr int` | 64 | `DeviceChainScratch.hpp` (moved) |

Both are in `namespace audioapp` and visible to all TUs that include the
header.

## Step 2 — `DeviceChainAutomationModulation.{hpp,cpp}`

All signatures below are **move-as-is** from the anonymous namespace in
`DeviceChain.cpp`. Names, types, noexcept, parameter order are preserved.

### Function: `applyModulation(OscillatorParams&, float, uint16_t)`

- **Owner:** `DeviceChainAutomationModulation.cpp`
- **Namespace:** `audioapp::DeviceChainAutomationModulation`
- **Inputs:** `p` (mutable ref), `modAmount` (LFO × edge amount), `localParamId`
  (encoded with kind tag).
- **Output:** none (mutates `p`).
- **Noexcept:** yes.
- **Threading:** audio thread.
- **Validation:** `unpackParamId(localParamId)` returns
  `OscillatorParam::Frequency` only — any other value hits the `default: break;`
  and is a silent no-op (matches existing behavior; do not add logging).
- **Example:** unchanged.

(22 overloads total: Oscillator, Sampler, SubtractiveSynth, KickGenerator,
SnareGenerator, ClapGenerator, CymbalGenerator, CrashGenerator,
PhaseModSynth, Gate, Compressor, Expander, Limiter, Filter, FourBandEq,
FrequencyShifter, plus no-op overloads for TrackGain, Delay, Reverb, Chorus,
Phaser. Signatures match lines 79–362 of HEAD. The 22nd overload is
`FrequencyShifterParams` (line 160).)

### Function: `applyDspModulationAtFrame`

```cpp
void applyDspModulationAtFrame(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               int lfoFrame,
                               int framesToProcess,
                               const float* lfoValues,
                               int lfoCount,
                               const ModulationEdgePlayback* modEdges,
                               int modEdgeCount) noexcept;
```

- **Owner:** `DeviceChainAutomationModulation.cpp`
- **Inputs:** `params` (mutable ref), `kind`, `lfoFrame`, `framesToProcess`,
  `lfoValues` (nullable), `lfoCount`, `modEdges` (nullable), `modEdgeCount`.
- **Output:** none.
- **Noexcept:** yes.
- **Threading:** audio thread.
- **Validation:** early-returns if any of `lfoValues`, `lfoCount`, `modEdges`,
  `modEdgeCount` is null/zero. Skips `kEncodedCommonGain` / `kEncodedCommonPan`
  in the per-edge loop. No heap allocation.

### Function: `dspParamsAtFrame`

```cpp
DeviceVariantParams dspParamsAtFrame(const DeviceNodePlayback& node,
                                     int deviceIndex,
                                     double beat,
                                     int lfoFrame,
                                     int framesToProcess,
                                     const AutomationClipPlayback* automationClips,
                                     int automationClipCount,
                                     const float* lfoValues,
                                     int lfoCount,
                                     const ModulationEdgePlayback* modEdges,
                                     int modEdgeCount);
```

- **Owner:** `DeviceChainAutomationModulation.cpp`
- **Inputs:** `node` (const ref), `deviceIndex`, `beat` (absolute timeline
  beats), `lfoFrame`, `framesToProcess`, automation/LFO/modulation arrays.
- **Output:** a fresh `DeviceVariantParams` value (copy of `node.params` with
  automation + modulation applied).
- **Noexcept:** **NO** — the existing signature is **not** `noexcept` because
  `std::variant` copy is not `noexcept` on every implementation. Preserve
  this. Do not add `noexcept`.
- **Threading:** audio thread.
- **Allocation:** the returned `DeviceVariantParams` is a stack value; no
  heap.
- **Calls (in order):** `applyDspAutomationAtBeat`, then
  `applyDspModulationAtFrame`.

### Function: `nodeNeedsSubBlocks`

```cpp
bool nodeNeedsSubBlocks(const DeviceNodePlayback& node,
                        int deviceIndex,
                        const AutomationClipPlayback* clips,
                        int clipCount,
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount) noexcept;
```

- **Owner:** `DeviceChainAutomationModulation.cpp`
- **Inputs:** `node`, `deviceIndex`, automation/modulation arrays.
- **Output:** `true` if any clip/edge targets this `deviceIndex` and is **not**
  a Common gain/pan.
- **Noexcept:** yes.
- **Threading:** audio thread.
- **Validation:** skips `kEncodedCommonGain` / `kEncodedCommonPan` in both
  loops. Behavior is byte-identical to HEAD lines 437–467.

### Function: `nodeUsesDspAutomationSubBlocks`

```cpp
bool nodeUsesDspAutomationSubBlocks(const DeviceNodePlayback& node,
                                    int deviceIndex,
                                    const AutomationClipPlayback* clips,
                                    int clipCount) noexcept;
```

- **Owner:** `DeviceChainAutomationModulation.cpp`
- **Inputs:** `node`, `deviceIndex`, automation clips.
- **Output:** `true` only for `Oscillator` and `Sampler` kinds when a
  non-Common automation clip targets this `deviceIndex`. Other kinds return
  `false` (subtractive/bass/phase-mod do per-sample inside
  `mix*MidiNotesBlock`).
- **Noexcept:** yes.
- **Threading:** audio thread.
- **Validation:** matches HEAD lines 469–492.

### Function: `nodeHasDspModulation`

```cpp
bool nodeHasDspModulation(uint16_t deviceIndex,
                          const ModulationEdgePlayback* modEdges,
                          int modEdgeCount) noexcept;
```

- **Owner:** `DeviceChainAutomationModulation.cpp`
- **Inputs:** `deviceIndex`, modulation edges.
- **Output:** `true` if any edge targets this device with a non-Common param.
- **Noexcept:** yes.
- **Threading:** audio thread.
- **Validation:** matches HEAD lines 494–506.

## Step 3 — `DeviceChainProcessor.{hpp,cpp}`

### Function: `processDeviceNode`

```cpp
void processDeviceNode(
    const DeviceNodePlayback& node,
    int deviceIndex,
    int framesToProcess,
    float* trackLeft,
    float* trackRight,
    double sampleRate,
    int bpm,
    double playheadStartBeat,
    const MidiPlaybackNote* notes,
    int noteCount,
    DeviceVariantParams& modulatedParams,
    bool needsSubBlocks,
    const float* lfoValues,
    int lfoCount,
    const ModulationEdgePlayback* modEdges,
    int modEdgeCount,
    const AutomationClipPlayback* automationClips,
    int automationClipCount,
    float& oscillatorPhase,
    bool suppressInstruments,
    BiquadState* samplerFilterStates,
    SubtractiveSynthRuntime* subtractiveRuntimes,
    KickGeneratorRuntime* kickRuntimes,
    SnareGeneratorRuntime* snareRuntimes,
    ClapGeneratorRuntime* clapRuntimes,
    CymbalGeneratorRuntime* cymbalRuntimes,
    CrashGeneratorRuntime* crashRuntimes,
    PhaseModSynthRuntime* phaseModRuntimes,
    DynamicsRuntime* dynamicsRuntimes,
    TimeBasedEffectRuntime* timeBasedRuntimes,
    FilterRuntime* filterRuntimes,
    FourBandEqRuntime* fourBandEqRuntimes,
    FrequencyShifterRuntime* frequencyShifterRuntimes,
    DeviceMeterAtomic* deviceMeters,
    int maxDeviceMeters,
    DeviceChainScratch& scratch) noexcept;
```

- **Owner:** `DeviceChainProcessor.cpp`
- **Namespace:** `audioapp::DeviceChainProcessor`
- **Inputs:** the full set of parameters that `processDeviceChain` currently
  resolves **before** the device switch (modulated params, sub-block flag, LFO
  buffers, automation buffers, runtime pointers, meter slot, scratch ref).
- **Output:** none (mutates `trackLeft`/`trackRight` and the runtime pointers
  in-place; writes scratch for instrument cases).
- **Noexcept:** yes.
- **Threading:** audio thread.
- **Validation:** the dispatcher is allowed to `std::get<>` the
  `modulatedParams` variant; an `std::bad_variant_access` would be a
  programmer error and the function inherits the existing behaviour of
  `std::get<>` (no try/catch — matches HEAD).
- **Notes:** the scratch is **never** reached for globally. The orchestrator
  passes its `gScratch` by reference.

## Step 4 — `processDeviceChain` (unchanged signature, slimmer body)

The signature of `processDeviceChain` in `DeviceChain.hpp` is **byte-identical
to HEAD line 253–285** and is **not edited** by any step. Step 4 only
slims the body in `DeviceChain.cpp` to be orchestration glue (≤50 LOC plus the
namespace wrapper).
