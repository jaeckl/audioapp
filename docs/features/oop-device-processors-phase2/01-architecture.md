# OOP Device Processors Phase 2 — Architecture Contract

## Architectural Goal

Replace the stateless processor adapter pattern (static methods + parallel runtime arrays + switch-case dispatcher) with true virtual dispatch over stateful `DeviceProcessor` subclass instances held in a lock-free preallocated arena.

## Design Patterns & Core Decisions

### 1. Abstract Base Class + Virtual Dispatch

```
DeviceProcessor (abstract)
  ├── TrackGainProcessor
  ├── OscillatorProcessor
  ├── SamplerProcessor
  ├── SubtractiveSynthProcessor
  ├── PhaseModSynthProcessor
  ├── KickProcessor
  ├── SnareProcessor
  ├── ClapProcessor
  ├── CymbalProcessor
  ├── CrashProcessor
  ├── GateProcessor
  ├── CompressorProcessor
  ├── ExpanderProcessor
  ├── LimiterProcessor
  ├── DelayProcessor
  ├── ReverbProcessor
  ├── ChorusProcessor
  ├── PhaserProcessor
  ├── FilterProcessor
  ├── FourBandEqProcessor
  ├── FrequencyShifterProcessor
  └── BassSynthProcessor (delegates to SubtractiveSynthProcessor)
```

Virtual methods are called from the audio thread. Each subclass's `process()` is a leaf function that the compiler can devirtualize when the call site goes through a known concrete type. The arena's `get()` returns `DeviceProcessor*` — the vtable lookup cost (~2 cycles) is acceptable for 1–16 calls per audio block.

### 2. Arena Ownership Model

- **ProcessorArena** is a fixed-capacity, placement-new arena. It is populated on the **control thread** when the device chain changes.
- Once populated, the arena is **read-only** on the audio thread — no thread-safe resizing, no locking.
- The control thread resets the arena and re-populates it atomically.
- All memory is POD or has trivial destructors (or explicitly no destruction — the arena is recycled without calling destructors, which is safe because all runtime state is POD and will be re-initialized via `initParams`).

### 3. ProcessContext — A Single Aggregated Parameter Object

All the parameters that were scattered across the 33-parameter `processDeviceNode` signature are consolidated into `ProcessContext`:

- Scratch buffers (from `DeviceChainScratch`)
- LFO outputs and modulation edges
- Automation clips
- MIDI notes
- Timeline state (playhead, BPM, sample rate)
- Device meters
- Current device index (fills automatically in the orchestrator loop)

### 4. AudioBlock — A Thin Stereo Buffer Wrapper

Instead of `(float* left, float* right, int frames)` triples, every processor receives an `AudioBlock&`. This prevents buffer-pointer confusion and enables `clear()`, `addFrom()`, and future multi-channel support without signature changes.

### 5. Common Gain/Pan Centralized

Each Phase 1 processor independently multiplied by `scratch.perFrameGain[]` at the end of its `process()`. In Phase 2, the orchestrator applies gain/pan AFTER the processor call, eliminating duplication. Processors that need custom gain behavior (instruments that synthesize into scratch then pan) handle their own pan but do NOT multiply the output buffer by `scratch.perFrameGain[]` — that happens in the orchestrator.

Exceptions:
- Instrument processors (Oscillator, Sampler, SubtractiveSynth, PhaseModSynth, Kick, Snare, Clap, Cymbal, Crash) render into `scratch.scratch`, apply per-frame gain, then mix into the track via stereo pan. This is preserved as custom internal behavior. The orchestrator's common gain/pan still applies to the track buffer after mix-down.

### 6. No Virtual Destructors

`DeviceProcessor` has **no virtual destructor**. The arena recycles memory without calling destructors — all runtime state is POD. This is a deliberate real-time safety choice:

- The arena's `reset()` simply sets `size_ = 0` and repurposes the same raw storage.
- On the next `emplace<>()` call, placement-new overwrites the old memory.
- Processors that hold resources (like `TimeBasedEffectRuntime`'s heap-allocated buffers) must move those to a dedicated arena in `DeviceChainScratch` (see data contracts).

### 7. Threading & Real-Time Safety

- **Control thread**: arena emplacement, `initParams()` calls, parameter conversion.
- **Audio thread**: `process()` calls only. No allocations, no locks, no I/O.
- The arena pointer is published via a relaxed atomic after the control thread finishes population.

### 8. Folder Structure

No changes to the Phase 1 folder layout:

| Layer | Path |
|-------|------|
| Abstract base | `engine_juce/include/audioapp/devices/processors/DeviceProcessor.hpp` |
| Arena | `engine_juce/include/audioapp/devices/processors/ProcessorArena.hpp` |
| ProcessContext | `engine_juce/include/audioapp/devices/processors/ProcessContext.hpp` |
| AudioBlock | `engine_juce/include/audioapp/devices/processors/AudioBlock.hpp` |
| Concrete processors | `engine_juce/include/audioapp/devices/processors/*.hpp` (same files, new class hierarchy) |
| Processor implementations | `engine_juce/src/devices/processors/*.cpp` (same files, rewritten to subclass) |

### 9. Orchestrator Loop (replaces `processDeviceNode`)

New loop in `DeviceChain.cpp`:

```cpp
void processDeviceChain(audioapp::DeviceChainOrchestrator::Context& ctx) noexcept {
    auto& arena = ctx.arena;
    auto& scratch = ctx.scratch;
    ProcessContext pctx;
    // populate pctx from ctx once per block...
    for (int i = 0; i < arena.size(); ++i) {
        auto* proc = arena.get(i);
        if (proc->bypassed()) continue;
        AudioBlock block{trackLeft, trackRight, numFrames};
        pctx.deviceIndex = i;
        proc->process(block, pctx);
        applyGainPan(block, scratch, pctx.deviceIndex);
    }
}
```

No switch-case. No parallel arrays. No 33-parameter function call.

## Non-Goals

- Changing the `processDeviceChain` public API signature in `DeviceChain.hpp`. The existing `processDeviceChain(...)` function is kept as a **thin wrapper** that constructs the arena context and delegates to the new loop. (Eventually it can be deprecated.)
- Changing the `DeviceNodePlayback`, `DeviceVariantParams`, or any control-thread data structures.
- Moving device type factory/instantiation logic into the processor layer — `DeviceSlot`/`IDeviceType` still owns parameter conversion.