# OOP Device Processors Phase 2 — Integration Plan

## Step-by-Step Integration Order

### Phase 2a: Pre-Refactor Baseline

```bash
# 1. Verify current code compiles
cmake -S engine_juce -B build/engine -G Ninja -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++
cmake --build build/engine --target audioapp_engine

# 2. Capture snapshot
python tools/snapshot_test.py docs/features/oop-device-processors-phase2/baseline.txt

# 3. Run tests
cmake --build build/engine --target audioapp_juce_tests
./build/engine/audioapp_juce_tests
```

---

### Step 1: P0 — Infrastructure

**Goal**: Add DeviceProcessor, AudioBlock, ProcessContext, ProcessorArena, DeviceChainOrchestrator (empty), DeviceChainScratchArena. Compiles but old path still active.

**Order**:
1. Create `AudioBlock.hpp` — standalone struct, no dependencies on other new types
2. Create `ProcessContext.hpp` — depends on `AudioBlock` (no), `DeviceChainScratch`, `DeviceChain`, `AutomationTypes`
3. Create `DeviceProcessor.hpp` — depends on `AudioBlock`, `ProcessContext`, `DeviceChain`
4. Create `ProcessorArena.hpp` — depends on `DeviceProcessor`, `DeviceChain` (kMaxDevicesPerTrack)
5. Create `ProcessorArena.cpp` — static assertion for max processor size
6. Modify `DeviceChainScratch.hpp` — add `DeviceChainScratchArena` + `ringBufferArena` member
7. Create `DeviceChainOrchestrator.hpp` — forward declarations only
8. Create `DeviceChainOrchestrator.cpp` — empty `processChain()` stub
9. Update `CMakeLists.txt` — add new .cpp files
10. Compile and verify

**Verification**: `cmake --build build/engine --target audioapp_engine` succeeds.

---

### Step 2: P1-P6 — Processor Migration (Parallel)

**Execute P1, P2, P3, P4, P5, P6 in parallel**.

Each package:
1. Modify .hpp: change class declaration to inherit from `DeviceProcessor`
2. Add runtime state as private members
3. Implement `process(AudioBlock&, ProcessContext&)` with the same DSP logic as Phase 1 static method
4. Implement `kind()` returning the appropriate `DeviceNodeKind`
5. Modify .cpp: move existing logic into `process()`, referencing members instead of external arrays

**Verification per package**: `cmake --build build/engine --target audioapp_engine` with the package's specific processor .cpp files compiles. (Full link may fail until P7 — but compilation of individual translation units must succeed.)

**For P5 (time-based) specifically**:
1. Remove `#include <audioapp/DeviceChain.hpp>` (which brings in `TimeBasedEffectRuntime`)
2. Add `#include <audioapp/DeviceChainScratch.hpp>` (for `ringBufferArena`)
3. Change member declaration from `TimeBasedEffectRuntime* timeBasedRuntimes` parameter to `float* bufferLeft_; float* bufferRight_; int writeIndex_; float lfoPhase_`
4. In `initParams()`, call `allocate()` from `ctx.scratch.ringBufferArena` (but `initParams` receives `DeviceVariantParams&`, not `ProcessContext` — the ring buffer arena lives in `DeviceChainScratch`, which is thread-local. Since `initParams` is called on the control thread, we need access to the scratch. See Step 2a below.)

#### Step 2a: Ring Buffer Allocation in initParams

P5's ring buffer allocation needs special handling because `initParams()` runs on the control thread but the arena is in the thread-local `DeviceChainScratch`. Solution: pass a `DeviceChainScratch*` to `buildProcessorChain()`:

```cpp
// In DeviceChainOrchestrator.cpp:
int buildProcessorChain(
    const DeviceNodePlayback* devices, int deviceCount,
    ProcessorArena& arena,
    DeviceChainScratch& scratch) noexcept  // <-- for ring buffer allocation
{
    arena.reset();
    scratch.ringBufferArena.reset();
    for (int i = 0; i < deviceCount; ++i) {
        DeviceProcessor* proc = nullptr;
        switch (devices[i].kind) {
            case DeviceNodeKind::Delay:
                // Emplace + pass scratch for ring buffer
                // initParams gets the variant params only
                // But we need scratch for ring buffer allocate...
                break;
            // ...
        }
    }
}
```

However, `initParams()` only receives `DeviceVariantParams&`. The ring buffer arena is in `DeviceChainScratch`. Solution: have time-based processors call a helper to get scratch during `initParams()`. Since `initParams` runs on the control thread, we can pass scratch as a second parameter:

**Revised contract for time-based processors** — override a separate hook:

```cpp
class DelayProcessor : public DeviceProcessor {
    float* bufferLeft_ = nullptr;
    float* bufferRight_ = nullptr;
    int writeIndex_ = 0;
    float lfoPhase_ = 0.0f;
public:
    void initParams(const DeviceVariantParams&) noexcept override {
        // Does NOT allocate ring buffers — they're allocated in a separate step
        // because scratch isn't accessible from initParams.
    }

    /// Called on control thread after initParams, with scratch access.
    void initRingBuffers(DeviceChainScratch& scratch) noexcept {
        if (bufferLeft_ != nullptr) return;  // already allocated
        auto [bufL, bufR] = scratch.ringBufferArena.allocate();
        bufferLeft_ = bufL;
        bufferRight_ = bufR;
        writeIndex_ = 0;
        lfoPhase_ = 0.0f;
        if (bufferLeft_) {
            std::memset(bufferLeft_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
            std::memset(bufferRight_, 0, DeviceChainScratchArena::kBufferSize * sizeof(float));
        }
    }
};
```

**Alternative**: Make `DeviceChainScratch` globally accessible (it's thread-local, so it's already accessible via `gScratch` in DeviceChain.cpp). The time-based `initParams` can access it via a global getter:

```cpp
// In DeviceChainScratch.hpp:
DeviceChainScratch& getScratch() noexcept;
// Implementation: returns the thread-local instance.

void DelayProcessor::initParams(const DeviceVariantParams&) noexcept {
    auto& scratch = getScratch();
    auto [bufL, bufR] = scratch.ringBufferArena.allocate();
    // ... same as above
}
```

**Decision**: Use the global getter approach for `initParams()` in time-based processors. This allows `initParams` to remain a single-parameter override without changing the base class interface.

---

### Step 3: P7 — Integration (Sequential, after P1-P6)

1. **Implement `buildProcessorChain()`** in `DeviceChainOrchestrator.cpp`:

```cpp
int buildProcessorChain(
    const DeviceNodePlayback* devices, int deviceCount,
    ProcessorArena& arena,
    DeviceChainScratch& scratch) noexcept
{
    arena.reset();
    scratch.ringBufferArena.reset();

    for (int i = 0; i < deviceCount; ++i) {
        const auto& node = devices[i];
        if (node.bypassed) continue;

        DeviceProcessor* proc = nullptr;
        switch (node.kind) {
            case DeviceNodeKind::Filter:           proc = arena.emplace<FilterProcessor>(); break;
            case DeviceNodeKind::Gate:             proc = arena.emplace<GateProcessor>(); break;
            case DeviceNodeKind::Delay:            proc = arena.emplace<DelayProcessor>(); break;
            case DeviceNodeKind::Oscillator:       proc = arena.emplace<OscillatorProcessor>(); break;
            // ... all 22 kinds ...
            default: break;
        }

        if (proc) {
            proc->bypassed = node.bypassed;
            proc->meterSlot = node.meterSlot;
            proc->initParams(node.params);
        }
    }
    return arena.size();
}
```

Note: A switch-case is still needed here, but it's a **factory** switch (one line per type, no DSP logic). This is acceptable — it's called on the control thread and is not performance-critical.

2. **Implement `DeviceChainOrchestrator::processChain()`**:

```cpp
void DeviceChainOrchestrator::processChain(Context& ctx) noexcept {
    auto& arena = ctx.arena;
    auto& scratch = ctx.scratch;
    const int frames = ctx.numFrames;

    for (int i = 0; i < arena.size(); ++i) {
        auto* proc = arena.get(i);
        if (proc->bypassed) continue;

        const auto& node = /* need node from original devices array */;

        // Build per-frame gain/pan arrays
        for (int f = 0; f < frames; ++f) {
            scratch.perFrameGain[f] = node.gain;
            scratch.perFramePan[f] = node.pan;
        }

        // Apply timeline automation to perFrameGain/Pan if needed
        // Apply LFO modulation to perFrameGain/Pan
        applyCommonGainPanLfo(scratch, i, frames,
            ctx.lfoValues, ctx.lfoCount,
            ctx.modEdges, ctx.modEdgeCount);

        // Build process context
        ProcessContext pctx(scratch);
        pctx.lfoValues = ctx.lfoValues;
        pctx.lfoCount = ctx.lfoCount;
        pctx.modEdges = ctx.modEdges;
        pctx.modEdgeCount = ctx.modEdgeCount;
        pctx.automationClips = ctx.automationClips;
        pctx.automationClipCount = ctx.automationClipCount;
        pctx.notes = ctx.notes;
        pctx.noteCount = ctx.noteCount;
        pctx.playheadBeat = ctx.playheadStartBeat;
        pctx.bpm = ctx.bpm;
        pctx.sampleRate = ctx.sampleRate;
        pctx.suppressInstruments = ctx.suppressInstruments;
        pctx.deviceMeters = ctx.deviceMeters;
        pctx.maxDeviceMeters = ctx.maxDeviceMeters;
        pctx.deviceIndex = i;
        pctx.modulatedParams = &node.params;  // needs per-frame evaluation for sub-block

        // Process
        AudioBlock block{ctx.trackLeft, ctx.trackRight, frames};
        proc->process(block, pctx);

        // Apply common gain/pan (orchestrator responsibility)
        for (int f = 0; f < frames; ++f) {
            const float angle = std::clamp(scratch.perFramePan[f], 0.0f, 1.0f) * 1.57079632679f;
            ctx.trackLeft[f] *= scratch.perFrameGain[f];
            ctx.trackRight[f] *= scratch.perFrameGain[f];
            // Note: non-instrument processors write directly to trackLeft/Right
            // Instrument processors mix via scratch + perFramePan already
        }
    }
}
```

3. **Update `ProjectEngine.hpp`** — remove all parallel runtime arrays, add `ProcessorArena processorArena;` to `TrackPlaybackSnapshot`.

4. **Update `ProjectEngine.cpp`** — replace the old `processDeviceChain(...)` call with:

```cpp
// Before processDeviceChain call:
buildProcessorChain(track.devices, track.deviceCount,
    trackPlayback_[trackIndex].processorArena, gScratch);

DeviceChainOrchestrator::Context octx(
    trackPlayback_[trackIndex].processorArena, gScratch);
octx.trackLeft = trackLeft;
octx.trackRight = trackRight;
octx.numFrames = framesToProcess;
// ... populate other fields ...
DeviceChainOrchestrator::processChain(octx);
```

5. **Update `DeviceChainProcessor.cpp`** — either:
   - Option A: Mark `processDeviceNode` as deprecated and have it delegate to the orchestrator (backward compat), OR
   - Option B: Remove the switch-case entirely (clean break, but breaks any test that calls `processDeviceNode` directly)

   **Recommended**: Option A for the transition period. After all callers migrate, delete `DeviceChainProcessor.cpp` in a follow-up cleanup phase.

6. Build and test everything.

---

### Step 4: Final Verification

```bash
# Full compile
cmake --build build/engine --target audioapp_engine
cmake --build build/engine --target audioapp_juce_tests

# Run all tests
./build/engine/audioapp_juce_tests

# Snapshot comparison
python tools/snapshot_test.py docs/features/oop-device-processors-phase2/final.txt
powershell Compare-Object (Get-Content baseline.txt) (Get-Content final.txt)
```

---

## Rollback Plan

If any test fails:

1. Disable the `#include "DeviceChainOrchestrator.hpp"` and restore the old `processDeviceChain()` path (keep both paths in parallel)
2. The old path still works because all processor .hpp files still expose the static `process()` methods for backward compat (they can coexist with the new OOP `process()` during transition)
3. Fix the failing processor, re-enable the new path, retest

## Contract Gaps & Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `initParams()` for time-based processors needs scratch access | P5 can't allocate ring buffers | Use global thread-local scratch getter (see Step 2a) |
| Byte-identical output if gain/pan ordering changes | Tests fail | Orchestrator must apply perFrameGain/pan exactly as processors did internally |
| `DeviceChainProcessor.cpp` still included and used by tests | Dual maintenance | Keep old `processDeviceNode` as delegating wrapper |
| Processor subclass size exceeds `kMaxProcessorSize` | Arena overflow | Verify with static_assert in `ProcessorArena.cpp` |
| SubtractiveSynth/PhaseModSynth runtime sizes (largest) | May exceed 256B estimate | Increase `kMaxProcessorSize` to 1536 based on analysis in data contracts |