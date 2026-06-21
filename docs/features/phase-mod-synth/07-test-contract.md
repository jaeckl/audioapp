# Test Contract: Phase Modulation Synth Device

## C++ tests (engine_juce/tests/phase_mod_synth_test.cpp)

### Group A: DSP engine tests (PhaseModSynth)

#### Test A1: VoiceSampleBasics
- Create a `PhaseModSynthParams` with default values, something = algo 0 (stack_4)
- Create a `PhaseModSynthVoiceRuntime` (zeroed)
- Call `phaseModVoiceSample(voice, params, 1.0f, 1.0f, 44100.0, 0.0f)` for one frame
- Verify output is non-zero (carrier produces sound)
- Verify no NaN, no inf

#### Test A2: VoiceSampleSilence
- Set all operator levels to 0.0
- Call `phaseModVoiceSample` → verify output is 0.0

#### Test A3: ModulationProducesSidebands
- Set algo 0 (stack_4), op1 carrier at ratio 1.0, op2 modulator at ratio 5.0 with high level
- Run voice sample, verify output is more complex than pure sine
- This is a spectral sanity check — the output should differ from a simple sine

#### Test A4: AlgorithmSelection
- For each algorithm 0..7, verify the output routing is different/sensible
- At minimum verify that switching algorithms changes output

#### Test A5: AdsrEnvelopeAttack
- Set op attack to a long value (e.g., 0.9), run samples, verify envelope rises from 0 to peak over attack time

#### Test A6: AdsrEnvelopeDecaySustain
- Set op decay to moderate, sustain to 0.5, run samples past attack, verify envelope reaches sustain level

#### Test A7: AdsrEnvelopeRelease
- Trigger release (set voice state to release), verify envelope fades to 0

#### Test A8: FilterBiquad
- Set filter cutoff low, verify high frequencies attenuated compared to filter fully open

#### Test A9: Feedback
- Enable feedback on algorithm 7 (all_mod_fb), set feedback to 0.9, verify output is audibly different and more distorted

#### Test A10: LfoModulation
- Set LFO to modulate pitch, run voice across multiple samples, verify pitch changes over time following LFO waveform

#### Test A11: MidiBlockRender
- Create `PhaseModSynthParams`, `PhaseModSynthRuntime`, one `SubtractiveMidiNoteRegion` (note 60)
- Call `mixPhaseModMidiNotesBlock()` for 441 frames (10ms at 44.1kHz)
- Verify output buffer has non-zero samples
- Verify voice runtime is active (stealIndex advanced, voice states set)

#### Test A12: Unison
- Set unisonVoices to 1.0 (4 voices), create voice, render samples
- Verify output has different phase/detune per voice

#### Test A13: LiveVoice
- Call `renderPhaseModLiveVoice()` for one frame with valid params and voice
- Verify non-zero output

### Group B: Instance and device type tests

#### Test B1: DefaultInstance
- Call `PhaseModSynthDeviceType::createDefault("test-id")`
- Verify `slot.id == "test-id"`
- Verify `std::holds_alternative<PhaseModSynthInstance>(slot.instance)`
- Verify default values match contract: `algoIndex == 0`, `feedback == 0.0`, `op[0].ratio == 0.0625`, etc.

#### Test B2: ToSnapshotRoundtrip
- Create default slot
- Call `slotToVar(slot)` → get `juce::var`
- Modify some params (set op1 ratio to 0.5, algo to 3, feedback to 0.5)
- Call `varToSlot(var)` → get new slot
- Verify `std::holds_alternative<PhaseModSynthInstance>(newSlot.instance)`
- Verify modified params match: `instance.op[0].ratio == 0.5`, `instance.algoIndex == 3`, `instance.feedback == 0.5f`

#### Test B3: SetParameter
- Create default slot
- For each PM-specific parameter ID:
  - Call `setParameter(slot, paramId, newValue)`
  - Verify `result.handled == true`
  - Get instance from slot and verify field updated
- For unknown param ID:
  - Call `setParameter(slot, "bogus", 0.5)`
  - Verify `result.handled == false`

#### Test B4: SetParameterClamping
- Set `pmOp1Level` to 1.5 → verify clamped to 1.0
- Set `pmOp1Level` to -0.5 → verify clamped to 0.0
- Set `pmAlgoIndex` to 10 → verify clamped to 7

#### Test B5: SetStringParameterAlgo
- Call `setStringParameter(slot, "pmAlgo", "stack_4", ctx)` → verify returns true, algoIndex == 0
- Call `setStringParameter(slot, "pmAlgo", "chain_4", ctx)` → verify returns true, algoIndex == 4
- Call `setStringParameter(slot, "pmAlgo", "bogus", ctx)` → verify returns false
- Call `setStringParameter(slot, "unhandled", "value", ctx)` → verify returns false

#### Test B6: BuildPlaybackNode
- Create default slot, set some params
- Call `buildPlaybackNode(slot, ctx, out)`
- Verify `out.kind == DeviceNodeKind::PhaseModSynth`
- Verify `out.params` holds `PhaseModSynthParams`
- Verify params match: algoIndex, operator[0].level, etc.

#### Test B7: BuildLiveInstrument
- Create default slot
- Call `buildLiveInstrument(slot, ctx, out)`
- Verify `out.kind == LiveInstrumentKind::PhaseModSynth`
- Verify `out.phaseMod` is populated correctly

#### Test B8: ModulatableParams
- Call `modulatableParams()`
- Verify result contains `"gain"`, `"pmFeedback"`, `"pmOp1Level"`, `"filterCutoff"`, etc.
- Verify total matches contract

#### Test B9: DeviceRegistryIntegration
- Get registry from `DeviceRegistry::createBuiltIn()`
- Verify `find("phase_mod_synth")` returns non-null
- Create slot via `createDefault("phase_mod_synth", "test-id")`
- Verify slot has `PhaseModSynthInstance`
- Call `setParameter(slot, "pmOp1Level", 0.9)`
- Verify `slotToVar(slot)` JSON has `pmOp1Level` as 0.9

## Flutter tests (app_flutter/test/phase_mod_synth_snapshot_test.dart)

### Test F1: DeviceSnapshotFromMap with all PM fields
- Create a mock JSON map with `type: "phase_mod_synth"` and all 54 PM params
- `DeviceSnapshot.fromMap` returns snapshot with correct PM fields
- Verify `pmOp1Ratio == 0.0625`, `pmAlgoIndex == 0`, `pmFeedback == 0.0`, etc.

### Test F2: DeviceSnapshotFromMap with defaults
- Create a minimal mock JSON with just `type: "phase_mod_synth"` and no PM fields
- `DeviceSnapshot.fromMap` returns snapshot with default values for all PM fields

### Test F3: CopyWith
- Create default snapshot
- Call `copyWith(pmOp1Level: 0.9)` → verify `pmOp1Level == 0.9`
- Call `copyWith(pmAlgoIndex: 3)` → verify `pmAlgoIndex == 3`
- Other fields unchanged

### Test F4: WithParameter
- Create default snapshot
- Call `withParameter("pmOp1Level", 0.9)` → verify `pmOp1Level == 0.9`
- Call `withParameter("pmAlgoIndex", 3)` → verify `pmAlgoIndex == 3`
- Call `withParameter("pmFeedback", 0.5)` → verify `pmFeedback == 0.5`
- Call `withParameter("bogus", 0.5)` → verify all PM fields unchanged

### Test F5: Preset loading
- Create a mock preset map with a few PM parameter values
- Verify that applying the preset (iterating over preset map and calling `withParameter`) produces correct snapshot values

## Manual verification (local developer)

1. Insert Phase Mod Synth from picker → verify card shows "Phase Mod Synth · 4-OP"
2. Switch to ALGO tab, pick algorithm #3 (dual 2→1) → verify instrument sounds different
3. Switch to OP tab, select operator 2, adjust ratio to 5.0, level high → verify classic FM bell-like tone
4. Adjust each operator's ADSR envelope → verify envelope shapes audible change
5. Switch to MOD tab, set LFO rate to medium, shape to sine, amount high, destination to pitch → verify vibrato effect
6. Switch to TONE tab, adjust filter cutoff → verify filter sweep
7. Load factory preset "Classic EP" → verify all params change and instrument sounds like an electric piano
8. Save project → close → reopen → verify all PM synth params restored
9. Play MIDI notes with glide enabled → verify portamento between notes
10. Enable mono mode → verify only one voice at a time
11. Record automation on filterCutoff → play back → verify filter sweep in automation playback