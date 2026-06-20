# Feature Brief: Fix Filter Cutoff Automation & Modulation Routing

## User-Visible Goal
Automation clips and LFO modulation targeting `filterCutoff` on a SubtractiveSynth device must produce audibly correct filter cutoff sweeps.

## Symptoms (from user report)
| Scenario | Observed | Expected |
|----------|----------|----------|
| Manual knob drag on filter cutoff | Clear filter sweep (Works ✓) | Clear filter sweep |
| LFO → filterCutoff modulation | No audible change (Broken) | Audible filter modulation |
| Automation clip, downwards ramp | Sound gets quieter (was misread as "thinner") | Filter closes (sweep) |
| Automation clip, saw-wave cycle | "Multiple stabs" — gain-like (Broken) | Filter sweep cycle |
| Automation clip ends | Sound returns to knob value (Correct ✓) | Returns to knob value |

## CORRECTED Root Cause Analysis

The previous analysis (paramIdFromString "routing is correct") was wrong. The user
pushed back and that pushback was correct. The real bug is below.

### THE BUG: paramId encoding is ambiguous

`paramIdFromString` returns the raw `uint16_t` value of the per-kind enum, but
multiple kinds reuse value `0` for *different* parameters:

| Kind | Enum value 0 | `paramIdFromString` returns |
|------|--------------|------------------------------|
| `CommonParam` | `Gain = 0` | `0` for `"gain"` |
| `OscillatorParam` | `Frequency = 0` | `0` for `"frequency"` |
| `SamplerParam` | `FilterCutoff = 0` | `0` for `"filterCutoff"` |
| `SubtractiveParam` | `FilterCutoff = 0` | `0` for `"filterCutoff"` |
| `CompressorParam` | `InputGain = 0` | `0` for `"inputGain"` |
| `LimiterParam` | `InputGain = 0` | `0` for `"inputGain"` |
| `ExpanderParam` | `InputGain = 0` | `0` for `"inputGain"` |
| `GateParam` | `InputGain = 0` | `0` for `"inputGain"` |
| `TrackGainParam` | `Gain = 0` | `0` for `"gain"` |
| `KickParam` | `Model = 0` | `0` for `"kickModel"` |
| `SnareParam` | `Model = 0` | `0` for `"snareModel"` |
| `ClapParam` | `Bursts = 0` | `0` for `"clapBursts"` |
| `CymbalParam` | `Color = 0` | `0` for `"cymbalColor"` |
| `CrashParam` | `Color = 0` | `0` for `"crashColor"` |

The runtime uses this value to *both* (a) decide whether the clip is a CommonParam
gain/pan automation, *and* (b) index into the per-kind enum's switch.

### Failure path 1 — automation: `applyDspAutomationAtBeat` silently skips

`engine_juce/src/AutomationPlayback.cpp:702-706`:
```cpp
const uint16_t pid = ac.localParamId;
if (pid == static_cast<uint16_t>(CommonParam::Gain) ||
    pid == static_cast<uint16_t>(CommonParam::Pan)) {
    continue;  // <-- this fires for filterCutoff, attack, decay, etc.
}
```

When `localParamId == 0` is stored for `filterCutoff`, this branch is taken
(incorrectly), the loop `continue`s, and `applyAutomationValue` is never called
for the filter. The actual `SubtractiveSynthParams::filterCutoff` is never
overwritten by the automation curve.

This is why **LFO modulation for filterCutoff is inaudible**: the modulation
path (`DeviceChain.cpp:302-303` and `SubtractiveSynth.cpp:642-644`) has the
identical `if (pid == CommonParam::Gain || pid == CommonParam::Pan) continue;`
check, so the LFO is also dropped on the floor.

### Failure path 2 — automation: block-rate path misroutes the value

`engine_juce/src/DeviceChain.cpp:477-505`:
```cpp
if (ac.localParamId == static_cast<uint16_t>(CommonParam::Gain) ||
    ac.localParamId == static_cast<uint16_t>(CommonParam::Pan)) {
    const bool isGain = ac.localParamId == static_cast<uint16_t>(CommonParam::Gain);
    for (int f = 0; f < framesToProcess; ++f) {
        ...
        s.perFrameGain[f] = val;   // <-- filterCutoff automation ends up here
    }
} else if (!needsSubBlocks) {
    // block-rate apply (only for non-Gain/Pan, non-SubtractiveSynth-with-sub-blocks)
    ...
}
```

The same `if (pid == Gain || pid == Pan)` heuristic also routes the
`filterCutoff` automation into the **per-frame gain** array. So during the
clip's span, `s.perFrameGain[f]` is being modulated by the curve, and the
per-frame multiplier in `multiplyPerFrameGain` (line 627) is what the user
actually hears. The "thinner" sensation is the gain dropping; the "stabs"
are saw-wave cycles modulating gain. The filter cutoff is never touched.

For SubtractiveSynth specifically, the sub-block path is taken (line 646-655)
and `mixSubtractiveMidiNotesBlock` *also* receives the clip — but its inner
`applyDspAutomationAtBeat` has the same skip, so the per-frame filter value
is never set.

## Why the previous "ramp works" observation was a misread

A 1→0 ramp applied to per-frame gain causes the audio to fade from full
amplitude to silence. The user described this as "gets thinner", which is
consistent with a gain fade but is **not** a lowpass filter sweep. The
correct filter-sweep behavior is the audible reduction of *high-frequency
content* (brilliance), not amplitude.

A saw-wave cycle modulating gain at audio rate (4 cycles in 4 beats = 2 Hz
tremolo) sounds exactly like "multiple stabs". A saw-wave cycle modulating
filter cutoff at the same rate would sound like a smooth whooshing
"vwah-vwah" effect.

## Why the previous architect report missed this

The previous verification checked that `paramIdFromString("filterCutoff", SubtractiveSynth)`
returns `0`, and that the dispatch in `applyAutomationValue` correctly maps `0`
to `SubtractiveParam::FilterCutoff`. **Both are true** — but only when the
function is actually *reached*. The "skip if pid == Gain" guard short-circuits
the dispatch before it ever runs.

The skip logic was originally written under the assumption that `0..2` (Gain, Pan,
Bypass) are CommonParam IDs and "all other ids are device-local". That assumption
breaks because every device kind reuses `0` for its first parameter.

## Scope of the bug

This is not specific to filterCutoff. **Any** parameter whose per-kind enum
value is `0` (e.g. Sampler::FilterCutoff, Compressor::InputGain, all
`Model` and `Color` drum-machine params) is misrouted in the same way:

- `attack` on SubtractiveSynth (id 3) is fine
- `osc1Shape` on SubtractiveSynth (id 7) is fine
- `filterCutoff` on SubtractiveSynth (id 0) is **broken**
- `osc1Octave` on SubtractiveSynth (id 9) is fine
- any per-kind `0` is broken

This affects both automation and modulation for the entire set of
"first params" of every device kind. The fix must encode the *kind*, not
just the per-kind id.

## Required Fix (per-kind encoding)

The minimal, type-safe fix is to encode `(kind, id)` into a single
`uint16_t` so the runtime can disambiguate. Since `localParamId` is already
`uint16_t` and the audio thread does a switch-on-kind already, we can
re-encode the value at the control-thread boundary.

The proposed encoding uses the high bits to identify the kind:

```
bits 12-15 : 4-bit kind tag (0..15)
bits 0-11  : 12-bit per-kind id (0..4095)
```

Each device kind is assigned a unique tag (e.g. `CommonParam = 0`,
`OscillatorParam = 1`, `SamplerParam = 2`, `SubtractiveParam = 3`, etc.).
`paramIdFromString` returns the encoded value, and the dispatch in
`applyAutomationValue`, `applyModulation`, etc. extracts the kind tag
first and switches on it before casting the lower bits to the per-kind
enum.

The runtime skip check (`pid == Gain || pid == Pan`) becomes a check
against the encoded CommonParam+0 and CommonParam+1, which no longer
collide with anything else.

## Non-Goals
- Changing the per-kind enum values (we add an outer encoding, not a
  renumbering)
- Changing the JSON wire format (still uses string param names; only the
  in-memory `localParamId` uint16_t changes encoding)
- Modifying the manual knob → DSP path (works correctly)
- Touching the modulation graph or automation clip model
