# Golden file testing (engine tests)

The engine render is **not sample-exact** across runs due to unordered iteration
and pointer-based ordering. Instead of comparing raw samples, we store an
`AudioFingerprint` — aggregate metrics that are empirically stable.

## Data structure

```
AudioFingerprint
├── frameCount        (uint64_t)  # total samples rendered
├── peak              (float)     # peak absolute sample
├── rms               (float)     # full-buffer RMS
└── rmsVariationRatio (float)     # max/min window-RMS over 8 windows
```

Golden files are a direct binary dump of `AudioFingerprint` (24 bytes).
Stored in `engine_juce/tests/golden/`.

## Tolerance

Comparison uses **2× relative tolerance** on all three float metrics:

```
|got - expected| / expected  ≤  2.0
```

This is loose enough to survive non-deterministic renders but tight enough
to catch regressions (wrong filter type, broken modulation, missing device).

## How to use

### 1. Convert a test to golden

Replace spectral-ratio / peak-counting assertions with a single call:

```cpp
expect(audioapp::test::checkRenderGolden(
    "my_test.bin", host, lengthBeats, sampleRate));
```

`checkRenderGolden` calls `renderOffline`, computes the fingerprint, and
either writes the golden file or compares against it (controlled by the
build define).

### 2. Regenerate golden files

```bash
cmake -S engine_juce -B build/engine -G Ninja -DAUDIOAPP_REGENERATE_GOLDEN=ON
cmake --build build/engine --target audioapp_juce_tests
./build/engine/audioapp_juce_tests
```

Each golden test prints `GOLDEN REGENERATED: <name>` on first run.
Commit the new `.bin` files.

Also works via the shortcut (Windows):

```bash
cmake -B build/engine -DAUDIOAPP_REGENERATE_GOLDEN=ON
build_only.bat
```

### 3. Run in comparison mode (normal CI)

```bash
cmake -S engine_juce -B build/engine -G Ninja -DAUDIOAPP_REGENERATE_GOLDEN=OFF
cmake --build build/engine --target audioapp_juce_tests
./build/engine/audioapp_juce_tests
```

No `GOLDEN` output means golden files matched. Mismatches print diagnostics
showing expected vs actual values per metric.

## When to regenerate

- Engine rendering changed intentionally (new DSP, different topology)
- A test was added or its render parameters changed
- The `AudioFingerprint` struct layout changed (rare)

Do **not** regenerate to work around a real regression — investigate first.

## Currently golden-converted tests (32 golden files)

| Test file | Golden files |
|-----------|-------------|
| `automation_filter_sweep_test.cpp` | `automation_filter_sweep.bin` |
| `automation_sampler_filter_sweep_test.cpp` | `automation_sampler_filter_sweep.bin` |
| `lfo_polarity_test.cpp` | 5 files (bipolar, bipolar_solo, positive, positive_solo, negative) |
| `lfo_sync_bpm_test.cpp` | 8 files (sync ratios, free vs sync, bpm 60/120) |
| `modulation_e2e_test.cpp` | 12 files (lfo filtercutoff, mod+auto, multi-edge, unmod, mod, retrigger, with/without mod, slow/fast, with_lfo, after_remove) |
| `stacked_lfo_modulation_test.cpp` | 5 files (diff_params, same_param, single, both, one) |

## API reference (TestHelpers.h)

| Function | Purpose |
|----------|---------|
| `computeFingerprint(samples)` | Build `AudioFingerprint` from a float buffer |
| `writeGolden(name, fp)` | Serialize fingerprint to `tests/golden/<name>` |
| `matchesGoldenFingerprint(name, got)` | Load golden and compare with 2× tolerance |
| `checkRenderGolden(name, host, len, sr)` | Render + compare (or regenerate if `-DAUDIOAPP_REGENERATE_GOLDEN=ON`) |

All functions are in `namespace audioapp::test` (`TestHelpers.h`).