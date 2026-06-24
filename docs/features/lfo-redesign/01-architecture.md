# Architecture: LFO Modulator Redesign

## Architecture decision

The LFO morph/spread is computed **entirely on the client side** (Dart/Flutter) for preview rendering. The C++ engine continues to use the discrete `waveform` integer internally — morph is a UI-only concept that maps to a client-side evaluation function.

**Rationale:** The engine audio thread must remain deterministic and low-latency. Continuous waveform morphing would require either:
- Pre-computing blended wavetables (complex, memory overhead)
- Real-time interpolation (extra math per sample, hard to tune)
- Treating morph as a control-rate parameter that warps the LFO output after evaluation

None of these improve the audio quality meaningfully. The client-side preview only needs to show what the morphed wave *looks like* — the actual audio output can remain discrete-waveform-based, or morph can be added to the engine in a future phase if needed.

## Module boundaries

| Layer | Responsibility |
|-------|----------------|
| C++ `LfoParams` | Store `morph` and `spread` floats alongside existing fields; serialize/deserialize them; add `setParameter` entries |
| Dart `LfoSnapshot` | Parse `morph` and `spread` from engine JSON; `copyWith` support; wire-to-widget |
| Dart `ModulatorMath` | `lfoWaveMorph(waveform, morph, spread, phase)` — client-side preview evaluation |
| Dart `LfoPreviewPainter` | Custom painter for the static waveform preview (no playhead dot) |
| Dart `ModulatorPropertiesPanel` | New `_lfoLayout` matching the envelope pattern; DG/AN toggle; morph/spread knobs |
| Dart `ModulatorRateCodec` | Add `morphLabel`/`spreadLabel` display formatting |

## Threading/async

- `LfoParams` mutation: control thread only (same as all existing params)
- Preview evaluation: Flutter UI thread (same as `ModulatorMath.curvePoints`)
- No changes to audio-thread path

## Error model

- `morph` clamped to [0, 1] in engine `setParameter`
- `spread` clamped to [0, 1] in engine `setParameter`
- Backward compat: old JSON without `morph`/`spread` fields defaults to 0.0 / 0.5 respectively

## Persistence model

- `morph` and `spread` serialized as JSON doubles in `paramsToVar` / `varToParams`
- Old projects load with defaults (morph=0.0, spread=0.5)
- No migration needed

## UI/state synchronization

- `onUpdate('morph', v)` and `onUpdate('spread', v)` use the existing `updateLfoParam` bridge channel (same as all other params)
- Engine persists immediately (same as existing pattern)
- No new bridge methods needed