# OOP Device Processors Phase 2 — Feature Brief

## Summary

Transform the 22 static-method processor classes (created in Phase 1) into true stateful OOP objects with virtual dispatch, a `ProcessContext` struct, an `AudioBlock` wrapper, and a lock-free preallocated arena (`ProcessorArena`) — eliminating all parallel runtime arrays (e.g. `DynamicsRuntime[]`, `TimeBasedEffectRuntime[]`, `FilterRuntime[]`, etc.) and the 22-way `switch`-case dispatcher in `DeviceChainProcessor.cpp`.

## Today’s Problem (end of Phase 1)

Phase 1 extracted the procedural DSP into separate files but preserved the **stateless adapter pattern**:

```
// Each processor is a "class-shaped namespace":
class FilterProcessor {
public:
    static void process(
        int deviceIndex,
        float* trackLeft, float* trackRight, int frames,
        double sampleRate,
        const DeviceVariantParams& params,
        DeviceChainScratch& scratch,
        FilterRuntime* filterRuntimes  // external parallel array!
    ) noexcept;
};
```

Problems remaining:

1. **9 parallel runtime arrays** live in `TrackPlaybackSnapshot` (`subtractiveRuntimes[16]`, `dynamicsRuntimes[16]`, `timeBasedRuntimes[16]`, `filterRuntimes[16]`, `fourBandEqRuntimes[16]`, `frequencyShifterRuntimes[16]`, `kickRuntimes[16]`, etc.). Each is sized `kMaxDevicesPerTrack` (16), allocated even for tracks that don't use those processor types.

2. **22-way switch-case** in `processDeviceNode` dispatches by `DeviceNodeKind`. Adding a new device type touches this switch, the enum, AND the `DeviceVariantParams` variant.

3. **Mammoth function signature**: `processDeviceNode` takes 33 parameters. `processDeviceChain` takes 38. Every addition to the processing loop bloats both.

4. **Runtime state is external**: `FilterRuntime`, `DynamicsRuntime`, `TimeBasedEffectRuntime`, `oscillatorPhase`, `FourBandEqRuntime`, `FrequencyShifterRuntime`, `SubtractiveSynthRuntime`, `KickGeneratorRuntime` etc. are all owned by the caller and passed as pointers. Processor logic and its runtime state are separated by files, functions, and array indices.

5. **Parameter conversion happens outside**: `DeviceVariantParams` is `std::variant` — each processor calls `std::get<T>()` to unpack. When the variant grows, every processor file must recompile.

## Vision (end of Phase 2)

```
// True OOP — state is inside the object:
class FilterProcessor : public DeviceProcessor {
    FilterRuntime runtime_;  // embedded state
public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Filter; }
};
```

The orchestrator loop in `DeviceChain.cpp` becomes:

```
for (int i = 0; i < arena.size(); ++i) {
    auto* proc = arena.get(i);
    AudioBlock block{trackLeft, trackRight, frames};
    ProcessContext ctx = /* ... populated once per block ... */;
    ctx.deviceIndex = i;
    proc->process(block, ctx);
    applyGainPan(block, ctx);  // common gain/pan, not duplicated per processor
}
```

No switch-case. No parallel runtime arrays. No 33-parameter function.

## Success Metrics

- `DeviceChainProcessor.cpp` is **deleted**. Its function is replaced by the orchestrator loop in `DeviceChain.cpp`.
- Zero parallel runtime arrays in `TrackPlaybackSnapshot` — all state lives inside `DeviceProcessor` subclasses in the `ProcessorArena`.
- `ProcessContext` reduces the per-processor call to 2 parameters: `(AudioBlock&, ProcessContext&)`.
- All 22 processors convert to OOP and produce **byte-identical** output to Phase 1.
- Adding a new processor requires: (1) new subclass, (2) register it in the factory. No switch-case, no variant, no parallel array.
- ProcessorArena is lock-free and zero-alloc on the audio thread (all placement-new happens on the control thread).