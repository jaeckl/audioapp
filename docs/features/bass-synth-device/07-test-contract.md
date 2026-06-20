# Test Contract: Bass Synth Device

## C++ tests (engine_juce/tests/bass_synth_test.cpp)

### Test 1: DefaultInstance
- Call `BassSynthDeviceType::createDefault("test-id")`
- Verify `slot.id == "test-id"`
- Verify `std::holds_alternative<BassSynthInstance>(slot.instance)`
- Verify default values match contract: `oscShape == 0.3f`, `subMix == 0.5f`, `filterCutoff == 0.85f`, etc.

### Test 2: ToSnapshotRountrip
- Create default slot
- Call `toSnapshotState(slot)` → get `DeviceState`
- Verify `state.type == device_types::kBassSynth`
- Verify bass fields match: `state.bassOscShape == 0.3f`, `state.bassSubMix == 0.5f`, etc.
- Call `slotFromSnapshot(state)` → get new slot
- Verify `std::holds_alternative<BassSynthInstance>(newSlot.instance)`
- Verify all 16 fields match original

### Test 3: SetParameter
- Create default slot
- For each bass parameter ID:
  - Call `setParameter(slot, paramId, newValue)`
  - Verify `result.handled == true`
  - Get instance from slot and verify field updated
- For unknown param ID:
  - Call `setParameter(slot, "bogus", 0.5)`
  - Verify `result.handled == false`

### Test 4: SetParameterClamping
- Set `bassOscShape` to 1.5 → verify clamped to 1.0
- Set `bassOscShape` to -0.5 → verify clamped to 0.0
- Set `bassSubOctave` to 5 → verify clamped to 2
- Set `bassOctave` to -1 → verify clamped to 0

### Test 5: BuildPlaybackNode
- Create default slot, set some params
- Call `buildPlaybackNode(slot, ctx, out)`
- Verify `out.kind == DeviceNodeKind::BassSynth`
- Verify `out.params` holds `SubtractiveSynthParams`
- Verify hardcoded properties: `filterMode == 0`, `synthMono == 1.0f`, `synthLegato == 1.0f`, `oscMixMode == 0`, `filterSustain == 0.0f`

### Test 6: BuildPlaybackNodeMapping
- Set `bassOscShape = 0.0f` → verify `osc1Shape == 0.0f`
- Set `bassOscShape = 1.0f` → verify `osc1Shape == 1.0f`
- Set `bassSubMix = 0.25f` → verify `oscMix == 0.25f`
- Set `bassDrive = 0.5f` → verify `filterDrive == 0.5f` and `preDrive == 0.25f`
- Set `bassSquash = 0.7f` → verify `mixFeedback == 0.7f`
- Set `octave = 0` → verify `globalPitch == 0.0f`
- Set `octave = 4` → verify `globalPitch == 0.5f`
- Set `subOctave = 0` → verify `osc2Shape == 0.0f` (sine)

### Test 7: BuildLiveInstrument
- Create default slot
- Call `buildLiveInstrument(slot, ctx, out)`
- Verify `out.kind == LiveInstrumentKind::BassSynth`
- Verify `out.subtractive` is populated correctly (same as playback params)

### Test 8: ModulatableParams
- Call `modulatableParams()`
- Verify result contains `"gain"`, `"pan"`, `"bassOscShape"`, `"filterCutoff"`, etc.
- Verify total is at least 16

### Test 9: SetStringParameter
- Call `setStringParameter(slot, "anything", "value", ctx)`
- Verify returns `false`

### Test 10: DeviceRegistryIntegration
- Get registry from `DeviceRegistry::createBuiltIn()`
- Verify `find("bass_synth")` returns non-null
- Create slot via `createDefault("bass_synth", "test-id")`
- Verify slot has `BassSynthInstance`
- Call `setParameter(slot, "bassOscShape", 0.8)`
- Verify `toSnapshotState(slot)` has `bassOscShape == 0.8f`

## Flutter widget tests (app_flutter/test/bass_synth_snapshot_test.dart)

### Test 11: FromMap
- Create a mock JSON map with `type: "bass_synth"` and all bass params
- `DeviceSnapshot.fromMap` returns snapshot with correct bass fields
- Defaults are applied when fields are missing

### Test 12: CopyWith
- Create default snapshot
- Call `copyWith(bassOscShape: 0.9)` → verify `bassOscShape == 0.9`
- Other fields unchanged

### Test 13: WithParameter
- Create default snapshot
- Call `withParameter("bassOscShape", 0.9)` → verify `bassOscShape == 0.9`
- Call `withParameter("bassSubOctave", 2)` → verify `bassSubOctave == 2`
- Call `withParameter("bogus", 0.5)` → verify all fields unchanged

## Manual verification (local developer)

1. Insert Bass Synth from picker → verify card shows "Bass Synth · Mono · Sub"
2. Tweak every knob → verify audible change in sound output
3. Save project → close → reopen → verify all bass params restored
4. Press MIDI notes legato → verify glide between overlapping notes
5. Record automation on `filterCutoff` → play back → verify filter sweep