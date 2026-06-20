# Vertical Work Packages

## WP1: Per-Device Serialization Extraction

**Behavior:** Extract device-specific serialization from `ProjectJson.cpp` into
per-device serializer files. The `deviceToVar()`/`deviceFromVar()` dispatch
remains in `ProjectJson.cpp` but calls per-type functions.

| Property | Value |
|----------|-------|
| **Parallel-safe** | YES (with WP2, WP4) |
| **Sequential after** | WP3 (same file: ProjectJson.cpp) |
| **Files created** | 14 serializer `.hpp` files |
| **Files modified** | 1 (`ProjectJson.cpp`) |
| **Risk** | Low — mechanical code extraction |

### Implementation steps:

1. Create directory `engine_juce/include/audioapp/devices/serialization/`
2. For each device type, create a serializer `.hpp` file
3. Each serializer file contains:
   - One `*ToVar(const DeviceState&) → juce::var` function
   - One `*FromVar(const juce::var&) → DeviceState` function
   - Exact copy of the corresponding `if (device.type == "...")` block from
     `ProjectJson.cpp`, including all legacy compatibility fallbacks
4. In `ProjectJson.cpp`:
   - Add `#include` for each serializer
   - Replace inline `deviceToVar` body with dispatch table
   - Replace inline `deviceFromVar` body with dispatch table
5. Verify compilation, run all tests

### Worker instructions:

Implementation agents must:
- Copy serialization code EXACTLY — every `setProperty` key, every
  `varToFloat` fallback, every `hasProperty` check must be preserved
- NOT change the JSON output format
- NOT add or remove fields
- NOT touch any other file
- NOT invent new function signatures
- Keep all `namespace audioapp {` — do not use nested namespaces

---

## WP2: Per-Device Process Extraction

**Behavior:** Extract the body of each `case DeviceNodeKind::*` in
`processDeviceChain()` into a per-device `process*Node()` function.
`processDeviceChain()` becomes a dispatch that calls these functions.

| Property | Value |
|----------|-------|
| **Parallel-safe** | YES (with WP1, WP4) |
| **Sequential after** | Nothing |
| **Files created** | 14 process `.cpp` files |
| **Files modified** | 1 (`DeviceChain.cpp`) |
| **Risk** | Medium — must preserve realtime safety |

### Implementation steps:

1. For each `case DeviceNodeKind::*` in `processDeviceChain()`:
   - Extract the body into `void process*Node(...)` in a new `.cpp` file
   - Declare the function in `DeviceChain.hpp` or in individual process headers
2. Replace each `case` body with a single call to the extracted function
3. Keep the `applyModulation()` overloads in `DeviceChain.cpp` (anonymous
   namespace) — they are already cleanly factored
4. Keep the `applyDspModulationAtFrame`, `applyDspAutomationAtBeat`,
   `dspParamsAtFrame`, `nodeNeedsSubBlocks`, `nodeHasDspModulation`,
   `applyAutomationValue`, and similar helper functions in `DeviceChain.cpp`
5. Verify compilation, run all tests, verify audio output

### Which helpers stay vs move:

| Helper | Stays in DeviceChain.cpp | Moves to per-device file |
|--------|------------------------|-------------------------|
| `applyModulation(Params&, amount, localParamId)` | YES (used by dispatch) | Only declarations need to be visible |
| `applyDspModulationAtFrame` | YES | NO |
| `applyDspAutomationAtBeat` | YES (in AutomationPlayback.cpp) | NO |
| `dspParamsAtFrame` | YES | NO |
| `nodeNeedsSubBlocks` | YES | NO |
| `nodeHasDspModulation` | YES | NO |
| Per-device DSP body (addSineBlock, mixSamplerMidiNotesBlock, etc.) | NO | YES — the extracted function |

### Worker instructions:

Implementation agents must:
- Extract the EXACT body of each switch case — no algorithm changes
- Keep all `noexcept` specifiers
- Keep all `const` / `restrict` qualifiers
- NOT add string or heap operations
- NOT add locks or blocking calls
- NOT change thread safety guarantees
- The extracted function must receive all state it needs as parameters
- The extracted function body should be a verbatim copy of the original case body

---

## WP3: Bridge Utility Extraction

**Behavior:** Move bridge JSON helpers and argument parsers from `ProjectJson.cpp`
to `BridgeUtil.cpp`. Update all includes.

| Property | Value |
|----------|-------|
| **Parallel-safe** | NO |
| **Sequential after** | Nothing — should be DONE FIRST |
| **Files created** | 2 (`BridgeUtil.hpp`, `BridgeUtil.cpp`) |
| **Files modified** | 3 (`ProjectJson.cpp`, `BridgeHost.cpp`, `EngineHost_commands.cpp`) |
| **Risk** | Low — mechanical, well-understood |

### Implementation steps:

1. Create `engine_juce/include/audioapp/BridgeUtil.hpp`
2. Create `engine_juce/src/BridgeUtil.cpp`
3. Move these functions from `ProjectJson.cpp`:
   - `jsonGetStringArg`
   - `jsonGetNumberArg` (+ `varToDouble`, `varToFloat` from anon ns)
   - `jsonGetBoolArg`
   - `buildBridgeOkWithSnapshot`
   - `buildBridgeOkTransportState`
   - `buildBridgeOkWithPath`
   - `buildBridgeOkWithMessage`
   - `buildBridgeError`
   - `parseMidiNotesFromArgs` (uses `midiNoteFromVar` — needs `#include` or move that too)
   - `parseAutomationPointsFromArgs`
   - `parseSubtractivePresetArgs`
4. Move helper functions from anonymous namespace:
   - `toJuceString`
   - `parseRootVar`
   - `toStdString`
   - `varToInt`, `varToDouble`, `varToFloat`, `varToString`, `varArray`
5. Update `#include` in `BridgeHost.cpp` and `EngineHost_commands.cpp`
6. Remove declarations from `ProjectJson.hpp`

### Worker instructions:

Implementation agents must:
- Move the code exactly — no behavior changes
- Change namespace to `audioapp::bridge_util` (or `audioapp` — match the
  header style)
- Update all `#include` paths
- Update all callers of moved functions
- Test by verifying compilation

---

## WP4: LFO Math Declaration Move

**Behavior:** Move LFO/modulator math function declarations from `ProjectJson.hpp`
to `LfoTypes.hpp`. Update all files that include `ProjectJson.hpp` solely for
LFO math.

| Property | Value |
|----------|-------|
| **Parallel-safe** | YES (with WP1, WP2, WP3) |
| **Sequential after** | Nothing |
| **Files modified** | `ProjectJson.hpp`, `LfoTypes.hpp`, plus includes in consumer files |
| **Risk** | Low — only header changes |

### Implementation steps:

1. Remove LFO math declarations from `ProjectJson.hpp`
2. Add them to `LfoTypes.hpp` (after `LfoState` and `ModulationEdge` structs)
3. Search for all files that `#include "audioapp/ProjectJson.hpp"`
4. For each file that only includes it for LFO math, add `#include "audioapp/LfoTypes.hpp"`
5. For files that need BOTH ProjectJson.hpp and LfoTypes.hpp, both includes remain

### Worker instructions:

Implementation agents must:
- Only move declarations — implementations stay in `LfoEngine.cpp`
- Use `rg "#include .*ProjectJson.hpp"` to find all consumers
- NOT remove includes unnecessarily — only remove `ProjectJson.hpp` include
  if the file doesn't use any serialization or bridge function

---

## WP5 (Future): DeviceState Decomposition

Not part of the current Phase 1. Only implement if explicitly requested.
See Phase B notes in the architecture document.

---

## Implementation Worker Instructions (All WPs)

1. **Obey canonical names** — use the exact function names from §3
2. **Stay within assigned files** — do not touch files owned by another WP
3. **Do not invent public APIs** — only add functions specified in contracts
4. **Do not rename concepts** — `DeviceState::frequencyHz` stays `frequencyHz`
5. **Do not redesign architecture** — the double-buffered snapshot system stays
6. **Do not touch files owned by another package** — see file ownership table
7. **Stop and report if the contract is incomplete** — do not guess field names
   or function signatures
8. **Test after each change** — `cmake --build build/engine --target audioapp_engine`
   must compile; all relevant tests must pass
