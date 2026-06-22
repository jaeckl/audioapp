# OOP Device Processors Phase 2 — Canonical Vocabulary

This vocabulary is **binding**. Implementation agents must not invent synonyms or alternative names.

## New Classes & Types

| Concept | Canonical Name | Module / File | Notes |
|---------|---------------|---------------|-------|
| Abstract processor base | `DeviceProcessor` | `DeviceProcessor.hpp` | Virtual base for all 22 processors |
| Processor factory/arena | `ProcessorArena` | `ProcessorArena.hpp` | Fixed-capacity placement-new pool |
| Consolidated context | `ProcessContext` | `ProcessContext.hpp` | All per-block parameters |
| Stereo buffer wrapper | `AudioBlock` | `AudioBlock.hpp` | `{float* l, float* r, int frames}` |
| Orchestrator namespace | `DeviceChainOrchestrator` | `DeviceChainOrchestrator.hpp` | New orchestrator function(s) |
| Orchestration context | `DeviceChainOrchestrator::Context` | `DeviceChainOrchestrator.hpp` | Bridge between old API and new loop |
| Scoped scratch arena | `DeviceChainScratchArena` | `DeviceChainScratch.hpp` | Preallocated heap buffer for ring buffers |

## New Constants (all constexpr)

| Name | Value | File | Notes |
|------|-------|------|-------|
| `kMaxDevicesPerTrack` | 16 | `DeviceChain.hpp` | Unchanged from Phase 1 |
| `kArenaStorageBytes` | calculated | `ProcessorArena.hpp` | `kMaxDevicesPerTrack * sizeof(largest processor)` |

## Retained Types (unchanged from Phase 1)

| Concept | Canonical Name | Notes |
|---------|---------------|-------|
| Device node playback | `DeviceNodePlayback` | Still in `DeviceChain.hpp`, used by factory |
| Parameter variant | `DeviceVariantParams` | Still in `DeviceChain.hpp`, passed to `initParams` |
| Device node kind | `DeviceNodeKind` | Still in `DeviceChain.hpp` |
| Thread-local scratch | `DeviceChainScratch` | Still in `DeviceChainScratch.hpp`, expanded with arena |
| Device meters | `DeviceMeterAtomic` | Still in `DeviceChain.hpp` |
| MIDI playback note | `MidiPlaybackNote` | Still in `DeviceChain.hpp` |
| Midi note regions | `*MidiNoteRegion` | Still in respective generator headers |
| Biquad state | `BiquadState` | Still in `SamplerFilter.hpp` |

## Removed Types (replaced by embedded state)

| Old Name | Replacement | Notes |
|----------|-------------|-------|
| `FilterRuntime` (parallel array) | embedded in `FilterProcessor` as member | Moved from `FrequencyFxProcessor.hpp` to private member |
| `FourBandEqRuntime` | embedded in `FourBandEqProcessor` | Same |
| `FrequencyShifterRuntime` | embedded in `FrequencyShifterProcessor` | Same |
| `DynamicsRuntime` | embedded in each dynamics processor | `GateProcessor`, `CompressorProcessor`, `ExpanderProcessor`, `LimiterProcessor` each own one |
| `TimeBasedEffectRuntime` (heap array) | embedded in each time-based processor | **Except** the 192K buffer goes into `DeviceChainScratchArena` |
| `SubtractiveSynthRuntime` | embedded in `SubtractiveSynthProcessor` | Same |
| `PhaseModSynthRuntime` | embedded in `PhaseModSynthProcessor` | Same |
| `KickGeneratorRuntime` | embedded in `KickProcessor` | Same |
| `SnareGeneratorRuntime` | embedded in `SnareProcessor` | Same |
| `ClapGeneratorRuntime` | embedded in `ClapProcessor` | Same |
| `CymbalGeneratorRuntime` | embedded in `CymbalProcessor` | Same |
| `CrashGeneratorRuntime` | embedded in `CrashProcessor` | Same |
| `oscillatorPhase` (float&) | embedded in `OscillatorProcessor` | No longer passed as mutable reference |
| `samplerFilterStates` (BiquadState*) | embedded in `SamplerProcessor` | No longer an external array |

## Canonical Names for All 22 Processor Subclasses

See Phase 1 canonical vocabulary table for the full list. All processor class names are unchanged — only their inheritance and method signatures change.

## Namespaces

- `audioapp` — all new types live here.
- No nested namespace like `audioapp::processors` or `audioapp::devices::processors`.