# Architecture: Phase Modulation Synth Device

## Overview

`PhaseModSynth` is a **full new audio engine** that implements phase modulation (PM) synthesis — mathematically equivalent to FM but implemented as phase modulation of sine oscillators for better aliasing control. It follows the same device registration pattern as `SubtractiveSynth`, `KickGenerator`, etc., but introduces its own DSP engine rather than wrapping an existing one.

The device features 4 sine-based operators with configurable frequency ratios, ADSR envelopes per operator, an algorithm routing matrix (8–10 preset algorithms), feedback, global LFO, per-operator waveform selection, and a shared filter section reusing the existing `SubtractiveSynth` filter biquad.

## Architecture diagram

```
┌──────────────────────────────────────────────────────────────────┐
│  Flutter UI                                                       │
│  PhaseModSynthDevicePanel (ALGO | OP | MOD | TONE tabs)          │
│  PhaseModSynthDeviceStrip (compact card wrapper)                  │
│  PhaseModSynthEditorScreen (fullscreen editor)                    │
│  DevicePickerSheet (list entry)                                   │
│  DeviceSnapshot (pm* fields + existing filter/amp fields)         │
└──────────────────────┬───────────────────────────────────────────┘
                       │ JSON snapshot
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│  C++ DeviceRegistry → findForSlot()                              │
│  → PhaseModSynthDeviceType (IDeviceType impl)                    │
│    ├─ createDefault()  (4 ops, algorithm 0, default params)      │
│    ├─ slotToVar() / varToSlot()  (JSON via juce::DynamicObject)  │
│    ├─ setParameter()   (all pm* params + filter/amp/global)      │
│    ├─ setStringParameter()  (algorithm selection by name)        │
│    ├─ buildPlaybackNode() ─┐                                     │
│    └─ buildLiveInstrument()─┤                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│  PhaseModSynthInstance (4 × operator configs + global + filter)   │
│  toPlaybackParams() → PhaseModSynthParams (audio-thread struct)   │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│  DeviceNodeKind::PhaseModSynth                                    │
│  → std::get<PhaseModSynthParams>(...)                             │
│  → mixPhaseModMidiNotesBlock()                                    │
│    (new audio path — phase modulation engine)                      │
└──────────────────────────────────────────────────────────────────┘
```

## DSP architecture (PhaseModSynth engine)

### Operator model

Each of the 4 operators is a sine oscillator with:

- **Phase accumulator** (float, wraps at 2π)
- **Frequency** = noteHz × ratio × 2^(fine/1200)
- **Waveform** sine (default), triangle, saw, square, noise — shape morph applied post-phase
- **Level** (output gain of this operator)
- **ADSR envelope** (per-operator A, D, S, R)
- **Output bus**: routes to mix (carrier) or to another operator's phase input (modulator)

### Algorithm matrix

8 preset algorithms defining which operators modulate which:

| # | Name | Routing |
|---|------|---------|
| 0 | 4-op stack | 1→2→3→4 (all carriers) |
| 1 | 3→1 | 1→2→3, 4 carrier |
| 2 | 3→2 | 1→2→3, 4 carrier |
| 3 | 2→1×2 | 1→2, 3→4, 2+4 out |
| 4 | 4→1 | 1→2→3→4 (carrier) |
| 5 | 1→2 pair | 1→2, 3→4, 2+4 out |
| 6 | 1→1×2 | 1→2, 3, 4 all |
| 7 | All mod | 1→2→3→4, with feedback on 1 |

Operators marked as "carriers" output to the master mix. Modulators output to the phase input of their target operator(s). The algorithm is stored as an index (0-7) and implemented in a switch in the per-sample render function.

### Feedback

Operator 1 can have a self-feedback path: a fraction of operator 1's output from the previous sample is added to operator 1's phase input. This creates classic FM feedback tones (brass, distortion).

### Signal flow

```
note frequency
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  Per-operator processing (based on algorithm matrix): │
│                                                       │
│  For each operator (in algorithm-defined order):      │
│    1. Compute base phase += freq * 2π / sampleRate   │
│    2. Add modulation inputs from source operators     │
│    3. Add feedback (if op 1 and feedback enabled)     │
│    4. Read sine wave sample                           │
│    5. Apply waveform shape morph                      │
│    6. Apply ADSR envelope                             │
│    7. Apply operator level                            │
│    8. If carrier → sum to output mix                  │
│    9. If modulator → store for target operator input  │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────┐
│  Filter (reuse SubtractiveSynphonic)  │
│  → SamplerFilter Biquad              │
└──────────────┬───────────────────────┘
               ▼
┌──────────────────────────────────────┐
│  Amp envelope + gain + pan           │
└──────────────────────────────────────┘
```

### Threading model

- **Control thread**: `PhaseModSynthDeviceType` methods, `PhaseModSynthInstance` parameter changes, snapshot serialization, preset loading
- **Audio thread**: `DeviceNodePlayback` (holds `PhaseModSynthParams`), `LiveInstrumentSnapshot` (holds `phaseMod` field), `PhaseModSynthRuntime`
- The mapping from `PhaseModSynthInstance` → `PhaseModSynthParams` happens on the control thread during `buildPlaybackNode` / `buildLiveInstrument`
- All 4 operators processed in a single audio callback (no extra threading)

### Threading model — additional detail

- `PhaseModSynthParams` is copied to audio thread as part of `DeviceVariantParams` (the new `PhaseModSynthParams` variant entry)
- Runtime state (voice phases, envelope values) lives in `PhaseModSynthRuntime` which is only touched on the audio thread
- LFO modulation is applied via the existing `lfoValues` / `ModulationEdgePlayback` arrays — mapping to PM-specific params uses the same pattern as SubtractiveSynth

### Error model

- Unknown parameter IDs: return `DeviceParameterResult{handled: false}` (no error)
- Out-of-range values: clamp to [0, 1] or discrete range
- Invalid operator selection: operator index clamped to [0,3]
- Invalid algorithm index: clamp to [0, 7]
- Device registration: registered in `createBuiltIn()`; if not found, `find()` returns nullptr
- Division by zero: operator frequency = 0 at ratio 0 handled by min frequency floor

### Persistence model

- `PhaseModSynthInstance` state serialized via `slotToVar()` / `varToSlot()` using `juce::DynamicObject` (same pattern as SubtractiveSynth, BassSynth)
- JSON field names are prefixed with `pm` for PM-specific params (e.g. `pmOp1Ratio`, `pmAlgoIndex`)
- Existing shared fields reused for filter: `filterCutoff`, `filterQ`, `filterEnvAmount`, etc.
- Existing shared fields reused for amp: `attack`, `decay`, `sustain`, `release`
- Full save/load round-trip: `slot → slotToVar() → JSON → varToSlot()`
- Factory presets stored in `app_flutter/lib/features/device_strip/phase_mod_synth_presets.dart` as Dart constants (exported as `List<Map<String, dynamic>>`)

### UI/state sync model

- Flutter `DeviceSnapshot` receives `pm*` fields from JSON engine snapshot
- `DeviceSnapshot.copyWith(pmOp1Ratio: v)` → bridge → engine `setParameter('pmOp1Ratio', v)` → `PhaseModSynthDeviceType`
- Algorithm selection is a `setStringParameter('pmAlgo', 'stack_4')` call that maps algorithm name to index
- LFO modulation: `modulatableParams()` returns selected PM params for LFO routing
- Automation: filter/amp params support automation clips; operator params support automation via `ParamKind::PhaseModSynth`