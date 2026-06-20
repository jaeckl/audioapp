# Integration Plan: Bass Synth Device

## Recommended implementation order

```
         ┌─────────────┐
         │   WP-1      │  Engine registration + instance + playback
         │  (C++ core) │
         └──────┬──────┘
                │
          ┌─────┴──────┐
          │            │
          ▼            ▼
   ┌──────────┐  ┌──────────┐
   │  WP-2    │  │  WP-5    │  DeviceState fields + Flutter UI
   │  (DTO)   │  │  (Flutter)│  (WP-1 creates the contract stubs)
   └────┬─────┘  └──────────┘
        │
        ▼
   ┌──────────┐
   │  WP-3    │  Automation types & dispatch
   │  (C++    │
   │  auto)   │
   └────┬─────┘
        │
        ▼
   ┌──────────┐
   │  WP-4    │  DeviceChain + LivePerformance dispatch
   │  (C++    │
   │  chain)  │
   └────┬─────┘
        │
        ▼
   ┌──────────┐
   │  WP-6    │  Tests
   │  (test)  │
   └────┬─────┘
        │
        ▼
   ┌──────────┐
   │  WP-INT  │  Build + manual verification
   │  (build) │
   └──────────┘
```

## Packages that can run in parallel

| Group | Packages | Rationale |
|-------|----------|-----------|
| **Group A** | WP-1 + WP-5 + WP-6 (contract skeleton) | WP-1 is pure C++ engine, WP-5 is pure Flutter UI, WP-6 is test skeletons — no file overlap, no runtime dependency |
| **Group B** | WP-2 + WP-1 | WP-2 only modifies `DeviceState.hpp`. WP-1 adds `BassSynthInstance`. Both can proceed simultaneously if WP-1's field list is specified in the contract |
| **Group C** | WP-3 (after WP-2) | Needs DeviceNodeKind (WP-1) + DeviceState field names (WP-2) |
| **Group D** | WP-4 (after WP-3) | Needs WP-1 + WP-3 |
| **Group E** | WP-6 (full tests after WP-1/2/4/5) | Test content can be written after WP-1, but full pass requires all implementations |
| **Group F** | WP-INT (last) | Requires everything to compile |

## Shared files requiring care

1. **`DeviceSlot.hpp`** — WP-1 adds include + variant entry. No other package touches this file.
2. **`DeviceChain.hpp`** — WP-1 adds `DeviceNodeKind::BassSynth`. Only WP-1 touches.
3. **`DeviceState.hpp`** — WP-1 reads it, WP-2 adds bass fields. WP-2 MUST NOT break the existing field layout or order.
4. **`DeviceRegistry.cpp`** — Only WP-1 touches. No merge conflicts possible.
5. **`device_strip_slot.dart`** — WP-5 adds `'bass_synth'` case. The switch contains ~15 existing cases; WP-5 adds one more. No conflict with other Flutter files.
6. **`project_snapshot.dart`** — WP-5 adds 9 fields to `DeviceSnapshot`. No other package modifies this.

## Contract gaps or risks

1. **Risk: Missing `DeviceState` fields** — if a bass-specific field is accidentally omitted from `DeviceState`, the JSON snapshot will lack that field and defaults will apply on reload. The round-trip test (Test 2) catches this.
2. **Risk: `SubstractiveSynthParams` defaults change** — the `toPlaybackParams()` mapping hardcodes values. If future changes to `SubtractiveSynth` defaults shift the baseline, bass params must be reviewed.
3. **Risk: Duplicate parameter IDs** — `filterCutoff` and `filterEnvAmount` are shared param IDs between SubtractiveSynth and BassSynth. This is safe because they use the same `ParamKind::BassSynth` prefix in packed IDs, but the `setParameter` implementation must use bass-specific parameter IDs not subtractive-synth ones.
4. **Risk: `outputPanelWidthFor`** — the BassSynth outputs in stereo, so `outputPanelWidthFor("bass_synth")` should return `stereoOutputPanelWidth`. Ensure this is handled (falls through to default in the switch already — stereoOutputPanelWidth is the default). Verified safe.
5. **Risk: `_cardSubtitle`** — ensure subtitle "Mono · Sub" is added to the switch in `device_strip_slot.dart`.
6. **Contract gap: Modulatable parameters vs automation** — modulatable params and `BassSynthParam` enum should be reviewed for completeness. All 16 bass params should be automatable and at least 14 should support modulation (leaving out `bassOctave` and `bassSubOctave` as discrete).
7. **Risk: DeviceChain.cpp `nodeHasDspAutomation` logic** — the `BassSynth` case must return `false` (same as `SubtractiveSynth`) to indicate per-sample processing. The `isInstrumentDeviceNodeKind` helper must include `BassSynth`.