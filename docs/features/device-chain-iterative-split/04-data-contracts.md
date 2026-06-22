# DeviceChain Iterative Split — Data Contracts

This document pins the exact data layout that each step moves or shares. The
goal: byte-identical behaviour at every step, so the existing
`device_chain_test` keeps passing.

## `DeviceChainScratch` (POD, value-typed)

**Owner:** `engine_juce/include/audioapp/DeviceChainScratch.hpp` (new, Step 1)
**Namespace:** `audioapp`
**Header-only:** yes (no constructors, destructors, or methods)
**Allocation:** none — value-typed, no `new`/`malloc`
**Threading:** each instance is `thread_local` (one per audio thread)

### Field order (binding — do not reorder)

| Index | Field | Type | Size (bytes) | Notes |
|---|---|---|---|---|
| 0 | `scratch` | `float[4096]` | 16384 | Mono scratch. |
| 1 | `tempStereoL` | `float[4096]` | 16384 | Cymbal/Crash L. |
| 2 | `tempStereoR` | `float[4096]` | 16384 | Cymbal/Crash R. |
| 3 | `perFrameGain` | `float[4096]` | 16384 | Resolved gain. |
| 4 | `perFramePan` | `float[4096]` | 16384 | Resolved pan. |
| 5 | `samplerRegions` | `SamplerMidiNoteRegion[32]` | depends | Sampler per-note. |
| 6 | `subtractiveRegions` | `SubtractiveMidiNoteRegion[32]` | depends | Subtractive/Bass. |
| 7 | `kickRegions` | `KickMidiNoteRegion[32]` | depends | Kick. |
| 8 | `snareRegions` | `SnareMidiNoteRegion[32]` | depends | Snare. |
| 9 | `clapRegions` | `ClapMidiNoteRegion[32]` | depends | Clap. |
| 10 | `cymbalRegions` | `CymbalMidiNoteRegion[32]` | depends | Cymbal. |
| 11 | `crashRegions` | `CrashMidiNoteRegion[32]` | depends | Crash. |
| 12 | `phaseModRegions` | `PhaseModSynthMidiNoteRegion[32]` | depends | PhaseMod. |
| 13 | `samplerNoteFilterStates` | `BiquadState[32]` | depends | Sampler fallback. |

**Field order must match HEAD line 28–43 exactly.** Reordering would shift
all later field offsets; the test suite does not exercise absolute offsets
but the orchestrator's `s.samplerRegions[i] = ...` and `s.subtractiveRegions[i] = ...`
statements still depend on the field names, not offsets, so reordering is
semantically safe **as long as names are preserved** — but workers must not
reorder for "style".

**Padding:** the struct contains only POD fields; the compiler may insert
padding between `BiquadState` arrays. This matches HEAD; no contract change.

### Singleton instance

```cpp
// engine_juce/src/DeviceChain.cpp (Step 1)
#include "audioapp/DeviceChainScratch.hpp"

namespace audioapp {
namespace {
thread_local DeviceChainScratch gScratch;  // single definition
} // namespace
} // namespace audioapp
```

**No other TU may define `gScratch`.** The header declares the type, the `.cpp`
defines the instance. One-definition rule.

## `dspParamsAtFrame` return value

**Owner:** `audioapp::DeviceChainAutomationModulation`
**Type:** `DeviceVariantParams` (existing `std::variant` of all `*Params`
structs, defined in `DeviceChain.hpp`)

**Contract:** the returned value is a copy of `node.params` with:

1. `applyDspAutomationAtBeat` applied first.
2. `applyDspModulationAtFrame` applied second.

The copy is stack-allocated (no heap). The variant is `~120 bytes` max
(PhaseModSynthParams with 4 operators is the largest). Worker must not
change the variant's type list.

## `processDeviceNode` argument structs

`processDeviceNode` does **not** introduce a new argument struct. It takes
its 30+ arguments individually, matching the parameter list of
`processDeviceChain`. This is intentional:

- The orchestrator (`processDeviceChain`) already has every value as a local.
- A wrapper struct would be a second refactor on top of the SRP refactor and
  violates the "minimum change" principle.
- Future refactors may introduce an arg-struct; not part of this slice.

## `DeviceChainScratch` lifetime

- The `gScratch` instance is `thread_local`, so it is constructed the first
  time the audio thread calls `processDeviceChain` and is destroyed at audio
  thread exit. Both construction and destruction are zero-cost because the
  struct is a POD aggregate.
- The struct is **never** copied, **never** taken by value across function
  boundaries in the new code. Step 2 and Step 3 helpers receive it as
  `DeviceChainScratch&`.

## `nodeNeedsSubBlocks` return semantics

- `true` ⇒ the orchestrator must render the device in 64-frame sub-blocks
  (only `Oscillator` and `Sampler` honour this; other devices ignore the flag
  in their per-device case, matching HEAD).
- `false` ⇒ the orchestrator renders the device in one full-block call.

## `nodeHasDspModulation` vs `nodeHasDspAutomation`

These are **distinct** helpers with different owners:

- `nodeHasDspAutomation` — defined in `AutomationPlayback.hpp`, takes
  automation clips.
- `nodeHasDspModulation` — defined in `DeviceChainAutomationModulation.hpp`
  (Step 2), takes modulation edges.

Do not unify. Do not rename. The orchestrator (`processDeviceChain`) calls
both. The Sub-tractive/Bass/PhaseMod block (HEAD line 651) uses both to
decide whether to skip per-block modulation.

## Layout stability

`DeviceChainScratch` layout must not change between Step 1 and Step 4. The
test suite exercises a `Sampler` chain (which writes `samplerRegions`) and
`SubtractiveSynth` (which writes `subtractiveRegions`) — any layout change
that invalidates the indices or the field access pattern will break the
test.

The struct is **POD, not a class**, and has no methods. There is no
v-table, no ABI concern. Step workers must not add a constructor (even
`=default`) to `DeviceChainScratch` — it would change it from aggregate to
non-aggregate, breaking aggregate-initialization in callers.
