# Integration Plan: Phase Modulation Synth Device

## Recommended implementation order

```
         ┌─────────────┐
         │   WP-1      │  DSP core engine (PhaseModSynth.hpp/.cpp)
         │  (DSP core) │  — FULL NEW AUDIO ENGINE
         └──────┬──────┘
                │
                ▼
         ┌──────────────┐
         │   WP-2       │  Engine device registration + instance + serialization
         │  (C++ reg)   │  — connects DSP engine to device pipeline
         └──────┬───────┘
                │
          ┌─────┴──────┐
          │            │
          ▼            ▼
   ┌────────────┐  ┌──────────┐
   │  WP-3      │  │  WP-5    │  Automation types & dispatch
   │  (C++ auto)│  │  (Flutter)│  + Flutter UI (parallel-safe with WP-3)
   └────┬───────┘  └──────────┘
        │
        ▼
   ┌────────────┐
   │  WP-4      │  DeviceChain + LivePerformance dispatch
   │  (C++      │  — routes audio through the PM synth engine
   │  chain)    │
   └────┬───────┘
        │
        ▼
   ┌────────────┐
   │  WP-6      │  Tests
   │  (tests)   │
   └────┬───────┘
        │
        ▼
   ┌────────────┐
   │  WP-INT    │  Build + manual verification
   │  (build)   │
   └────────────┘
```

## Packages that can run in parallel

| Group | Packages | Rationale |
|-------|----------|-----------|
| **Group A** | WP-1 (after contract exists) | DSP core is pure signal processing — no dependencies on device registration, UI, or chain routing. Must be first because WP-2 depends on `PhaseModSynthParams` being defined. |
| **Group B** | WP-2 (after WP-1) + WP-5 (Flutter UI) | WP-2 is pure C++ device registration. WP-5 is pure Flutter UI with mock engine. No file overlap. WP-5 depends on the contract (field names, param IDs) not on WP-2 implementation. |
| **Group C** | WP-3 (after WP-2) | Needs `DeviceNodeKind::PhaseModSynth` (WP-2) and `PhaseModSynthParams` field offsets (WP-1). |
| **Group D** | WP-4 (after WP-3) | Needs WP-1 + WP-2 + WP-3. |
| **Group E** | WP-6 (after WP-1/2/4/5) | Test content can be written after WP-1, but full pass requires all implementations. |
| **Group F** | WP-INT (last) | Requires everything to compile. |

## Shared files requiring care

1. **`DeviceSlot.hpp`** — WP-2 adds include + variant entry. No other package touches this file.
2. **`DeviceChain.hpp`** — WP-2 adds `DeviceNodeKind::PhaseModSynth` + updates `DeviceVariantParams`. Only WP-2 touches.
3. **`LivePerformance.hpp`** — WP-2 adds `LiveInstrumentKind::PhaseModSynth` + `phaseMod` field to `LiveInstrumentSnapshot`. Only WP-2 touches.
4. **`DeviceRegistry.cpp`** — Only WP-2 touches. No merge conflicts possible.
5. **`AutomationTypes.hpp`** — WP-3 adds `ParamKind::PhaseModSynth` + `PhaseModSynthParam` enum. WP-3 also adds to pack/unpack tables in AutomationPlayback.cpp. Only WP-3 touches.
6. **`DeviceChain.cpp`** / **`LivePerformance.cpp`** — Only WP-4 touches.
7. **`device_strip_slot.dart`** — WP-5 adds `'phase_mod_synth'` case. No conflict with other Flutter files.
8. **`project_snapshot.dart`** — WP-5 adds 54 PM fields to `DeviceSnapshot`. No other package modifies this.

## Parallel execution strategy

1. **Start**: WP-1 (DSP core) — must be written first. This is the foundational new audio engine.
2. **After WP-1 header is defined**: WP-2 + WP-5 in parallel.
   - WP-2: All C++ registration, instance, serialization
   - WP-5: All Flutter UI (panel, strip, editor, presets, snapshot fields)
3. **After WP-2**: WP-3 (automation dispatch) — needs WP-1 + WP-2 types
4. **After WP-3**: WP-4 (chain/live routing) — needs all C++ infrastructure
5. **After WP-1/2/4/5**: WP-6 (tests) — needs implementation to test against
6. **Last**: WP-INT (build + manual verification)

## Contract gaps or risks

1. **Risk: New DSP engine complexity** — Unlike BassSynth (which wraps SubtractiveSynth), PhaseModSynth is a from-scratch PM engine. The audio quality, aliasing behavior, and performance on mobile are unproven. Mitigation: Keep operators simple (sine-based), use phase modulation not raw FM, test on device early.
2. **Risk: 4 operators + unison on mobile** — 4 operators × up to 4 unison voices = 16 oscillators per voice × 8 voices = 128 oscillators. This may be CPU-heavy on older Android devices. Mitigation: `kPhaseModMaxVoices = 8` but default to fewer; designers can tune.
3. **Risk: Algorithm routing is complex** — 8 algorithms with different modulation paths must be correct in the inner loop. Mitigation: Algorithm routing is a simple switch statement mapping modulator outputs to carrier phase inputs. Each algorithm is tested in Test A4 (algorithm selection).
4. **Risk: ADSR envelope implementation** — Per-operator ADSR with proper segment timing is critical for PM sound. Mitigation: Match existing SubtractiveSynth envelope implementation for consistency.
5. **Risk: Large Flutter `DeviceSnapshot`** — 54 new fields added to `project_snapshot.dart`. This creates a large `DeviceSnapshot` class but follows the existing pattern. Mitigation: Ensure `fromMap`, `copyWith`, and `withParameter` are correctly generated.
6. **Risk: 54 parameters in the device panel** — The panel must be carefully laid out across 4 tabs. Mitigation: Tab 2 (OP) uses operator selector to show only one operator's controls at a time (same pattern as Ableton Operator).
7. **Risk: Feedback instability** — Self-feedback in digital PM can easily blow up. Mitigation: Clamp feedback output to [-1, 1], use soft clipping.
8. **Risk: LFO implementation** — The global LFO runs per-voice (not truly global) in MVP, which means each voice starts at a different LFO phase on note-on. Mitigation: Document this limitation for MVP; note as future enhancement.
9. **Contract gap: String parameter for algorithm** — The `setStringParameter` method for algorithm selection by name requires a mapping from name to index. This is documented in the API contracts but must be implemented exactly as specified.
10. **Contract gap: Waveform generation** — The morphable waveform (sine→tri→saw→square→noise) should reuse the existing `subtractiveMorphWaveSample()` function from `SubtractiveSynth.hpp` where possible, or implement identical logic inline for the PM operators.