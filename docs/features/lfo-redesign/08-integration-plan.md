# Integration Plan: LFO Modulator Redesign

## Recommended implementation order

```
WP1 (C++ engine params)
└─► WP2 (Dart LfoSnapshot model)
    └─► WP3 (Dart math + preview painter)
        └─► WP4 (Dart properties panel UI)
```

## Parallelization matrix

| WP | Parallel-safe with | Blocked by |
|----|--------------------|------------|
| WP1 | WP2 (with contract) | None |
| WP2 | WP1 (needs JSON shape) | WP1 merge or shared stub |
| WP3 | Nothing | WP2 (model fields) |
| WP4 | Nothing | WP2 + WP3 |

### Effective parallelism

| Batch | Work packages | Reason |
|-------|---------------|--------|
| Batch 1 | WP1 + stub of WP2 (contract only) | WP1 is independent; WP2 model can be implemented from JSON spec without WP1 compiled |
| Batch 2 | WP2 + WP3 | WP2 model must exist first; WP3 depends on it; these can run in parallel if WP2 is stubbed |
| Batch 3 | WP4 (alone) | Requires both WP2 and WP3 |

**Practical recommendation:** Run WP1 first (small, fast), then run WP2+WP3 in parallel (model + math), then WP4.

## Contract stubs needed for parallelism

If running WP1 and WP2 in parallel, provide this stub for the JSON contract:

```
Morph key:     "morph"     → double, default 0.0
Spread key:    "spread"    → double, default 0.5
AnalogMode key:"analogMode"→ int, default 0
```

If running WP3 before WP2 is merged (not recommended), stub:

```
class LfoSnapshot {
  double get morph => 0.0;
  double get spread => 0.5;
  int get analogMode => 0;
  int get waveform => 0;
}
```

## Integration risks

| Risk | Mitigation |
|------|------------|
| WP3 `lfoWaveMorph` evaluation disagrees with eventual engine implementation | Morph is client-side only for this phase; engine evaluation is unchanged. Future engine morph can use same algorithm |
| Spread at extreme values (0 or 1) produces degenerate waveforms | Test that output stays in [-1, 1]; degenerate is acceptable visual behavior |
| WP4 panel is too tall for small mobile screens | Pin knobs to bottom, use Expanded for preview, compress retrigger/chip rows |
| DG/AN toggle state is not persisted (UI-only) — analogMode IS persisted in engine, but morph/spread values are reset on toggle | This is intentional: AN mode sets fixed engine values. Restoring last DG values would require additional UI state management (future enhancement) |
| Backward compat: old projects with polarity=2 still load correctly | Engine serialization unchanged; Dart parser still reads polarity=2; UI simply doesn't show it |

## Contract gaps or risks

1. **Spread implementation detail**: The exact spread mapping function may require visual tuning. The contract defines the conceptual behavior (remap phase for square PWM, peak shift for tri/saw, through-zero offset for sine). Implementation worker should verify on device.

2. **Morph at exact boundaries**: At morph=0.0, 0.25, 0.5, 0.75, 1.0 the output should EXACTLY match the pure waveform. Floating-point arithmetic for `seg * 4.0` at these exact values should produce integer `idx`. Implementation must handle floating-point edge cases (e.g., 1.0 - epsilon rounding).

3. **curvePoints update**: The existing `curvePoints` method must be extended to use `lfoWaveMorph` for LFO-type modulators. This is a small change but has visual impact on the modulation grid tile preview. Ensure the grid tile preview updates correctly.

4. **No animated playhead**: The new `LfoPreviewWidget` is explicitly static. The existing animated playhead dot remains in the modulation grid tile (`ModulatorPreview` / `phaseDot`). No changes needed there.

## Demo sequence

1. Open project with existing LFO → panel shows new layout
2. Toggle morph knob → waveform preview updates in real time
3. Toggle spread knob → waveform skews visually
4. Toggle DG/AN → morph and spread jump to fixed values
5. Toggle polarity ↔ preview redraws with correct visualization
6. Save and reload project → morph/spread values persist
7. Load old project without morph/spread → defaults apply