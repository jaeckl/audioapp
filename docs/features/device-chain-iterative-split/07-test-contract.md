# DeviceChain Iterative Split — Test Contract

## Principle: zero new tests in this refactor

The previous attempt added a flurry of new tests as it split, which obscured
real regressions because each new test had its own expected values. This time
the **only** behavioural test for the refactor is the existing
`engine_juce/tests/device_chain_test.cpp`. It must keep passing — with the
same pass/fail outcome — at every step.

The other tests that exercise `processDeviceChain` indirectly are listed
below; they must also keep passing because they link against the static lib
and call into `processDeviceChain`. We do **not** add new test cases for
the refactor.

## The gate test: `device_chain_test.cpp`

This is a JUCE `UnitTest` with 4 `beginTest` blocks:

1. **"sampler without PCM stays silent"** — passes a `Sampler` device with
   `samplerPcm == nullptr`; expects the output peak to be ≤ 1.0e-6f on both
   channels. This exercises the `Sampler` case in the dispatcher and the
   `samplerRegions` field on the scratch.

2. **"oscillator generates audio, track gain scales"** — passes an
   `Oscillator` followed by `TrackGain`. Expects:
   - Output peak > 0.01f (oscillator is producing sound).
   - Output peak < `kInstrumentOutputGain * 0.9f` (= 0.18f; verifies the
     `TrackGain` device applied its `gain = 0.25f` scaling).
   This exercises both the `Oscillator` case (which uses `addSineBlock`)
   and the `TrackGain` case (which multiplies `trackLeft`/`trackRight` by
   `perFrameGain`).

3. **"hard pan left biases energy left"** — passes an `Oscillator` with
   `pan = 0.0f`. Expects the left channel to have more energy than the right.
   This exercises the `mixStereoPerFramePan` path inside `Oscillator`.

4. **"engine integration: default track is sampler-only"** — uses
   `EngineHost` end-to-end. Creates a project, adds a "Sampler" track,
   starts playback, and expects silence (because the default sampler has
   no PCM).

All 4 blocks must continue to pass at every step. The expected outcome
matrix:

| Step | Block 1 | Block 2 | Block 3 | Block 4 |
|---|---|---|---|---|
| 1 | pass | pass | pass | pass |
| 2 | pass | pass | pass | pass |
| 3 | pass | pass | pass | pass |
| 4 | pass | pass | pass | pass |

If any block starts failing at any step, that step has introduced a
behavioural regression and must be reverted.

## Test gate command (per AGENTS.md gotchas)

`engine_juce/tests/audioapp_juce_tests` **cannot link** because all 17
files in `engine_juce/tests/` define their own `int main()`. We compile
`device_chain_test.cpp` against the built static lib directly:

```bash
# Extract flags from the existing compile_commands.json (one-shot)
FLAGS=$(jq -r '.[0].command' build/engine/compile_commands.json | sed 's/-c //; s/"[^"]*"//g; s/\\$//g')

# Compile and link the gate test
g++ $FLAGS \
    engine_juce/tests/device_chain_test.cpp \
    build/engine/libaudioapp_engine.a \
    -lasound -lpthread -ldl -lrt \
    -o /tmp/device_chain_test

# Run it; exit code 0 = pass
/tmp/device_chain_test
echo "exit code: $?"
```

On Windows, replace `g++` with the MSVC `cl.exe` invocation that matches
the flags in `build/engine/compile_commands.json`. The exact MSVC command
is platform-specific; see AGENTS.md for the host-engine build invocation
on Windows.

The exit code of `/tmp/device_chain_test` is the gate. **Non-zero = step
fails.**

## What each step's test verifies

### Step 1

- The static lib still exports the `processDeviceChain` symbol.
- `device_chain_test` Block 1 still passes — proves the `Sampler` case can
  still allocate `samplerRegions` on the scratch (the scratch is now in a
  shared header, so the field layout must be identical).
- `device_chain_test` Block 2 still passes — proves the `Oscillator` and
  `TrackGain` cases still produce correct output (these cases read
  `scratch` and `perFrameGain`).
- `device_chain_test` Block 4 still passes — proves the `EngineHost`
  integration is unaffected.

### Step 2

- All 4 blocks still pass — proves the moved `applyModulation` overloads
  and helpers behave identically.
- Block 1 still passes — proves `SamplerParams::applyModulation` is still
  reachable (even though no test exercises modulation in this block, the
  `std::visit` in `applyDspModulationAtFrame` will fail to link if the
  overloads are missing).

### Step 3

- All 4 blocks still pass — proves the dispatcher switch matches HEAD's
  behaviour for every exercised case.
- Block 2 still passes — proves the `TrackGain` case in the dispatcher
  applies `perFrameGain[f]` correctly.
- Block 4 still passes — proves the `EngineHost` integration through the
  full pipeline (which calls `processDeviceChain` → `processDeviceNode` →
  `*Runtime::processStereoBlock`).

### Step 4

- All 4 blocks still pass — proves the orchestrator glue is correct.
- `BridgeHost.cpp` still links — proves the public ABI of
  `processDeviceChain` is unchanged.

## Sibling tests that **must** keep compiling

The following tests also link against `audioapp_engine` and call
`processDeviceChain` indirectly. They are not part of the per-step gate,
but Step N must verify that none of them breaks at the link level:

```text
tests/common_param_modulation_test.cpp
tests/gain_pan_mod_auto_test.cpp
tests/lfo_sync_bpm_test.cpp
tests/lfo_polarity_test.cpp
tests/adsr_modulator_test.cpp
tests/modulation_e2e_test.cpp
tests/effect_device_modulation_test.cpp
```

Link-level verification (per-file, due to the `int main()` gotcha):

```bash
for t in common_param_modulation_test gain_pan_mod_auto_test \
         lfo_sync_bpm_test lfo_polarity_test adsr_modulator_test \
         modulation_e2e_test effect_device_modulation_test; do
    g++ $FLAGS engine_juce/tests/${t}.cpp \
        build/engine/libaudioapp_engine.a \
        -lasound -lpthread -ldl -lrt \
        -o /tmp/${t} || echo "LINK FAIL: ${t}"
done
```

If any of these fails to link, Step N has broken a public symbol and must
be reverted.

## Forbidden test changes

- ❌ Adding new `beginTest` blocks to `device_chain_test.cpp`.
- ❌ Modifying the expected thresholds in existing `beginTest` blocks
  (e.g. `1.0e-6f`, `0.01f`, `kInstrumentOutputGain * 0.9f`).
- ❌ Adding new test files under `engine_juce/tests/`.
- ❌ Modifying `TestHelpers.h` or `JuceTestRunner.cpp`.

The only test-side change allowed is the gate command above, which
runs in the worker's shell. **No source-file edits to any test.**
