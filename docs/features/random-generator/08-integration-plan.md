# Integration Plan: Random Generator Modulator

## Recommended Implementation Order

1. **WP1: Engine Implementation** (C++)
2. **WP2: Flutter UI Implementation** (Dart)
3. **WP3: Tests** (C++ + Dart)

## Packages That Can Run in Parallel

**None**. All packages are sequential:

- WP1 must complete first (engine must support the new type at the bridge level)
- WP2 must wait for WP1 (Flutter reads engine-defined contract shapes)
- WP3 must wait for both WP1 and WP2 (tests exercise the full stack)

## Packages That Must Be Sequential

| Sequence | Package | Depends On |
|----------|---------|------------|
| 1 | WP1 (Engine) | Nothing |
| 2 | WP2 (Flutter) | WP1 |
| 3 | WP3 (Tests) | WP1, WP2 |

## Shared Files Requiring Care

| File | Risk | Why |
|------|------|-----|
| `engine_juce/include/audioapp/modulation/ModulatorParams.hpp` | Low | Only WP1 touches it. Adding a struct + variant variant. Must ensure existing `std::get` calls in Lfo/Envelope types still compile. |
| `engine_juce/src/modulation/ModulationGraph.cpp` | Low | Adding include + push_back + clamp fix. The `createLfo` clamp change affects existing types — must verify existing LFO (typeIndex=0) and Envelope (typeIndex=1) still work via bridge. |
| `app_flutter/lib/core/models/project_snapshot.dart` | Low | Adding `smoothing` field. Non-breaking since default is 0.0 which is the existing behavior for non-random-generator types. |

## Integration Steps

### Step 1: Engine Implementation (WP1)
1. Add `RandomGeneratorParams` struct to `ModulatorParams.hpp`
2. Update `ModulatorParams` variant
3. Add `RandomGenerator = 2` to `ModulatorType` enum in `ModulationTypes.hpp`
4. Create `RandomGeneratorModulator.hpp` and `.cpp` (audio-thread evaluation)
5. Create `RandomGeneratorModulatorType.hpp` (type descriptor, header-only)
6. Update `ModulationGraph.cpp`: add include, register in constructor, fix createLfo clamp
7. Build and verify engine compiles

### Step 2: Flutter Implementation (WP2)
1. Add `randomGenerator = 2` to `ModulatorTypes` class
2. Add "Random" entry to modulation grid bottom sheet
3. Add `smoothing` field to `LfoSnapshot`
4. Update `applyParamUpdate()` for random generator params
5. Add `randomGeneratorPreview()` to `ModulatorMath`
6. Add `_randomGeneratorLayout()` to properties panel
7. Wire up rate knob + smoothing knob + retrigger bar + polarity toggle

### Step 3: Integration Verification
1. Build Android APK: `cd app_flutter && flutter build apk --debug`
2. Deploy to device: `.\tools\flutter_deploy.ps1`
3. Manual test:
   - Open app → see modulation grid
   - Tap "+" → see "Random" in bottom sheet
   - Tap "Random" → tile appears with "RND" label
   - Tap tile → properties panel shows rate, smoothing, retrigger, polarity
   - Adjust rate → hear modulation speed change
   - Adjust smoothing → hear stepped vs smooth transitions
   - Toggle polarity → hear unipolar/bipolar difference
   - Save project → reload → random generator parameters preserved

### Step 4: Tests (WP3)
1. Write engine C++ tests covering all contract requirements
2. Write Flutter Dart tests covering JSON parsing, applyParamUpdate, preview math
3. Run all tests and verify pass

## Contract Gaps / Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| LfoSnapshot `polarity: int` currently uses 0/1/2 (with unipolar-neg=2) — Random Generator only uses 0/1 | Low — Flutter side only reads/writes values 0/1 for random generator | Document in code comment that type-2 polarity is 0/1 only |
| `ModulatorMath.randomGeneratorPreview()` is non-deterministic | Visual inconsistency (preview changes each frame) — acceptable since engine random is truly independent | Accept as-is; the changing preview is visually interesting |
| Existing code using `std::get<LfoParams>` or `std::get<EnvelopeParams>` on params must not break when `RandomGeneratorParams` is added | Must verify all existing `std::get` calls are guarded by type checks (they are — via `ModulationGraph::modulatorTypes_[typeIndex]`) | Low risk — existing code accesses `params` through the variant-aware type descriptor, not raw `std::get` |
| Bridge `createLfo` method name is misleading for non-LFO modulators | Medium — `createLfo` and `updateLfoParam` are called for all modulator types | Not in scope for this feature; rename would be a separate refactoring task. The bridge and Flutter code use these names generically. |
| The `ModulationGraph::ModulationGraph()` constructor uses hardcoded `push_back` for each type | Low — adding one more `push_back` is the established pattern | Consider refactoring to auto-registration for future modulators (not in scope) |

## Rollout Checkpoints

1. **Checkpoint A**: Engine builds, tests pass for WP1
2. **Checkpoint B**: Flutter builds, `flutter analyze` has no new errors
3. **Checkpoint C**: APK builds and deploys to device, manual test passes
4. **Checkpoint D**: All C++ and Dart tests pass