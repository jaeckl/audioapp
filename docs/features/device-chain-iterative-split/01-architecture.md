# DeviceChain Iterative Split — Architecture

## Overview

The 1261-LOC `DeviceChain.cpp` is split into **4 small, focused TUs**, each
owned by exactly one of 4 sequential work packages. Each TU has a paired header
declaring its public surface, and a `.cpp` carrying the definitions. The
original `DeviceChain.cpp` shrinks monotonically; nothing is ever added back to
it. After all 4 steps, `DeviceChain.cpp` contains only `processDeviceChain`
orchestration glue and the 3 trivial classifier helpers
(`isDynamicsDeviceNodeKind`, `isInstrumentDeviceNodeKind`,
`isFrequencyFxDeviceNodeKind`).

## File layout (final state after Step 4)

```
engine_juce/
  include/audioapp/
    DeviceChain.hpp                       ← UNCHANGED (public API stays)
    DeviceChainScratch.hpp                ← NEW (Step 1): scratch POD + owner
  src/
    DeviceChain.cpp                       ← shrinks 1261 → ≤50 LOC (orchestration)
    DeviceChainAutomationModulation.cpp   ← NEW (Step 2): applyModulation overloads,
                                            applyDspModulationAtFrame, dspParamsAtFrame,
                                            nodeNeedsSubBlocks,
                                            nodeUsesDspAutomationSubBlocks,
                                            nodeHasDspModulation
    DeviceChainAutomationModulation.hpp   ← NEW (Step 2): declarations
    DeviceChainProcessor.cpp              ← NEW (Step 3): processDeviceNode dispatcher
    DeviceChainProcessor.hpp              ← NEW (Step 3): declarations
```

Note: `DeviceChainScratch.hpp` is header-only (struct-only, no inline
functions, no `inline` storage). The single `thread_local DeviceChainScratch
gScratch` instance lives in **`DeviceChain.cpp`** (it owns the scratch) and is
passed by reference into the Step 2 / Step 3 functions.

## Step 1 — Move scratch to a header (2 new files, 19 lines deleted)

### Public surface of `DeviceChainScratch.hpp`

```cpp
#pragma once

#include "audioapp/DeviceChain.hpp"  // for kMaxInstrumentRegions, BiquadState
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/PhaseModSynth.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"

namespace audioapp {

constexpr int kScratchFrames = 4096;
constexpr int kAutomationSubBlockFrames = 64;

struct DeviceChainScratch {
    float scratch[kScratchFrames];
    float tempStereoL[kScratchFrames];
    float tempStereoR[kScratchFrames];
    float perFrameGain[kScratchFrames];
    float perFramePan[kScratchFrames];
    SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions];
    SubtractiveMidiNoteRegion subtractiveRegions[kMaxInstrumentRegions];
    KickMidiNoteRegion kickRegions[kMaxInstrumentRegions];
    SnareMidiNoteRegion snareRegions[kMaxInstrumentRegions];
    ClapMidiNoteRegion clapRegions[kMaxInstrumentRegions];
    CymbalMidiNoteRegion cymbalRegions[kMaxInstrumentRegions];
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];
    PhaseModSynthMidiNoteRegion phaseModRegions[kMaxInstrumentRegions];
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];
};

} // namespace audioapp
```

Step 1 deletes lines 25–44 of `DeviceChain.cpp` (the `kScratchFrames` /
`kAutomationSubBlockFrames` constants, the `DeviceChainScratch` struct, and the
`thread_local gScratch` definition) and replaces them with:

```cpp
#include "audioapp/DeviceChainScratch.hpp"

namespace audioapp {
namespace {
thread_local DeviceChainScratch gScratch;
// ... rest of anonymous namespace ...
} // namespace
```

No other code in `DeviceChain.cpp` changes. The `gScratch` instance continues
to live in `DeviceChain.cpp` (one definition rule); the struct type is now
visible to other TUs that include the header.

### Why header-only and not a `.cpp`?

The struct is a POD value type with no constructors, destructors, or methods.
Putting it in a header keeps it cheap to include from many TUs and lets the
compiler prove (via inlining) that the per-call scratch passes are zero-cost.
This matches the existing pattern (`DeviceChain.hpp` itself is a header-only
container of POD types).

## Step 2 — Move automation/modulation helpers (2 new files, ~290 lines deleted)

### Public surface of `DeviceChainAutomationModulation.hpp`

```cpp
#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/AutomationTypes.hpp"  // for ModulationEdgePlayback
#include "audioapp/AutomationPlayback.hpp" // for AutomationClipPlayback
#include "audioapp/DeviceChainScratch.hpp"  // for kAutomationSubBlockFrames (transitively)

namespace audioapp {
namespace DeviceChainAutomationModulation {

// Per-type modulation overloads (move-as-is, signatures unchanged)
void applyModulation(OscillatorParams&, float, uint16_t) noexcept;
void applyModulation(SamplerParams&, float, uint16_t) noexcept;
void applyModulation(SubtractiveSynthParams&, float, uint16_t) noexcept;
void applyModulation(KickGeneratorParams&, float, uint16_t) noexcept;
void applyModulation(SnareGeneratorParams&, float, uint16_t) noexcept;
void applyModulation(ClapGeneratorParams&, float, uint16_t) noexcept;
void applyModulation(CymbalGeneratorParams&, float, uint16_t) noexcept;
void applyModulation(CrashGeneratorParams&, float, uint16_t) noexcept;
void applyModulation(PhaseModSynthParams&, float, uint16_t) noexcept;
void applyModulation(GateParams&, float, uint16_t) noexcept;
void applyModulation(CompressorParams&, float, uint16_t) noexcept;
void applyModulation(ExpanderParams&, float, uint16_t) noexcept;
void applyModulation(LimiterParams&, float, uint16_t) noexcept;
void applyModulation(FilterParams&, float, uint16_t) noexcept;
void applyModulation(FourBandEqParams&, float, uint16_t) noexcept;
void applyModulation(FrequencyShifterParams&, float, uint16_t) noexcept;
// No-op overloads (move-as-is)
void applyModulation(TrackGainParams&, float, uint16_t) noexcept;
void applyModulation(DelayParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(ReverbParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(ChorusParamsPlayback&, float, uint16_t) noexcept;
void applyModulation(PhaserParamsPlayback&, float, uint16_t) noexcept;

// DSP automation/modulation evaluation (move-as-is)
void applyDspModulationAtFrame(DeviceVariantParams& params,
                               DeviceNodeKind kind,
                               int lfoFrame,
                               int framesToProcess,
                               const float* lfoValues,
                               int lfoCount,
                               const ModulationEdgePlayback* modEdges,
                               int modEdgeCount) noexcept;

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

// Predicate helpers (move-as-is, signatures unchanged)
bool nodeNeedsSubBlocks(const DeviceNodePlayback& node,
                        int deviceIndex,
                        const AutomationClipPlayback* clips,
                        int clipCount,
                        const ModulationEdgePlayback* modEdges,
                        int modEdgeCount) noexcept;

bool nodeUsesDspAutomationSubBlocks(const DeviceNodePlayback& node,
                                    int deviceIndex,
                                    const AutomationClipPlayback* clips,
                                    int clipCount) noexcept;

bool nodeHasDspModulation(uint16_t deviceIndex,
                          const ModulationEdgePlayback* modEdges,
                          int modEdgeCount) noexcept;

} // namespace DeviceChainAutomationModulation
} // namespace audioapp
```

**Why a sub-namespace?** The previous attempt collided when `applyModulation`
overloads from different modules landed in the same `audioapp` namespace. The
sub-namespace `audioapp::DeviceChainAutomationModulation` binds the names to
this feature and prevents future collisions without forcing fully-qualified
call sites everywhere (callers in `DeviceChain.cpp` use
`using namespace DeviceChainAutomationModulation;` inside the anonymous
namespace).

Step 2 deletes lines 77–435 and 437–506 of `DeviceChain.cpp` (the
`applyModulation` overloads, `applyDspModulationAtFrame`, `dspParamsAtFrame`,
`nodeNeedsSubBlocks`, `nodeUsesDspAutomationSubBlocks`, `nodeHasDspModulation`)
and adds:

```cpp
#include "audioapp/DeviceChainAutomationModulation.hpp"
// ...
using namespace audioapp::DeviceChainAutomationModulation;
```

to the anonymous namespace. `DeviceChain.cpp` calls
`applyModulation(params, modAmount, pid)` exactly as before.

## Step 3 — Extract per-device dispatcher (2 new files, ~600 lines deleted)

### Public surface of `DeviceChainProcessor.hpp`

```cpp
#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"

namespace audioapp {
namespace DeviceChainProcessor {

/// Process one device node for [framesToProcess] frames, writing into
/// [trackLeft]/[trackRight] (additive for instruments, replace for effects)
/// and into [scratch] for instrument cases.
///
/// Orchestrator-facing: this is the SRP unit "process one device kind".
/// Takes everything by reference/pointer; no global state is reached for.
void processDeviceNode(const DeviceNodePlayback& node,
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

} // namespace DeviceChainProcessor
} // namespace audioapp
```

Step 3 deletes the `switch (node.kind)` block (lines 687–1257) from
`processDeviceChain` and replaces it with:

```cpp
audioapp::DeviceChainProcessor::processDeviceNode(
    node, deviceIndex, framesToProcess, trackLeft, trackRight,
    sampleRate, bpm, playheadStartBeat, notes, noteCount,
    modulatedParams, needsSubBlocks, lfoValues, lfoCount,
    modEdges, modEdgeCount, automationClips, automationClipCount,
    oscillatorPhase, suppressInstruments, samplerFilterStates,
    subtractiveRuntimes, kickRuntimes, snareRuntimes, clapRuntimes,
    cymbalRuntimes, crashRuntimes, phaseModRuntimes, dynamicsRuntimes,
    timeBasedRuntimes, filterRuntimes, fourBandEqRuntimes,
    frequencyShifterRuntimes, deviceMeters, maxDeviceMeters, gScratch);
```

The `switch` body (all device cases) is moved verbatim into
`DeviceChainProcessor.cpp` inside the new `processDeviceNode` function. The
scratch pointer is passed by reference (never reached for globally) — this is
the SRP guarantee.

**Why the long parameter list?** Mirroring `processDeviceChain` keeps the
dispatcher a true refactor: every existing runtime pointer, every LFO/automation
array, every meter slot is plumbed the same way. The dispatcher does no
caller-side computation; it only switches on `node.kind` and reuses the
arguments the orchestrator already has.

## Step 4 — Slim `processDeviceChain` to orchestration only (0 new files, ~60 lines deleted)

After Step 3, `processDeviceChain` is already a thin orchestrator. Step 4:

- Inlines the 3 trivial classifier helpers (`isDynamicsDeviceNodeKind`,
  `isInstrumentDeviceNodeKind`, `isFrequencyFxDeviceNodeKind`) since they
  remain in `DeviceChain.cpp` (they were never part of the monolith's SRP
  problem).
- Adds a top-of-function local comment that this file is glue only.
- Final LOC count must be ≤50 (excluding the namespace wrapper and the
  classifier helpers, which can stay if they bring the count over 50 only by
  1–2 lines).

No new files. No new symbols. The signature of `processDeviceChain` is
byte-identical to HEAD.

## Threading / async boundaries

| Path                         | Thread           | Allocations allowed? | State                          |
|------------------------------|------------------|----------------------|--------------------------------|
| `processDeviceChain`         | audio thread     | NO                   | Reads `gScratch` (thread_local POD) |
| `processDeviceNode` (Step 3) | audio thread     | NO                   | Mutates the passed `scratch&`  |
| Step 2 helpers               | audio thread     | NO                   | None                           |
| `isXxxDeviceNodeKind`        | any              | NO                   | None (trivial switches)        |
| `midiActiveFrequencyHz`      | audio thread     | NO                   | None                           |
| `gScratch` itself            | n/a              | n/a                  | `thread_local` (one per AudioThread) |

**No shared mutable state.** The scratch is `thread_local`; one instance per
audio thread. There are no locks, no atomics, no `static` mutable data in any
new header or `.cpp`.

## Ownership boundaries

| Symbol                                                  | Owner (after refactor)                          |
|---------------------------------------------------------|-------------------------------------------------|
| `DeviceChainScratch` struct, `kScratchFrames`, `kAutomationSubBlockFrames` | `DeviceChainScratch.hpp` (Step 1) |
| `thread_local DeviceChainScratch gScratch`              | `DeviceChain.cpp` (one-definition rule)         |
| `applyModulation` overloads                             | `DeviceChainAutomationModulation.{hpp,cpp}`     |
| `applyDspModulationAtFrame`, `dspParamsAtFrame`         | `DeviceChainAutomationModulation.{hpp,cpp}`     |
| `nodeNeedsSubBlocks`, `nodeUsesDspAutomationSubBlocks`, `nodeHasDspModulation` | `DeviceChainAutomationModulation.{hpp,cpp}` |
| `processDeviceNode`                                     | `DeviceChainProcessor.{hpp,cpp}` (Step 3)       |
| `processDeviceChain`                                    | `DeviceChain.cpp` (Step 4 glue)                 |
| `isDynamicsDeviceNodeKind` etc., `midiActiveFrequencyHz`| `DeviceChain.cpp` (unchanged)                   |
| `evaluateAutomationEnvelope`, `nodeHasDspAutomation`, `applyDspAutomationAtBeat`, `applyAutomationValue` | `AutomationPlayback.hpp` (unchanged — do not move) |
| `ModulationEdgePlayback`, `AutomationClipPlayback`, `kEncodedCommonGain`, `kEncodedCommonPan` | `AutomationTypes.hpp` (unchanged) |

## Error model

There is no error model to add. All functions are `noexcept` and either:

- return a value (`dspParamsAtFrame` returns by value),
- mutate a passed `DeviceChainScratch&` or `DeviceVariantParams&`,
- or write into passed audio buffers.

No exceptions, no error codes, no logging on the audio thread. Step workers
must keep the existing `noexcept` annotations.

## UI / state synchronization model

Not applicable. The refactor is pure engine code; the Flutter bridge, JSON
serialization, and UI are untouched.

## Persistence model

Not applicable. No serialization changes.

## Summary

- 4 sequential steps, 0 parallel.
- 6 new files (3 hpp + 3 cpp; `DeviceChainScratch.hpp` is header-only, so 3 hpp
  pairs and 1 header-only).
- `DeviceChain.cpp` shrinks monotonically: 1261 → 1242 (Step 1) → ~950 (Step 2)
  → ~350 (Step 3) → ≤50 (Step 4).
- Public API of `processDeviceChain` is byte-identical to HEAD.
- All existing tests must keep passing after every step.
