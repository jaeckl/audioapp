# Phase 5 — JUCE AudioProcessorGraph

> **Goal:** Evaluate whether to replace the custom `DeviceChainOrchestrator` with `juce::AudioProcessorGraph`. This is the lowest-priority phase — only justified if the custom chain becomes a bottleneck.

## Current State

Audio processing is orchestrated by `DeviceChainOrchestrator` — a custom loop that iterates `DeviceNodePlayback` array from `TrackPlaybackSnapshot`:

```cpp
// DeviceChainOrchestrator (simplified)
for (int i = 0; i < snap.deviceCount; ++i) {
    auto& node = snap.devices[i];
    switch (node.kind) {  // or virtual dispatch via DeviceProcessor
        case DeviceNodeKind::Oscillator:     oscProcess(node, buffer, ...); break;
        case DeviceNodeKind::Filter:         filterProcess(node, buffer, ...); break;
        case DeviceNodeKind::Compressor:     compProcess(node, buffer, ...); break;
        // ...
    }
}
```

## Problems with Custom Orchestrator

| Problem | Current | JUCE AudioProcessorGraph |
|---------|---------|--------------------------|
| Routing flexibility | Fixed chain, no sends/returns | Arbitrary graph with edge routing |
| Parallel processing | Not supported | Supported via parallel branches |
| Latency compensation | Hand-rolled | Built-in |
| Sidechain support | Not supported | Native support |
| Bypass processing | Manual bypass flag per device | `AudioProcessor::suspendProcessing(true)` |
| Tail / reverb handling | Manual tail management | Automatic tail calculation |
| Channel layout | Hardcoded mono/stereo | Dynamic layout negotiation |

## When The Custom Chain Hurts

The custom chain is **fine for MVP** with 3-4 devices per track in a fixed series. It becomes a problem when:

1. **Parallel routing** — user wants filter in parallel with dry path (need a splitter/merger)
2. **Sidechain compression** — compressor needs a second input from another track
3. **Dynamic routing** — sends/returns with variable amounts
4. **Complex plugin chains** — 8+ devices with bypass state changes during playback

## Design — Optional Migration

### A. Wrap Processors in juce::AudioProcessor

```cpp
class OscillatorProcessorNode : public juce::AudioProcessor {
    // ...
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&) override {
        // Existing oscillator DSP code
        oscillatorProcess(buffer, params_);
    }
};
```

JUCE 8's `AudioProcessorGraph` allows adding nodes (`createNode`) and connecting them (`addConnection`). The graph owns the nodes; the engine rebuilds the graph when the device chain changes.

### B. Integration with Current Architecture

The graph is built on the **control thread** and `prepareToPlay()`/`releaseResources()` are called on the audio thread:

```cpp
class ProjectEngine {
    // Optional: AudioProcessorGraph for tracks that need it
    // Default: DeviceChainOrchestrator for simple chains
    // Hybrid: AudioProcessorGraph for devices that need sidechain/routing
    std::unique_ptr<juce::AudioProcessorGraph> audioGraph_;
};
```

### C. Not a Replacement — An Opt-in

JUCE's `AudioProcessorGraph` has overhead (virtual dispatch per processor, graph traversal). For simple chains (oscillator → filter → gain), the current `DeviceChainOrchestrator` is **faster**. The migration is:

1. Keep `DeviceChainOrchestrator` as the default path
2. Add `juce::AudioProcessorGraph` as an alternative for chains that need routing
3. Auto-upgrade when user adds a send/return or sidechain

## Changes Required (if executed)

| File | Change |
|------|--------|
| Device processor wrappers | Create `juce::AudioProcessor` subclasses for each device |
| Graph builder | Build `juce::AudioProcessorGraph` from device chain |
| Mixing logic | Read main mix from graph output nodes |
| Bypass handling | Use `suspendProcessing()` |
| Latency handling | JUCE handles automatically |

## When NOT to Do This

- **If the project never needs parallel routing or sidechains** — skip this phase entirely
- **If performance of the custom chain is adequate** — the custom chain is simpler to debug and faster for simple chains
- **Before profiling shows this is a bottleneck** — measure first

## Effort Estimate

| Item | Days |
|------|------|
| Evaluate routing requirements | 0.5 |
| Wrap 5 primary device types as AudioProcessor | 2 |
| Graph builder + chain orchestrator | 2 |
| Integration with playback rebuild | 1 |
| Performance comparison | 1 |
| **Total** | **6.5** |

## Recommendation

**Defer.** The current `DeviceChainOrchestrator` is fast, simple, and sufficient for MVP. Revisit when implementing:

- Send/return tracks
- Sidechain compression
- Parallel filter routing
- More than ~8 devices per track

At that point, the custom orchestrator becomes a bottleneck and `juce::AudioProcessorGraph` is the right answer.