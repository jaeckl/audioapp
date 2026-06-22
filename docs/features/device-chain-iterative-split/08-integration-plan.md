# DeviceChain Iterative Split — Integration Plan

## Final state after Step 4

The `engine_juce` library has been split into 5 focused files plus the
unchanged public header. The monolithic `DeviceChain.cpp` is reduced to a
thin orchestrator.

### File inventory

| Path | LOC (final) | Role |
|---|---|---|
| `engine_juce/include/audioapp/DeviceChain.hpp` | 287 (unchanged) | Public API: `processDeviceChain`, all `*Params` structs, `DeviceNodePlayback`, etc. |
| `engine_juce/include/audioapp/DeviceChainScratch.hpp` | ~30 (new) | Header-only POD: `DeviceChainScratch`, `kScratchFrames`, `kAutomationSubBlockFrames`. |
| `engine_juce/include/audioapp/DeviceChainAutomationModulation.hpp` | ~80 (new) | Declarations for `applyModulation` overloads + `applyDspModulationAtFrame` + `dspParamsAtFrame` + 3 predicate helpers. |
| `engine_juce/include/audioapp/DeviceChainProcessor.hpp` | ~70 (new) | Declarations for `processDeviceNode` + `applyCommonGainPanLfo`. |
| `engine_juce/src/DeviceChain.cpp` | **≤ 50** (≤ 80 with 3 helpers) | Orchestration: outer loop, automation-clip envelope loop, per-node LFO modulation, calls dispatcher, manages `gScratch`. |
| `engine_juce/src/DeviceChainAutomationModulation.cpp` | ≤ 600 (new) | 22 `applyModulation` overloads + DSP modulation/automation evaluation + 3 predicate helpers. |
| `engine_juce/src/DeviceChainProcessor.cpp` | ≤ 700 (new) | Per-device switch dispatcher + `applyCommonGainPanLfo` helper. |

Total LOC across new files: **≤ 1450** (roughly the same as the original
monolith + header boilerplate; the growth is comments + namespace wrappers +
new headers). The monolith itself drops from **1261 LOC → ≤ 80 LOC**.

### CMake changes

`engine_juce/CMakeLists.txt` adds 2 source files (Steps 2 and 3 each add
one):

```cmake
add_library(audioapp_engine STATIC
  src/TestOscillator.cpp
  src/ProjectEngine.cpp
  src/LivePerformance.cpp
  src/ProjectEngine_live.cpp
  src/ProjectJson.cpp
  src/ProjectArchive.cpp
  src/MidiClipPlayback.cpp
  src/SampleBank.cpp
  src/WavLoader.cpp
  src/SamplePlayback.cpp
  src/SamplerFilter.cpp
  src/SubtractiveSynth.cpp
  src/PhaseModSynth.cpp
  src/KickGenerator.cpp
  src/SnareGenerator.cpp
  src/ClapGenerator.cpp
  src/CymbalGenerator.cpp
  src/CrashGenerator.cpp
  src/MetallicNoiseSynth.cpp
  src/DynamicsProcessor.cpp
  src/FrequencyFxProcessor.cpp
  src/MasterMix.cpp
  src/DeviceChain.cpp                                # Step 4: ≤ 80 LOC
  src/DeviceChainAutomationModulation.cpp            # Step 2: NEW
  src/DeviceChainProcessor.cpp                        # Step 3: NEW
  src/devices/DeviceRegistry.cpp
  ...
)
```

No other CMake change. The 2 new TUs inherit `target_include_directories`,
`target_link_libraries`, and `target_compile_definitions` from the parent
target automatically.

## What `DeviceChain.cpp` looks like after Step 4

Sketch (≤ 50 LOC excluding classifier helpers):

```cpp
#include "audioapp/DeviceChain.hpp"
#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/DeviceChainAutomationModulation.hpp"
#include "audioapp/DeviceChainProcessor.hpp"

#include <algorithm>
#include <cstring>
#include <cmath>

namespace audioapp {
namespace {

thread_local DeviceChainScratch gScratch;

using namespace audioapp::DeviceChainAutomationModulation;

bool isMidiNoteActive(const MidiPlaybackNote& note, double beat) {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats)
        return false;
    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteEnd = std::min(note.noteStartBeat + note.noteDurationBeats, note.clipLengthBeats);
    return loopedBeat >= note.noteStartBeat && loopedBeat < noteEnd;
}

} // namespace

bool isDynamicsDeviceNodeKind(const DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Gate || kind == DeviceNodeKind::Compressor ||
           kind == DeviceNodeKind::Expander || kind == DeviceNodeKind::Limiter;
}
bool isInstrumentDeviceNodeKind(const DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Oscillator || kind == DeviceNodeKind::Sampler ||
           kind == DeviceNodeKind::SubtractiveSynth || kind == DeviceNodeKind::KickGenerator ||
           kind == DeviceNodeKind::SnareGenerator || kind == DeviceNodeKind::ClapGenerator ||
           kind == DeviceNodeKind::CymbalGenerator || kind == DeviceNodeKind::CrashGenerator ||
           kind == DeviceNodeKind::BassSynth || kind == DeviceNodeKind::PhaseModSynth;
}
bool isFrequencyFxDeviceNodeKind(DeviceNodeKind kind) noexcept {
    return kind == DeviceNodeKind::Filter ||
           kind == DeviceNodeKind::FourBandEq ||
           kind == DeviceNodeKind::FrequencyShifter;
}

float midiActiveFrequencyHz(const MidiPlaybackNote* notes, int noteCount,
                            double playheadBeat, float idleFrequencyHz) noexcept {
    int pitch = -1;
    for (int i = 0; i < noteCount; ++i) {
        if (!isMidiNoteActive(notes[i], playheadBeat)) continue;
        pitch = notes[i].pitch;
    }
    if (pitch >= 0) return midiNoteToHz(pitch);
    return idleFrequencyHz;
}

void processDeviceChain(float* trackLeft, float* trackRight, int numFrames,
                        double sampleRate, int bpm, double playheadStartBeat,
                        const MidiPlaybackNote* notes, int noteCount,
                        const DeviceNodePlayback* devices, int deviceCount,
                        float& oscillatorPhase, bool suppressInstruments,
                        BiquadState* samplerFilterStates,
                        /* … runtime pointers … */
                        DeviceChainScratch& /* exposed via gScratch */) noexcept {
    if (trackLeft == nullptr || trackRight == nullptr || numFrames <= 0 ||
        devices == nullptr || deviceCount <= 0) return;

    const int framesToProcess = numFrames > kScratchFrames ? kScratchFrames : numFrames;
    auto& s = gScratch;
    const double beatsPerFrame = (static_cast<double>(std::max(bpm, 1)) / 60.0) / sampleRate;

    for (int deviceIndex = 0; deviceIndex < deviceCount; ++deviceIndex) {
        const DeviceNodePlayback& node = devices[deviceIndex];
        if (node.bypassed) continue;

        auto modulatedParams = node.params;
        for (int f = 0; f < framesToProcess; ++f) {
            s.perFrameGain[f] = node.gain;
            s.perFramePan[f] = node.pan;
        }

        const uint16_t di = static_cast<uint16_t>(deviceIndex);
        const bool needsSubBlocks = nodeNeedsSubBlocks(
            node, deviceIndex, automationClips, automationClipCount, modEdges, modEdgeCount);

        // (timeline automation block — kept in DeviceChain.cpp because it
        //  resolves per-frame common-gain/pan envelopes into the scratch.)
        // (per-node LFO modulation block — kept in DeviceChain.cpp because
        //  it mutates modulatedParams.)
        DeviceChainProcessor::applyCommonGainPanLfo(
            modEdges, modEdgeCount, lfoValues, lfoCount, framesToProcess,
            deviceIndex, s);

        DeviceChainProcessor::processDeviceNode(
            node, deviceIndex, framesToProcess, trackLeft, trackRight,
            sampleRate, bpm, playheadStartBeat, notes, noteCount,
            modulatedParams, needsSubBlocks,
            lfoValues, lfoCount, modEdges, modEdgeCount,
            automationClips, automationClipCount,
            oscillatorPhase, suppressInstruments,
            samplerFilterStates, subtractiveRuntimes, kickRuntimes,
            snareRuntimes, clapRuntimes, cymbalRuntimes, crashRuntimes,
            phaseModRuntimes, dynamicsRuntimes, timeBasedRuntimes,
            filterRuntimes, fourBandEqRuntimes, frequencyShifterRuntimes,
            deviceMeters, maxDeviceMeters, s);
    }
}

} // namespace audioapp
```

The sketch above is illustrative; the **real** Step 4 file is whatever
the worker produces by slimming HEAD's `processDeviceChain` to ~50 LOC.

## Public ABI verification (Step 4 final gate)

The function `audioapp::processDeviceChain` is the **single** public symbol
exposed by `DeviceChain.{hpp,cpp}`. Step 4 verifies the ABI is unchanged:

```bash
# 1. Symbol exists and is defined (not undefined) in the static lib
nm build/engine/libaudioapp_engine.a 2>/dev/null | grep "processDeviceChain"
# expected: at least one "T" (defined text) entry, no "U" (undefined).

# 2. Every caller compiles without edits
grep -r "processDeviceChain" --include="*.cpp" --include="*.hpp" \
    engine_juce/ native_bridge/
# expected: matches in DeviceChain.hpp, DeviceChain.cpp,
# DeviceChainProcessor.cpp, BridgeHost.cpp, EngineHost*.cpp,
# ProjectEngine*.cpp, LivePerformance.cpp
# No edits to those files (this refactor does not touch them).
```

If `BridgeHost.cpp` or `EngineHost_*.cpp` still compiles, the public ABI
is preserved.

## Test verification (final gate)

```bash
# 1. engine compiles
cmake --build build/engine --target audioapp_engine

# 2. gate test passes
g++ <flags> engine_juce/tests/device_chain_test.cpp \
    build/engine/libaudioapp_engine.a \
    -lasound -lpthread -ldl -lrt -o /tmp/device_chain_test
/tmp/device_chain_test
# expected: 4/4 beginTest blocks pass, exit code 0

# 3. sibling tests still link
for t in common_param_modulation_test gain_pan_mod_auto_test \
         lfo_sync_bpm_test lfo_polarity_test adsr_modulator_test \
         modulation_e2e_test effect_device_modulation_test; do
    g++ <flags> engine_juce/tests/${t}.cpp \
        build/engine/libaudioapp_engine.a \
        -lasound -lpthread -ldl -lrt -o /tmp/${t} || echo "FAIL: ${t}"
done
# expected: no FAIL lines

# 4. final LOC counts
wc -l engine_juce/src/DeviceChain*.cpp engine_juce/include/audioapp/DeviceChain*.hpp
# expected:
#   DeviceChain.cpp:                           ≤ 80
#   DeviceChainAutomationModulation.cpp:        ≤ 600
#   DeviceChainProcessor.cpp:                   ≤ 700
#   DeviceChain.hpp (header):                   287 (unchanged)
#   DeviceChainScratch.hpp (header):            ~30
#   DeviceChainAutomationModulation.hpp:       ~80
#   DeviceChainProcessor.hpp:                   ~70
```

## Rollback plan

Each step is a single commit. If any step's test gate fails:

1. **Revert the commit for that step** (`git revert HEAD`).
2. Do **not** attempt to fix forward — the worker must report the failure
   with the failing block name (e.g. "Block 2: oscillator peak dropped to
   0.0001 < 0.01"), and the architect updates the contract before any
   re-attempt.

This is why each step is a **separate commit**: the previous attempt
merged all changes into one commit and made rollback impossible.

## Open follow-ups (not in this slice)

These are NOT in scope for the refactor. They are recorded here so future
iterations know what was deliberately left for later:

1. The 22 `applyModulation` overloads have ~80% duplication (each is a
   `switch` over the same pattern with different enum types). A future
   refactor could template this; out of scope here.
2. `processDeviceNode`'s parameter list is 30+ arguments. A future
   refactor could introduce a `ProcessContext` POD; out of scope here.
3. The orchestrator's automation-clip loop (HEAD lines 606–642) and
   per-node LFO modulation block (HEAD lines 645–664) are still in
   `DeviceChain.cpp`. A future refactor could move them into
   `DeviceChainAutomationModulation.cpp`; out of scope here.
4. The 4 dynamics cases (Gate, Compressor, Expander, Limiter) in the
   dispatcher are nearly identical. A future refactor could template them;
   out of scope here.

These follow-ups would be separate feature slices with their own
contracts.
