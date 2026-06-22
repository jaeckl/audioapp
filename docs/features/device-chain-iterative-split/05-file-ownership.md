# DeviceChain Iterative Split — File Ownership

This table is binding. Implementation workers may **only** edit the files
assigned to their work package. Two steps never edit the same file in the same
iteration — the design is sequential, not parallel.

## Files per work package

### Step 1 — Move `DeviceChainScratch` to a header

| File / path | Owner work package | Allowed changes | Forbidden changes |
|---|---|---|---|
| `engine_juce/include/audioapp/DeviceChainScratch.hpp` | Step 1 | **CREATE** (header-only POD struct + 2 constexpr). | Any non-POD member, any `inline` function, any `using namespace`. |
| `engine_juce/src/DeviceChain.cpp` | Step 1 | **DELETE** lines 25–44 (the struct definition + `thread_local gScratch;`). Add `#include "audioapp/DeviceChainScratch.hpp"` at top of file. Re-declare `thread_local DeviceChainScratch gScratch;` inside the anonymous namespace. | Anything else. No logic edits. No new functions. No reorder of remaining lines. |
| `engine_juce/CMakeLists.txt` | (not touched) | n/a | Step 1 adds no new compile target — `DeviceChainScratch.hpp` is header-only, picked up via existing `target_include_directories`. |
| `engine_juce/include/audioapp/DeviceChain.hpp` | (not touched) | n/a | Public API must not change. |

### Step 2 — Move automation/modulation helpers

| File / path | Owner work package | Allowed changes | Forbidden changes |
|---|---|---|---|
| `engine_juce/include/audioapp/DeviceChainAutomationModulation.hpp` | Step 2 | **CREATE** with all `applyModulation` overload declarations + `applyDspModulationAtFrame` + `dspParamsAtFrame` + `nodeNeedsSubBlocks` + `nodeUsesDspAutomationSubBlocks` + `nodeHasDspModulation`. | No logic, no `inline` definitions, no `using namespace`. |
| `engine_juce/src/DeviceChainAutomationModulation.cpp` | Step 2 | **CREATE** with all moved bodies (verbatim from HEAD lines 79–362, 392–416, 418–435, 437–467, 469–492, 494–506). | No function signature changes. No math changes. No reordering of cases. |
| `engine_juce/src/DeviceChain.cpp` | Step 2 | **DELETE** the 22 `applyModulation` overload bodies (HEAD lines 79–362), `applyDspModulationAtFrame` (392–416), `dspParamsAtFrame` (418–435), `nodeNeedsSubBlocks` (437–467), `nodeUsesDspAutomationSubBlocks` (469–492), `nodeHasDspModulation` (494–506). Add `#include "audioapp/DeviceChainAutomationModulation.hpp"` and `using namespace audioapp::DeviceChainAutomationModulation;` inside the anonymous namespace. | Any logic change. Any reordering. Any new helper. |
| `engine_juce/CMakeLists.txt` | Step 2 | **ADD** `src/DeviceChainAutomationModulation.cpp` to the `add_library(audioapp_engine STATIC ...)` source list (alphabetically with the others, e.g. between `src/DeviceChain.cpp` and `src/devices/DeviceRegistry.cpp`). | Anything else. |
| `engine_juce/include/audioapp/DeviceChainScratch.hpp` | (not touched in Step 2) | n/a | Step 2 may include it transitively but must not edit it. |
| `engine_juce/include/audioapp/DeviceChain.hpp` | (not touched in Step 2) | n/a | n/a |

### Step 3 — Extract per-device dispatcher

| File / path | Owner work package | Allowed changes | Forbidden changes |
|---|---|---|---|
| `engine_juce/include/audioapp/DeviceChainProcessor.hpp` | Step 3 | **CREATE** with `processDeviceNode` declaration only. | No logic. No other function. |
| `engine_juce/src/DeviceChainProcessor.cpp` | Step 3 | **CREATE** with the `switch (node.kind) { … }` block from HEAD lines 687–1257 verbatim, wrapped inside `void processDeviceNode(...) noexcept { switch (node.kind) { … } }`. | Any signature change. Any case reorder. Any math change. Any new helper. |
| `engine_juce/src/DeviceChain.cpp` | Step 3 | **REPLACE** the `switch (node.kind) { … }` block (HEAD lines 686–1257) inside `processDeviceChain` with a single call to `audioapp::DeviceChainProcessor::processDeviceNode(...)` passing every parameter that was in scope. | Any other change. The outer `for (int deviceIndex = 0; …)` loop, automation/LFO/modulation blocks, and `s.perFrameGain` / `s.perFramePan` initialization must remain in `DeviceChain.cpp`. |
| `engine_juce/CMakeLists.txt` | Step 3 | **ADD** `src/DeviceChainProcessor.cpp` to the source list (after `src/DeviceChainAutomationModulation.cpp`). | Anything else. |
| `engine_juce/include/audioapp/DeviceChainScratch.hpp` | (read-only in Step 3) | n/a | Step 3 includes it transitively. |
| `engine_juce/include/audioapp/DeviceChainAutomationModulation.hpp` | (read-only in Step 3) | n/a | Step 3 may use it but must not edit it. |

### Step 4 — Slim `processDeviceChain` to orchestration only

| File / path | Owner work package | Allowed changes | Forbidden changes |
|---|---|---|---|
| `engine_juce/src/DeviceChain.cpp` | Step 4 | **REDUCE** body of `processDeviceChain` to orchestration-only glue (≤50 LOC plus namespace + 3 classifier helpers). Optionally inline the 3 trivial classifier helpers (`isDynamicsDeviceNodeKind`, `isInstrumentDeviceNodeKind`, `isFrequencyFxDeviceNodeKind`) since they are already 1 line each. | Any change to `processDeviceChain`'s signature in the header. Any change to scratch handling. Any change to the LFO/automation/modulation sub-blocks. |
| `engine_juce/include/audioapp/DeviceChain.hpp` | (not touched in Step 4) | n/a | The signature `processDeviceChain(...)` is **frozen** by Step 4's test gate. |
| All other files | (not touched in Step 4) | n/a | Step 4 introduces no new files and no new symbols. |

## Cross-step file sharing

| File | Created by | Used by | Care required |
|---|---|---|---|
| `DeviceChainScratch.hpp` | Step 1 | Step 2 (transitively), Step 3 (explicitly) | Once moved, no step may add `inline` methods or a constructor. Field order is frozen. |
| `DeviceChainAutomationModulation.hpp` | Step 2 | Step 3 (transitively, for `nodeNeedsSubBlocks` etc.) | Once declared, Step 3 may not change overload signatures. |
| `DeviceChainProcessor.hpp` | Step 3 | Step 4 (`DeviceChain.cpp` calls `processDeviceNode`) | Step 4 must pass every parameter that `processDeviceNode` declares. |
| `DeviceChain.cpp` | Steps 1, 2, 3, 4 all touch | The single-threaded sequence guarantees no concurrent edit. | Step N may only delete lines added by Step N; no re-adds. |

## Files that **must not** be touched by any step

- `engine_juce/include/audioapp/DeviceChain.hpp` — public API frozen.
- `engine_juce/include/audioapp/AutomationTypes.hpp` — existing types
  (`ModulationEdgePlayback`, `AutomationClipPlayback`,
  `kEncodedCommonGain`, `kEncodedCommonPan`) frozen.
- `engine_juce/include/audioapp/AutomationPlayback.hpp` — existing free
  functions (`evaluateAutomationEnvelope`, `nodeHasDspAutomation`,
  `applyDspAutomationAtBeat`, `applyAutomationValue`) frozen.
- `engine_juce/src/AutomationPlayback.cpp` — not in scope.
- All `*DeviceType.cpp`, `*Generator*.cpp`, `*Synth*.cpp`, `*Processor*.cpp` —
  not in scope.
- `engine_juce/src/EngineHost*.cpp`, `engine_juce/src/LivePerformance.cpp`,
  `engine_juce/src/ProjectEngine*.cpp` — not in scope.
- `engine_juce/include/audioapp/EngineHost.hpp` — not in scope.
- `native_bridge/src/BridgeHost.cpp` — not in scope (but the existing
  `processDeviceChain` signature must continue to satisfy its caller).
- All test files — not in scope. Tests are the gate, not the target.

## CMake changes summary

After all 4 steps, `engine_juce/CMakeLists.txt` adds 2 source files:

```cmake
add_library(audioapp_engine STATIC
  ...
  src/DeviceChain.cpp
  src/DeviceChainAutomationModulation.cpp   # Step 2
  src/DeviceChainProcessor.cpp               # Step 3
  ...
)
```

`DeviceChainScratch.hpp` is header-only and requires no CMake change.

## Notes on the "shrinking" property

`DeviceChain.cpp` LOC count after each step (approximate):

| Step | LOC of DeviceChain.cpp | Δ |
|---|---|---|
| HEAD | 1261 | — |
| After Step 1 | ~1242 | -19 (scratch block removed) |
| After Step 2 | ~950 | -290 (applyModulation overloads + helpers moved) |
| After Step 3 | ~350 | -600 (switch block moved to dispatcher) |
| After Step 4 | ≤50 | -300 (in-process LFO/automation modulation logic moved into dispatcher glue; only the orchestrator loop + per-frame gain/pan LFO modulation remains in DeviceChain.cpp) |

**Step 4's extra reduction** comes from the fact that the orchestrator's
LFO modulation of common gain/pan (HEAD lines 666–684) is logically a
"per-node envelope setup" operation that can live in a new helper in
`DeviceChainProcessor.cpp`. This is the only deviation from the simple
"switch-block extraction" model: in Step 3 the dispatcher is given the
already-resolved `modulatedParams`, but the per-frame gain/pan LFO modulation
must happen *between* the orchestrator's automation clip loop and the
dispatcher call. To keep the dispatcher pure, Step 4 introduces a tiny
helper `applyCommonGainPanLfo(...)` in `DeviceChainProcessor.{hpp,cpp}`
called by `DeviceChain.cpp` after the per-node LFO modulation block. The
helper is **added in Step 3** (in the same TU as `processDeviceNode`),
not invented in Step 4.

Wait — this contradicts the "Step 3 only adds the dispatcher" rule. The
correct split:

- **Step 3** adds `DeviceChainProcessor.{hpp,cpp}`. The header declares
  both `processDeviceNode` and the helper `applyCommonGainPanLfo`. The `.cpp`
  defines both.
- **Step 4** uses the helper from `DeviceChain.cpp`.

The helper's signature is exactly the body of HEAD lines 666–684 lifted
verbatim:

```cpp
void applyCommonGainPanLfo(
    const ModulationEdgePlayback* modEdges,
    int modEdgeCount,
    const float* lfoValues,
    int lfoCount,
    int framesToProcess,
    int deviceIndex,
    DeviceChainScratch& scratch) noexcept;
```

This is recorded here for completeness; it does not change the file
ownership table above (Step 3 owns both files, Step 4 only calls the
helper from `DeviceChain.cpp`).
