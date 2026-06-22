# OOP Device Processors Phase 2 — Data Contracts

This document defines memory ownership, placement-new rules, arena layout, and the lifecycle of all runtime state.

---

## 1. Memory Ownership Model

### Before Phase 2 (Phase 1 ownership)

```
TrackPlaybackSnapshot (ProjectEngine.hpp)
  ├── samplerFilterStates[16][32]          — BiquadState, 16 devices × 32 regions
  ├── subtractiveRuntimes[16]               — SubtractiveSynthRuntime, even for non-subtractive devices
  ├── kickRuntimes[16]                      — KickGeneratorRuntime, even for non-kick devices
  ├── snareRuntimes[16]
  ├── clapRuntimes[16]
  ├── cymbalRuntimes[16]
  ├── crashRuntimes[16]
  ├── phaseModRuntimes[16]
  ├── dynamicsRuntimes[16]
  ├── timeBasedRuntimes[16]                 — includes heap-allocated ring buffers!
  └── oscillatorPhase (float)
  └── (plus FilterRuntime*, etc. passed as separate parameters)
```

Waste: 9 parallel arrays × 16 elements each, most slots unused for any given track.

### After Phase 2 (Phase 2 ownership)

```
ProjectEngine (for each track):
  └── ProcessorArena arena_                 — contains up to 16 DeviceProcessor* objects
        ├── FilterProcessor                 — owns FilterRuntime as member (24 bytes)
        ├── GateProcessor                   — owns DynamicsRuntime as member (12 bytes)
        ├── DelayProcessor                  — owns buffer pointers + writeIndex (members)
        │   └── ring buffers in DeviceChainScratchArena (preallocated)
        └── ...

DeviceChainScratch (thread-local):
  ├── scratch, tempStereoL/R, perFrameGain, perFramePan  (same as Phase 1)
  ├── samplerRegions, subtractiveRegions, kickRegions...  (same as Phase 1)
  ├── samplerNoteFilterStates                             (same as Phase 1)
  └── DeviceChainScratchArena ringBufferArena             (NEW — for time-based FX buffers)
```

---

## 2. ProcessorArena Layout

```
ProcessorArena
  ┌────────────────────────────────────────────────────────────┐
  │ storage_ (kMaxDeviceStorage bytes)                         │
  │  ┌──────────┐  ┌──────────┐           ┌──────────┐        │
  │  │ proc 0   │  │ proc 1   │  ...      │ proc 15  │        │
  │  │ 256 B    │  │ 256 B    │           │ 256 B    │        │
  │  └──────────┘  └──────────┘           └──────────┘        │
  └────────────────────────────────────────────────────────────┘
  size_ = 6  (only 6 devices in this chain)
```

Each slot is `kMaxProcessorSize` (256) bytes. The layout is dense — no gaps. Slot `i` is at `storage_ + i * kMaxProcessorSize`.

Worst-case processor size (to determine `kMaxProcessorSize`):

| Processor | Approx sizeof | Key large member |
|-----------|--------------|------------------|
| FilterProcessor | ~48 | FilterRuntime (2 × BiquadState = 24) |
| FourBandEqProcessor | ~120 | FourBandEqRuntime (8 × BiquadState = 96) |
| FrequencyShifterProcessor | ~32 | FrequencyShifterRuntime (2 × double = 16) |
| DelayProcessor | ~24 | No inline buffers — only pointers + ints |
| ReverbProcessor | ~24 | Same |
| ChorusProcessor | ~24 | Same |
| PhaserProcessor | ~60 | 8 floats phaser states |
| SubtractiveSynthProcessor | ~900 | SubtractiveSynthRuntime (8 voices × ~100 bytes + stealIndex) |
| PhaseModSynthProcessor | ~1200 | PhaseModSynthRuntime (8 voices × 4 operators × ~35 bytes) |
| KickProcessor | ~52 | KickGeneratorRuntime (KickVoiceRuntime + int) |
| GateProcessor | ~12 | DynamicsRuntime (3 floats) |
| OscillatorProcessor | ~4 | float oscillatorPhase_ |
| SamplerProcessor | ~770 | BiquadState[32] (32 × 12 = 384) |
| **Largest**: PhaseModSynthProcessor | **~1200** | |

**kMaxProcessorSize must be at least 1280**. Round up to 1536 (0x600) for alignment safety.

---

## 3. Placement-New Rules

### Control Thread (safe to call placement-new)

- `ProcessorArena::emplace<T>()` — called from `buildProcessorChain()`
- `DeviceProcessor::initParams()` — called after emplacement
- Ring buffer assignment from `DeviceChainScratchArena::allocate()` — during initParams

### Audio Thread (NEVER call placement-new)

- `DeviceProcessor::process()` only
- `DeviceChainOrchestrator::processChain()` only

### Reset Lifecycle

```
1. Control thread detects device chain change
2. Control thread calls arena.reset()     — sets size_ = 0, no destructors called
3. Control thread calls ringBufferArena.reset() — marks all slots free
4. Control thread calls buildProcessorChain() for each new chain
5. Control thread publishes arena pointer (relaxed atomic store)
6. Audio thread starts using new arena    — no lock needed, arena is const after publication
```

---

## 4. Time-Based Effect Ring Buffer Contract

`TimeBasedEffectRuntime` (in Phase 1) heap-allocates two 192K float buffers per instance:

```cpp
struct TimeBasedEffectRuntime {
    float* bufferLeft = new float[192000]();  // HEAP ALLOC
    float* bufferRight = new float[192000]();
    int writeIndex = 0;
    float lfoPhase = 0.0f;
    // phaser states...
    ~TimeBasedEffectRuntime() { delete[] bufferLeft; delete[] bufferRight; }
};
```

In Phase 2, this heap allocation is replaced by the `DeviceChainScratchArena`:

```
DeviceChainScratch::ringBufferArena
  ┌─ slot 0 ────────────────────────────────┐
  │  storage[0][0] = float[192000]  (left)  │  ← assigned to DelayProcessor
  │  storage[0][1] = float[192000]  (right) │
  └──────────────────────────────────────────┘
  ┌─ slot 1 ────────────────────────────────┐
  │  storage[1][0] = float[192000]  (left)  │  ← assigned to ChorusProcessor
  │  storage[1][1] = float[192000]  (right) │
  └──────────────────────────────────────────┘
  ┌─ slot 2 ────────────────────────────────┐
  │  storage[2][0] = float[192000]          │  ← assigned to ReverbProcessor
  │  storage[2][1] = float[192000]          │
  └──────────────────────────────────────────┘
  ┌─ slot 3 ────────────────────────────────┐
  │  storage[3][0] = float[192000]          │  ← assigned to PhaserProcessor
  │  storage[3][1] = float[192000]          │
  └──────────────────────────────────────────┘
```

### Time-based processor member layout

```cpp
class DelayProcessor : public DeviceProcessor {
    // NOT own float[192000] — instead:
    float* bufferLeft_ = nullptr;    // set during initParams
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;
    // ...
};
```

During `initParams()`:
```cpp
void DelayProcessor::initParams(const DeviceVariantParams&) noexcept {
    auto [bufL, bufR] = scratch.ringBufferArena.allocate();
    bufferLeft_ = bufL;
    bufferRight_ = bufR;
    writeIndex_ = 0;
    lfoPhase_ = 0.0f;
    std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
    std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
}
```

The `DeviceChainScratch` is thread-local, so there's no contention on the ring buffer arena. The control thread zeroes the buffers during `reset()`.

---

## 5. Parameter Passing Contract

### Flow

```
DeviceNodePlayback (control thread snapshot)
  │
  ▼
buildProcessorChain()
  ├── for each DeviceNodePlayback:
  │     kind → switch → arena.emplace<ConcreteProcessor>()
  │     proc->bypassed = node.bypassed
  │     proc->meterSlot = node.meterSlot
  │     proc->initParams(node.params)   // stores device-specific state
  │
  ▼
Audio thread orchestrator loop:
  │   ProcessContext ctx(scratch);
  │   ctx.playheadBeat = ...;
  │   ctx.modulatedParams = &node.params;  // (or computed per-frame)
  │   ctx.notes = ...;
  │   ...
  │   for (i = 0; i < arena.size(); ++i) {
  │       ctx.deviceIndex = i;
  │       auto* proc = arena.get(i);
  │       AudioBlock block{trackL, trackR, frames};
  │       proc->process(block, ctx);
  │       // orchestrator applies perFrameGain and perFramePan here
  │   }
```

### Modulation and Automation Sub-Blocking

For processors that need sub-block evaluation (Oscillator, Sampler, SubtractiveSynth, PhaseModSynth), the behavior is **internal to the processor**:

```cpp
void OscillatorProcessor::process(AudioBlock& block, ProcessContext& ctx) noexcept {
    if (ctx.suppressInstruments) return;
    // ctx.needsSubBlocks was set by orchestrator
    if (ctx.needsSubBlocks) {
        for (int sub = 0; sub < block.numSamples; sub += kAutomationSubBlockFrames) {
            // evaluate automation at sub-block granularity
            auto subParams = dspParamsAtFrame(/* ... */);
            AudioBlock subBlock{block.channelL + sub, block.channelR + sub, subLen};
            // render into scratch, apply gain, mix into block
        }
    } else {
        // render full block
    }
}
```

The orchestrator sets `ctx.needsSubBlocks` and `ctx.modulatedParams` before calling `process()`.

---

## 6. Instrument Processor Rendering Contract

Instrument processors (Oscillator, Sampler, SubtractiveSynth, PhaseModSynth, Kick, Snare, Clap, Cymbal, Crash) render into `ctx.scratch.scratch` (mono), apply per-frame gain, then pan into the track buffer. This is an internal detail — the orchestrator does NOT apply gain/pan to instrument-rendered content because the pan is per-voice. However, the orchestrator's gain/pan DOES apply to the accumulated track buffer.

The contract:

1. Instrument processor clears `ctx.scratch.scratch`
2. Renders mono audio into scratch
3. Applies `ctx.scratch.perFrameGain` to scratch
4. Pans from scratch into `block` using `ctx.scratch.perFramePan`
5. Returns (orchestrator may apply additional track gain)

Non-instrument processors write directly to `block` and the orchestrator applies perFrameGain after.

---

## 7. Meter Publishing Contract

Dynamics and time-based processors publish meter data via relaxed atomic stores:

```cpp
// Example in GateProcessor::process():
if (ctx.deviceMeters != nullptr && meterSlot >= 0 && meterSlot < ctx.maxDeviceMeters) {
    float inputPeak = stereoBlockPeak(block.channelL, block.channelR, block.numSamples);
    ctx.deviceMeters[meterSlot].gainReductionDb.store(runtime_.gainReductionDb, std::memory_order_relaxed);
    ctx.deviceMeters[meterSlot].inputPeak.store(inputPeak, std::memory_order_relaxed);
}
```

No locks, no barriers — relaxed stores are sufficient for meter display (visible updates within ~100ms).

---

## 8. Removal of TrackPlaybackSnapshot Runtime Arrays

After Phase 2, `TrackPlaybackSnapshot` no longer contains:

```diff
- BiquadState samplerFilterStates[kMaxDevicesPerTrack * kMaxInstrumentRegions];
- SubtractiveSynthRuntime subtractiveRuntimes[kMaxDevicesPerTrack];
- KickGeneratorRuntime kickRuntimes[kMaxDevicesPerTrack];
- SnareGeneratorRuntime snareRuntimes[kMaxDevicesPerTrack];
- ClapGeneratorRuntime clapRuntimes[kMaxDevicesPerTrack];
- CymbalGeneratorRuntime cymbalRuntimes[kMaxDevicesPerTrack];
- CrashGeneratorRuntime crashRuntimes[kMaxDevicesPerTrack];
- PhaseModSynthRuntime phaseModRuntimes[kMaxDevicesPerTrack];
- DynamicsRuntime dynamicsRuntimes[kMaxDevicesPerTrack];
- TimeBasedEffectRuntime timeBasedRuntimes[kMaxDevicesPerTrack];
- float oscillatorPhase;
```

Replaced by:

```diff
+ ProcessorArena processorArena;
```

---

## 9. Byte-Identity Guarantee

Each OOP processor must produce **bit-identical output** to the Phase 1 static-method processor for the same inputs. The mapping is:

| Phase 1 | Phase 2 |
|---------|---------|
| `runtime = dynamicsRuntimes[deviceIndex]` | `runtime_` (member) |
| `runtime = timeBasedRuntimes[deviceIndex]` | `bufferLeft_`, `bufferRight_`, `writeIndex_`, `lfoPhase_` (members) |
| `runtime = filterRuntimes[deviceIndex]` | `runtime_` (member) |
| `oscillatorPhase` (ref param) | `oscillatorPhase_` (member) |
| `samplerFilterStates[deviceIndex * kMaxInstrumentRegions]` | `samplerFilterStates_` (member array) |
| `scratch.perFrameGain` multiply at end | Orchestrator applies after process() |

The only exception is gain/pan multiplication order: in Phase 1, each processor multiplied by `scratch.perFrameGain[]` internally. In Phase 2, the orchestrator does it after `process()`. This means the `perFrameGain` array must be identical before and after the processor call — which it is, since non-instrument processors don't modify `perFrameGain` or `perFramePan` during processing.