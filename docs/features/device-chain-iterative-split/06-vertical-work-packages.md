# DeviceChain Iterative Split — Vertical Work Packages

4 work packages, executed **strictly sequentially** (Step 1 → Step 2 → Step 3
→ Step 4). Each is independent: it owns its files exclusively, must end with
the compile gate and the test gate passing, and must produce **byte-identical**
output to HEAD.

**No parallel execution.** The design is intentionally sequential because the
scratch struct is shared across all four steps and parallel agents would
contend on `DeviceChain.cpp` and `DeviceChainScratch.hpp`. The orchestrator
must run Step N+1 only after Step N's test gate passes.

---

## Step 1 — Move `DeviceChainScratch` to a header

### User-visible / system-visible behavior

**None.** This step is a pure refactor that moves a POD struct + 2 constants
from the anonymous namespace of `DeviceChain.cpp` into a public header.
Audio output is byte-identical to HEAD; all existing tests must pass.

### Allowed files (owned by Step 1)

- `engine_juce/include/audioapp/DeviceChainScratch.hpp` — **CREATE**.
- `engine_juce/src/DeviceChain.cpp` — edit only lines 1–44 (the file's
  include block and the anonymous namespace opening); **DELETE** lines 25–44
  (the constants, struct, and `thread_local gScratch;` declaration).

### Forbidden files (Step 1 must not touch)

- `engine_juce/include/audioapp/DeviceChain.hpp` (public API frozen).
- `engine_juce/CMakeLists.txt` (header-only, no build change).
- Any file in `engine_juce/src/`.
- Any test file.
- Any file under `app_flutter/`, `native_bridge/`, `docs/`.

### Canonical names used

- `DeviceChainScratch` (struct, in `audioapp` namespace)
- `kScratchFrames` (= 4096)
- `kAutomationSubBlockFrames` (= 64)
- `gScratch` (the `thread_local` instance, still defined in `DeviceChain.cpp`)
- All `*MidiNoteRegion` and `BiquadState` types (already in their respective
  headers, pulled in transitively)

### API/data contracts used

`DeviceChainScratch` per `04-data-contracts.md` § "`DeviceChainScratch`".

### Dependencies

None. Step 1 has no prerequisite.

### Acceptance criteria

1. `cmake --build build/engine --target audioapp_engine` succeeds (compile gate).
2. `device_chain_test` (compiled and run per the test gate below) produces
   **byte-identical** output to HEAD (the test only checks for non-trivial
   peaks and silence, so "byte-identical" here means the same pass/fail
   result for each `beginTest` block).
3. All other tests that link against `audioapp_engine` still compile and
   link (the test target is `audioapp_juce_tests`, but that target has the
   "each file has its own `int main()`" gotcha noted in AGENTS.md, so we
   only verify via the per-file compile-and-link of `device_chain_test.cpp`
   plus a static-lib symbol check).
4. `DeviceChain.cpp` LOC count is reduced by ~19 lines (the deleted struct +
  `thread_local gScratch;`).
5. `DeviceChainScratch.hpp` is header-only, `#pragma once`, contains only the
  struct + 2 constexpr, no `inline` functions, no `using namespace`.

### Required tests

**None new.** Step 1 reuses the existing
`engine_juce/tests/device_chain_test.cpp` as the gate. The worker must
**not** add new tests; the only verification is that the existing test
still passes.

### Manual verification steps

```bash
# 1. Compile gate
cmake --build build/engine --target audioapp_engine

# 2. Static-lib still exposes the processDeviceChain symbol
nm build/engine/libaudioapp_engine.a | grep processDeviceChain
# expected: multiple symbols (the public function + internal callers)

# 3. Per-file compile-and-link of the gate test (per AGENTS.md gotchas)
g++ <flags from build/engine/compile_commands.json> \
    engine_juce/tests/device_chain_test.cpp \
    build/engine/libaudioapp_engine.a \
    -lasound -lpthread -ldl -lrt \
    -o /tmp/device_chain_test
/tmp/device_chain_test
```

### Integration risk

**Low.** Step 1 only changes the visibility of an existing POD struct. The
behavioral surface (which code paths reach for `gScratch`, which fields are
written) is identical. The risk is **forgetting to re-declare `gScratch`** in
`DeviceChain.cpp` after deleting the original block — that would cause a
link error for the orchestrator's `auto& s = gScratch;`. Workers must
verify `gScratch` is still defined exactly once (in `DeviceChain.cpp`'s
anonymous namespace) after Step 1.

### Parallelization classification

**Sequential prerequisite** — Step 1 must complete before Step 2 begins.

---

## Step 2 — Move automation/modulation helpers

### User-visible / system-visible behavior

**None.** Pure refactor. All 22 `applyModulation` overloads + 5 helpers move
verbatim. No math changes, no signature changes, no `noexcept` changes.

### Allowed files (owned by Step 2)

- `engine_juce/include/audioapp/DeviceChainAutomationModulation.hpp` —
  **CREATE** with declarations only.
- `engine_juce/src/DeviceChainAutomationModulation.cpp` — **CREATE** with
  the bodies verbatim from HEAD lines 79–362 (`applyModulation` overloads),
  392–416 (`applyDspModulationAtFrame`), 418–435 (`dspParamsAtFrame`),
  437–467 (`nodeNeedsSubBlocks`), 469–492 (`nodeUsesDspAutomationSubBlocks`),
  494–506 (`nodeHasDspModulation`).
- `engine_juce/src/DeviceChain.cpp` — **DELETE** those same bodies (line
  ranges above). Add `#include "audioapp/DeviceChainAutomationModulation.hpp"`
  and `using namespace audioapp::DeviceChainAutomationModulation;` inside the
  anonymous namespace.
- `engine_juce/CMakeLists.txt` — **ADD** `src/DeviceChainAutomationModulation.cpp`
  to the `add_library(audioapp_engine STATIC ...)` source list (between
  `src/DeviceChain.cpp` and `src/devices/DeviceRegistry.cpp`).

### Forbidden files (Step 2 must not touch)

- `engine_juce/include/audioapp/DeviceChain.hpp`.
- `engine_juce/include/audioapp/DeviceChainScratch.hpp`.
- `engine_juce/include/audioapp/AutomationTypes.hpp`,
  `engine_juce/include/audioapp/AutomationPlayback.hpp` (existing free
  functions stay where they are).
- Any test file.

### Canonical names used

- `audioapp::DeviceChainAutomationModulation::applyModulation` (22 overloads)
- `audioapp::DeviceChainAutomationModulation::applyDspModulationAtFrame`
- `audioapp::DeviceChainAutomationModulation::dspParamsAtFrame`
- `audioapp::DeviceChainAutomationModulation::nodeNeedsSubBlocks`
- `audioapp::DeviceChainAutomationModulation::nodeUsesDspAutomationSubBlocks`
- `audioapp::DeviceChainAutomationModulation::nodeHasDspModulation`
- (Unchanged): `audioapp::applyDspAutomationAtBeat`,
  `audioapp::nodeHasDspAutomation`, `audioapp::applyAutomationValue`,
  `audioapp::evaluateAutomationEnvelope`

### API/data contracts used

Per `03-api-contracts.md` § "Step 2".

### Dependencies

**Sequential:** Step 2 requires Step 1 to have moved `DeviceChainScratch` to
a header (so the new TU can include it transitively if needed). Step 2 does
not actually depend on the scratch contents directly, but the compile order
must be Step 1 → Step 2.

### Acceptance criteria

1. `cmake --build build/engine --target audioapp_engine` succeeds.
2. `device_chain_test` passes with identical output to HEAD.
3. `DeviceChainAutomationModulation.cpp` LOC ≤ 600 (was ~430 in HEAD's
   anonymous namespace; the file adds 22 lines of `#include` + namespace +
   ~5 closing braces; under 600).
4. `DeviceChain.cpp` LOC count drops by approximately the same number of
   lines that moved out (~290 lines).
5. `DeviceChainAutomationModulation.hpp` has **no** `inline` definitions
   (the worker must verify `grep -c '^inline' DeviceChainAutomationModulation.hpp`
   returns 0).
6. All 22 `applyModulation` overloads are present (grep the `.cpp`).

### Required tests

**None new.** Gate is `device_chain_test`.

### Manual verification steps

Same as Step 1, plus:

```bash
# Symbol check: applyModulation overloads are in the static lib
nm build/engine/libaudioapp_engine.a | grep applyModulation | wc -l
# expected: ≥ 22 (some overloads may have been merged by the linker, but
# each device-kind type generates at least one symbol)

# Symbol check: dspParamsAtFrame, nodeNeedsSubBlocks are present
nm build/engine/libaudioapp_engine.a | grep -E "dspParamsAtFrame|nodeNeedsSubBlocks|nodeHasDspModulation"
# expected: 3 distinct symbols

# File-size check on the new TU
wc -l engine_juce/src/DeviceChainAutomationModulation.cpp
# expected: ≤ 600

# File-size check on DeviceChain.cpp (should have shrunk)
wc -l engine_juce/src/DeviceChain.cpp
# expected: ≤ 1000
```

### Integration risk

**Medium.** This step moves the largest amount of code (~430 lines of
modulation). Risks:

- **Missing include in the new TU:** the new `.cpp` must include every
  header that defines the param types it touches
  (`Sampler.hpp`, `SubtractiveSynth.hpp`, `PhaseModSynth.hpp`, all the
  `*Generator.hpp` files, `DynamicsProcessor.hpp`, `FrequencyFxProcessor.hpp`).
  A missing include would surface as a compile error caught by the compile
  gate, not a runtime bug.
- **`using namespace` shadowing:** the new TU uses `using namespace
  audioapp::DeviceChainAutomationModulation;` inside `DeviceChain.cpp`'s
  anonymous namespace. This shadows nothing because the orchestrator's
  remaining code only calls `applyModulation(...)` unqualified, which
  now resolves to the sub-namespace.
- **Inline-vs-declaration drift:** if the worker accidentally declares
  `applyModulation` in the header and **defines** it in the header as
  `inline`, the linker may produce duplicate symbols across TUs. Workers
  must keep definitions in the `.cpp` only.

### Parallelization classification

**Sequential** — requires Step 1 to be complete and green.

---

## Step 3 — Extract per-device dispatcher

### User-visible / system-visible behavior

**None.** Pure refactor. The `switch (node.kind) { … }` block moves to a
new TU; `processDeviceChain` calls it. No math changes, no parameter
re-ordering, no scratch access pattern changes.

### Allowed files (owned by Step 3)

- `engine_juce/include/audioapp/DeviceChainProcessor.hpp` — **CREATE** with
  `processDeviceNode` declaration + `applyCommonGainPanLfo` declaration.
- `engine_juce/src/DeviceChainProcessor.cpp` — **CREATE** with the moved
  switch block (HEAD lines 687–1257) verbatim inside `processDeviceNode`,
  plus the body of HEAD lines 666–684 lifted verbatim into
  `applyCommonGainPanLfo`.
- `engine_juce/src/DeviceChain.cpp` — **REPLACE** lines 686–1257 (the switch
  block) with a single call to `audioapp::DeviceChainProcessor::processDeviceNode(...)`.
  Also replace lines 666–684 with a single call to
  `audioapp::DeviceChainProcessor::applyCommonGainPanLfo(...)`.
- `engine_juce/CMakeLists.txt` — **ADD** `src/DeviceChainProcessor.cpp`
  to the source list (after `src/DeviceChainAutomationModulation.cpp`).

### Forbidden files (Step 3 must not touch)

- `engine_juce/include/audioapp/DeviceChain.hpp` (signature frozen).
- `engine_juce/include/audioapp/DeviceChainScratch.hpp`.
- `engine_juce/include/audioapp/DeviceChainAutomationModulation.hpp`.
- All `*Generator*.cpp`, `*Synth*.cpp`, `*Processor*.cpp`.
- Any test file.

### Canonical names used

- `audioapp::DeviceChainProcessor::processDeviceNode` (new)
- `audioapp::DeviceChainProcessor::applyCommonGainPanLfo` (new)
- All names from Step 2 (still in the
  `audioapp::DeviceChainAutomationModulation` namespace, accessible because
  `DeviceChainProcessor.cpp` does its own `using namespace`)

### API/data contracts used

Per `03-api-contracts.md` § "Step 3".

### Dependencies

**Sequential:** Step 3 requires Step 2 to have moved the automation helpers
(because the dispatcher's `Oscillator` and `Sampler` sub-block cases call
`dspParamsAtFrame`).

### Acceptance criteria

1. `cmake --build build/engine --target audioapp_engine` succeeds.
2. `device_chain_test` passes with identical output to HEAD.
3. `DeviceChainProcessor.cpp` LOC ≤ 700 (the switch block is ~570 lines;
   the file adds ~30 lines of namespace/function wrappers).
4. `DeviceChain.cpp` LOC ≤ 400.
5. The dispatcher's switch block has **every** case from HEAD (22 cases
   including the `default: break;`):
   - Oscillator, Sampler, SubtractiveSynth + BassSynth (merged case),
     KickGenerator, SnareGenerator, ClapGenerator, CymbalGenerator,
     CrashGenerator, PhaseModSynth, Gate, Compressor, Expander, Limiter,
     Filter, FourBandEq, FrequencyShifter, Delay, Reverb, Chorus, Phaser,
     TrackGain, `default`.
   - Worker must `grep -c "case DeviceNodeKind::" DeviceChainProcessor.cpp`
     and verify the count is **22**.

### Required tests

**None new.** Gate is `device_chain_test`.

### Manual verification steps

```bash
# Compile gate
cmake --build build/engine --target audioapp_engine

# Case count check
grep -c "case DeviceNodeKind::" engine_juce/src/DeviceChainProcessor.cpp
# expected: 22

# LOC check
wc -l engine_juce/src/DeviceChainProcessor.cpp engine_juce/src/DeviceChain.cpp
# expected: ≤ 700 and ≤ 400 respectively

# Test gate (per-file compile-and-link per AGENTS.md gotchas)
g++ <flags from build/engine/compile_commands.json> \
    engine_juce/tests/device_chain_test.cpp \
    build/engine/libaudioapp_engine.a \
    -lasound -lpthread -ldl -lrt \
    -o /tmp/device_chain_test
/tmp/device_chain_test
```

### Integration risk

**High.** This step is the largest single move (~570 lines of switch).
Risks:

- **Argument-list drift:** the dispatcher needs every parameter that the
  switch body uses. Missing one causes a compile error caught by the gate.
  The contract pins the full parameter list verbatim; the worker must
  match it exactly.
- **Scratch reach:** the dispatcher must use the passed `scratch&` for
  every access (no `extern thread_local` reach, no global). If a worker
  accidentally refers to `gScratch` inside `DeviceChainProcessor.cpp`, the
  compile will fail (`gScratch` is in an anonymous namespace inside
  `DeviceChain.cpp`). This is a feature, not a bug — it forces the SRP.
- **Case merging:** HEAD merges `BassSynth` with `SubtractiveSynth` in a
  single case (line 768). The worker must preserve this; do not split
  into two cases.
- **`CymbalGenerator` and `CrashGenerator` reach for `s.tempStereoL` and
  `s.tempStereoR`** (HEAD lines 867–877, 891–901). They must continue to
  do so via the `scratch&` parameter.

### Parallelization classification

**Sequential** — requires Step 2 to be complete and green.

---

## Step 4 — Slim `processDeviceChain` to orchestration only

### User-visible / system-visible behavior

**None.** Pure refactor. The orchestrator's body is reduced to ≤50 LOC of
straight-line glue; the 3 trivial classifier helpers may stay or be inlined.

### Allowed files (owned by Step 4)

- `engine_juce/src/DeviceChain.cpp` — slim the body of `processDeviceChain`
  to ≤50 LOC plus namespace wrapper. Optionally inline
  `isDynamicsDeviceNodeKind`, `isInstrumentDeviceNodeKind`,
  `isFrequencyFxDeviceNodeKind` (each is 1 line of switch-style logic).

### Forbidden files (Step 4 must not touch)

- `engine_juce/include/audioapp/DeviceChain.hpp` (signature is byte-frozen;
  this is the final test gate for ABI compatibility).
- Any other `.cpp` or `.hpp`.
- `engine_juce/CMakeLists.txt` (no build change).
- Any test file.

### Canonical names used

- `audioapp::processDeviceChain` (signature unchanged)
- `audioapp::isDynamicsDeviceNodeKind`, `isInstrumentDeviceNodeKind`,
  `isFrequencyFxDeviceNodeKind` (signatures unchanged)
- `audioapp::midiActiveFrequencyHz` (signature unchanged)
- `audioapp::DeviceChainProcessor::processDeviceNode` (call unchanged from
  Step 3)
- `audioapp::DeviceChainProcessor::applyCommonGainPanLfo` (call unchanged
  from Step 3)
- `audioapp::DeviceChainAutomationModulation::*` (calls unchanged from
  Step 2, reached via `using namespace` in the anonymous namespace)

### API/data contracts used

The signature of `processDeviceChain` in `DeviceChain.hpp` is **byte-frozen**
and identical to HEAD lines 253–285.

### Dependencies

**Sequential:** Step 4 requires Step 3 to be complete and green.

### Acceptance criteria

1. `cmake --build build/engine --target audioapp_engine` succeeds.
2. `device_chain_test` passes with identical output to HEAD.
3. **`BridgeHost.cpp` still links unchanged** — this is the ABI gate. The
   worker must verify `nm build/engine/libaudioapp_engine.a | grep " T "`
   shows `processDeviceChain` as a defined text symbol (not `U` undefined).
4. **`DeviceChain.cpp` LOC ≤ 50** (excluding namespace wrapper and
   classifier helpers; total file size may be up to ~80 LOC if all three
   helpers stay).
5. The orchestrator's outer `for (int deviceIndex = 0; deviceIndex <
   deviceCount; ++deviceIndex)` loop remains in `DeviceChain.cpp` (the
   per-device loop is orchestration, not per-device processing).
6. The orchestrator's automation-clip loop (HEAD lines 606–642) and the
   per-device LFO modulation block (HEAD lines 645–664) remain in
   `DeviceChain.cpp` because they set up the per-node `modulatedParams`
   and `needsSubBlocks` flag that the dispatcher consumes.

### Required tests

**None new.** The final acceptance test is:

```bash
# Re-link BridgeHost to verify the public API has not drifted
cmake --build native_bridge -j 4
# (or the equivalent on the host platform)
```

If `BridgeHost` builds unchanged, the public ABI is preserved.

### Manual verification steps

```bash
# Compile gate
cmake --build build/engine --target audioapp_engine

# ABI gate: every caller of processDeviceChain still compiles
grep -r "processDeviceChain" --include="*.cpp" --include="*.hpp" \
    engine_juce/ native_bridge/
# expected: matches in DeviceChain.hpp, DeviceChain.cpp,
# DeviceChainProcessor.cpp, BridgeHost.cpp, EngineHost*.cpp,
# ProjectEngine*.cpp, LivePerformance.cpp

# Test gate
g++ <flags from build/engine/compile_commands.json> \
    engine_juce/tests/device_chain_test.cpp \
    build/engine/libaudioapp_engine.a \
    -lasound -lpthread -ldl -lrt \
    -o /tmp/device_chain_test
/tmp/device_chain_test

# Final LOC check
wc -l engine_juce/src/DeviceChain.cpp
# expected: ≤ 80 (≤ 50 strict, ≤ 80 with the 3 classifier helpers)

# Cross-TU file count
ls engine_juce/src/DeviceChain*.cpp engine_juce/src/DeviceChain*.hpp \
    engine_juce/include/audioapp/DeviceChain*.hpp
# expected: 4 cpp/hpp pairs + 1 header-only (DeviceChainScratch.hpp)
```

### Integration risk

**Low.** Step 4 only slims a body, not a signature. The risk is purely
cosmetic (LOC count). If the slimmed body accidentally changes a control
flow, the test gate catches it before merge.

### Parallelization classification

**Sequential** — final step. No work follows it within this feature.

---

## Summary table

| Step | Allowed files (owned) | Forbidden files | Test gate | LOC after step |
|---|---|---|---|---|
| 1 | `DeviceChainScratch.hpp` (new), `DeviceChain.cpp` | everything else | `device_chain_test` passes | DeviceChain.cpp ≤ 1242 |
| 2 | `DeviceChainAutomationModulation.{hpp,cpp}` (new), `DeviceChain.cpp`, `CMakeLists.txt` | `DeviceChain.hpp`, `DeviceChainScratch.hpp`, tests | `device_chain_test` passes | DeviceChain.cpp ≤ 950, new TU ≤ 600 |
| 3 | `DeviceChainProcessor.{hpp,cpp}` (new), `DeviceChain.cpp`, `CMakeLists.txt` | `DeviceChain.hpp`, all scratch/automation headers, tests | `device_chain_test` passes | DeviceChain.cpp ≤ 400, new TU ≤ 700 |
| 4 | `DeviceChain.cpp` only | `DeviceChain.hpp` (signature frozen), tests | `device_chain_test` passes + `BridgeHost` still links | DeviceChain.cpp ≤ 50 (≤ 80 with helpers) |

## Worker instructions (apply to every step)

Implementation workers **must**:

- obey the canonical names in `02-canonical-vocabulary.md` verbatim;
- stay within the allowed files for their step;
- not invent public APIs (no new free functions outside the contract);
- not rename concepts (use the names in the vocabulary table);
- not redesign architecture (no new argument structs, no new namespaces);
- not touch files owned by another step;
- stop and report missing contract items instead of guessing.

If a step's worker discovers that a contract item is missing or wrong, they
must **stop**, write a brief report listing the gap, and wait for the
architect to update the contract. Do **not** invent a synonym and proceed.
