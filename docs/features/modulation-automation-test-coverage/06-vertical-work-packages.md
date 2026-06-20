# Vertical Work Packages

## Package classification

| Package | Test ID | File | Parallel | Depends on |
| ------- | ------- | ---- | -------- | ---------- |
| WP-01 | US-16-01 | `stacked_lfo_modulation_test.cpp` | YES (parallel-safe) | None |
| WP-02 | US-16-02 | `effect_device_modulation_test.cpp` | YES (parallel-safe) | None |
| WP-03 | US-16-03 | `common_param_modulation_test.cpp` | YES (parallel-safe) | None |
| WP-04 | US-16-04 | `percussion_modulation_test.cpp` | YES (parallel-safe) | None |
| WP-05 | US-16-05 | `adsr_modulator_test.cpp` | YES (parallel-safe) | None |
| WP-06 | US-16-06 | `lfo_polarity_test.cpp` | YES (parallel-safe) | None |
| WP-07 | US-16-07 | `lfo_sync_bpm_test.cpp` | YES (parallel-safe) | None |
| WP-08 | US-16-08 | `gain_pan_mod_auto_test.cpp` | YES (parallel-safe) | None |
| WP-09 | US-16-09 | `effect_device_automation_test.cpp` | YES (parallel-safe) | None |
| WP-10 | US-16-10 | `lfo_bridge_test.dart` | YES (parallel-safe) | None |
| WP-11 | US-16-11 | `modulation_widget_test.dart` | YES (parallel-safe) | None |
| WP-12 | US-16-12 | `lfo_snapshot_parsing_test.dart` | YES (parallel-safe) | None |
| WP-13 | US-16-13 | `modulation_persistence_test.dart` | YES (parallel-safe) | None |

**All 13 packages are parallel-safe** — no two packages edit the same file.
C++ tests are in `engine_juce/tests/`, Flutter tests are in `app_flutter/test/`.
No shared helper files, no race on CMakeLists.txt changes (no changes needed).

---

## WP-01: Stacked LFO Modulation (US-16-01)

**File:** `engine_juce/tests/stacked_lfo_modulation_test.cpp`

**Behavior:** Two LFOs simultaneously modulating different parameters on the same
SubtractiveSynth device produce complex spectral variation beyond single-LFO case.

**Canonical names used:** `EngineHost`, `createLfo`, `updateLfoParam`, `assignModulation`,
`renderOffline`, `highFrequencyEnergy`, `rms`

**Acceptance criteria:**
1. Create SubtractiveSynth with sustained MIDI note
2. Create LFO-1 (sine, 3 Hz) modulating `filterCutoff` at 0.8 amount
3. Create LFO-2 (square, 7 Hz) modulating `filterQ` at 0.5 amount
4. Render 4 beats at 48 kHz
5. RMS > threshold (audio produced)
6. HF energy variation across 8 windows > 2x ratio (stronger sweep than single LFO)
7. Optionally compare against a single-LFO render to prove stacked modulation is additive

**Required tests (in one file):**
- Test 1: Two LFOs on different params produce audible stacked modulation
- Test 2: Two LFOs on the SAME param (both filterCutoff) — verify additive amounts
- Test 3: Remove one LFO, render again — verify spectral variation decreases

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-02: Effect Device Modulation (US-16-02)

**File:** `engine_juce/tests/effect_device_modulation_test.cpp`

**Behavior:** LFO modulating parameters on Compressor (threshold), Gate (threshold, range),
Expander (threshold), and Limiter (ceiling) produce audible changes in dynamics processing.

**Canonical names used:** `EngineHost`, `createLfo`, `assignModulation`, `addDeviceToTrack`,
`renderOffline`, `highFrequencyEnergy`, `rms`, `setDeviceParameter`

**Device parameters to modulate:**
- Compressor: "compThreshold" — modulating between 0.0–1.0 changes compression amount
- Gate: "gateThreshold" — modulating opens and closes gate
- Expander: "expandThreshold" — modulating changes expansion
- Limiter: "limitCeiling" — modulating changes ceiling

**Acceptance criteria:**
1. Create oscillator device (produces steady signal)
2. Add Compressor after oscillator, modulate `compThreshold` with LFO at 4 Hz
3. Render 4 beats, verify audible variation in output (HF energy change or amplitude change)
4. Test other devices with the same oscillator-as-source pattern

**Required tests (in one file):**
- Test 1: LFO → Compressor threshold → audible gain reduction variation
- Test 2: LFO → Gate threshold → periodic opening/closing (amplitude modulation)
- Test 3: LFO → Gate range → partial gating
- Test 4: LFO → Expander threshold → amplitude variation
- Test 5: LFO → Limiter ceiling → peak limiting variation

**Note on test approach:** Since effect devices process their input (they don't generate
sound), the pattern is: Oscillator → Effect → render. The LFO modulates the effect
parameter, which changes how the effect processes the oscillator signal. Use RMS
variation or peak variation as the detection metric (not HF energy).

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-03: Common Parameter Modulation (US-16-03)

**File:** `engine_juce/tests/common_param_modulation_test.cpp`

**Behavior:** LFO modulating "gain" and "pan" on a SubtractiveSynth or Oscillator produces
audible amplitude/pan variation.

**Canonical names used:** `EngineHost`, `addDeviceToTrack`, `createLfo`, `assignModulation`,
`renderOffline`, `rms`, `peak`

**Acceptance criteria:**
1. Create SubtractiveSynth with sustained MIDI note
2. Create LFO (triangle, 4 Hz) modulating `gain` at 0.8 amount
3. Render 4 beats — output amplitude should vary with LFO frequency
4. RMS in high-LFO windows should differ from low-LFO windows
5. For pan: render stereo, verify left/right RMS imbalance varying per window

**Required tests (in one file):**
- Test 1: LFO → gain → amplitude modulation (RMS variation across windows)
- Test 2: LFO → pan → stereo imbalance variation (left/right RMS difference varies)
- Test 3: Two LFOs → gain + pan simultaneously

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-04: Percussion Generator Modulation (US-16-04)

**File:** `engine_juce/tests/percussion_modulation_test.cpp`

**Behavior:** LFO modulating parameters on KickGenerator, SnareGenerator, ClapGenerator,
CrashGenerator, and CymbalGenerator changes the timbre of percussion sounds.

**Canonical names used:** `EngineHost`, `addDeviceToTrack`, `createMidiClip`, `createLfo`,
`assignModulation`, `renderOffline`, `rms`, `peak`

**Percussion param IDs available for modulation:**
- Kick: `kickPitch`, `kickPunch`, `kickDecay`, `kickClick`, `kickTone`
- Snare: `snareBody`, `snareRing`, `snareTune`, `snareSnares`, `snareSnap`, `snareDecay`
- Clap: `clapBursts`, `clapSpread`, `clapTone`, `clapRoom`, `clapDecay`
- Crash: `crashColor`, `crashSpread`, `crashDecay`
- Cymbal: `cymbalColor`, `cymbalDecay`, `cymbalWidth`

**Acceptance criteria:**
1. Create Kick on track + MIDI note on each beat
2. Create LFO modulating kickPitch at 1.0 amount
3. Render 4 beats — RMS should differ from unmodulated render
4. Same pattern for Snare/Clap/Crash/Cymbal

**Required tests (in one file):**
- Test 1: LFO → Kick pitch → audible pitch change (compare RMS pattern vs unmodulated)
- Test 2: LFO → Snare body → timbre change (detect via RMS variation)
- Test 3: LFO → Clap tone → timbre change
- Test 4: LFO → Crash spread → timbre change
- Test 5: LFO → Cymbal width → timbre change

**Note on detection:** Percussion sounds are transient-heavy, so use `peak()` and
`rms()` over full render rather than `highFrequencyEnergy()`. Compare modulated
vs unmodulated RMS values — they should differ measurably.

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-05: ADSR Envelope Modulator (US-16-05)

**File:** `engine_juce/tests/adsr_modulator_test.cpp`

**Behavior:** ADSR envelope modulator (modulatorType=1) affecting filter cutoff produces
a characteristic envelope-shaped timbre change distinct from LFO modulation.

**Canonical names used:** `EngineHost`, `createLfo` (with modulatorType=1), `updateLfoParam`,
`assignModulation`, `renderOffline`, `highFrequencyEnergy`, `rms`

**Acceptance criteria:**
1. Create SubtractiveSynth with sustained MIDI note
2. Create ADSR modulator (`createLfo(1)` — modulatorType = 1 = ADSR)
3. Set ADSR parameters: attack=0.01, decay=0.15, sustain=0.3, release=0.2
4. Assign modulation to `filterCutoff` at 0.8 amount with retrigger=OnNote
5. Render 4 beats
6. HF energy should peak at note onset (attack phase) then decay to sustain level

**Required tests (in one file):**
- Test 1: ADSR envelope on filterCutoff produces characteristic attack→decay→sustain shape
  (early windows have higher HF energy than mid windows)
- Test 2: ADR (modulatorType=2, no sustain) produces different decay shape than ADSR
  (HF energy decays faster)
- Test 3: ADSR with zero attack produces immediate peak

**Detection approach:** Compare HF energy in early windows (attack phase) vs mid windows
(sustain phase). The attack peak should be measurably higher.

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-06: LFO Polarity Test (US-16-06)

**File:** `engine_juce/tests/lfo_polarity_test.cpp`

**Behavior:** LFO polarity setting (bipolar=0, positive=1, negative=2) constrains the
modulation signal to different ranges, producing different audio outcomes.

**Canonical names used:** `EngineHost`, `createLfo`, `updateLfoParam` (polarity),
`assignModulation`, `renderOffline`, `highFrequencyEnergy`, `rms`

**Acceptance criteria:**
1. Create SubtractiveSynth + sustained MIDI note
2. Bipolar LFO (polarity=0) on filterCutoff — filter sweeps both open and closed
3. Positive-only LFO (polarity=1) — filter only opens (or stays same) from baseline
4. Negative-only LFO (polarity=2) — filter only closes from baseline
5. The three polarity modes produce measurably different spectral content

**Required tests (in one file):**
- Test 1: Bipolar LFO on filterCutoff produces full sweep (high HF variation)
- Test 2: Positive-only LFO produces asymmetric sweep (different HF pattern)
- Test 3: Negative-only LFO produces opposite asymmetric sweep
- Test 4: Verify polarity is persisted in JSON round-trip (`modulatorApplyPolarity` test)

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-07: LFO Sync-to-BPM (US-16-07)

**File:** `engine_juce/tests/lfo_sync_bpm_test.cpp`

**Behavior:** LFO with syncDivision ≠ 0 synchronizes to project BPM, producing
different modulation rates than free-running Hz mode.

**Canonical names used:** `EngineHost`, `createLfo`, `updateLfoParam` (syncDivision, rate),
`assignModulation`, `setBpm`, `renderOffline`, `highFrequencyEnergy`, `rms`

**Acceptance criteria:**
1. Create SubtractiveSynth with sustained MIDI note at 120 BPM
2. LFO in sync mode (retrigger=1, syncDivision=3 for 1/4 notes) modulating filterCutoff
3. Render 4 beats at 120 BPM — expect exactly 4 LFO cycles (one per quarter note)
4. HF energy should show 4 peaks across 4 quarter-note windows
5. Changing BPM to 60 should halve the modulation rate

**Required tests (in one file):**
- Test 1: Sync 1/4 LFO at 120 BPM produces 4 cycles in 4 beats
- Test 2: Sync 1/2 LFO produces 2 cycles in 4 beats
- Test 3: Compare sync vs free LFO — different cycle counts in same duration
- Test 4: BPM change affects sync LFO rate but not free LFO rate

**Detection approach:** For sync tests, compare peak-to-peak HF energy distances.
Use a higher temporal resolution (16 windows) and count zero-crossings of the
derivative of HF energy to estimate cycle count.

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-08: Combined Modulation + Automation on Gain/Pan (US-16-08)

**File:** `engine_juce/tests/gain_pan_mod_auto_test.cpp`

**Behavior:** When both modulation AND automation are applied to the same common parameter
(gain or pan), the two modulations combine additively without conflict.

**Canonical names used:** `EngineHost`, `createAutomationClip`, `assignAutomationTarget`,
`setAutomationPoints`, `createLfo`, `assignModulation`, `renderOffline`, `rms`, `peak`

**Acceptance criteria:**
1. Create SubtractiveSynth with sustained MIDI note
2. Automation clip on "gain": ramp from 0.0 → 1.0 over 4 beats
3. LFO modulating "gain" with triangle waveform, ±0.3 amount
4. Render 4 beats — automation provides overall crescendo, LFO adds ripple
5. RMS envelope should show overall upward trend with periodic dips
6. Verify no double-apply (gain shouldn't clip or silence)

**Required tests (in one file):**
- Test 1: Automation-only on gain produces smooth RMS ramp
- Test 2: Modulation-only on gain produces periodic RMS variation
- Test 3: Combined mod+auto on gain produces ramp + ripple (RMS trend + variation)
- Test 4: Combined mod+auto on pan produces varying stereo imbalance + ramp

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-09: Effect Device Automation (US-16-09)

**File:** `engine_juce/tests/effect_device_automation_test.cpp`

**Behavior:** Automation clips targeting effect device parameters produce dynamic changes
in audio processing.

**Canonical names used:** `EngineHost`, `createAutomationClip`, `assignAutomationTarget`,
`setAutomationPoints`, `addDeviceToTrack`, `renderOffline`, `rms`, `peak`

**Effect parameters to automate:**
- Compressor: "compThreshold" — ramp from 0.0→1.0 changes compression amount
- Gate: "gateThreshold" — ramp from 1.0→0.0 opens gate
- Expander: "expandThreshold" — ramp changes expansion
- Limiter: "limitCeiling" — ramp changes ceiling

**Acceptance criteria:**
1. Create Oscillator → Compressor chain
2. Automation on compressor "compThreshold": 0.0→1.0 ramp
3. Render 4 beats — early audio is less compressed (higher RMS), later more compressed
4. Same pattern for Gate, Expander, Limiter

**Required tests (in one file):**
- Test 1: Automation on Compressor threshold → audible compression change
  (compare early RMS vs late RMS)
- Test 2: Automation on Gate threshold → gate opens over time
  (early silent/quiet, late loud)
- Test 3: Automation on Expander threshold → expansion change
- Test 4: Automation on Limiter ceiling → limiting change (peak varies)

**Manual verification:** Compile with `g++ ...` and run; `echo $?` should be 0.

---

## WP-10: Flutter LFO Bridge CRUD (US-16-10)

**File:** `app_flutter/test/lfo_bridge_test.dart`

**Behavior:** Engine bridge methods `createLfo`, `removeLfo`, `updateLfoParam`,
`assignModulation`, `removeModulation` all dispatch correctly and return proper snapshots.

**Canonical names used:** `EngineBridge`, `ProjectSnapshot`, `LfoSnapshot`,
`ModulationEdgeSnapshot`, `MethodChannel`

**Mock handler requirements:**
- `createLfo`: returns snapshot with new LFO in `lfos[]`
- `removeLfo`: returns snapshot without the removed LFO
- `updateLfoParam`: returns snapshot with updated LFO state
- `assignModulation`: returns snapshot with new edge in `modEdges[]`
- `removeModulation`: returns snapshot with edge removed

**Acceptance criteria:**
1. `createLfo` returns snapshot containing LFO with specified modulatorType
2. `removeLfo` returns snapshot with LFO removed from `lfos`
3. `updateLfoParam` returns snapshot with LFO param updated
4. `assignModulation` returns snapshot with new modulation edge
5. `removeModulation` returns snapshot with edge removed

**Required tests (in one file):**
- Test 1: `createLfo` adds LFO to snapshot
- Test 2: `removeLfo` removes LFO from snapshot
- Test 3: `updateLfoParam` updates rate/waveform on snapshot
- Test 4: `assignModulation` adds edge, snapshot contains it
- Test 5: `removeModulation` removes edge, snapshot no longer contains it
- Test 6: `createLfo` with different modulatorType values (0, 1, 2)

**Manual verification:** `cd app_flutter && flutter test test/lfo_bridge_test.dart`

---

## WP-11: Flutter Modulation Widget Tests (US-16-11)

**File:** `app_flutter/test/modulation_widget_test.dart`

**Behavior:** ModulationGrid, ModulationStrip, LfoPropertiesPanel, and
ModulatableSpinnerShell widgets render correctly with given props.

**Canonical names used:** `ModulationGrid`, `ModulationStrip`, `LfoPropertiesPanel`,
`ModulatableSpinnerShell`, `LfoSnapshot`, `ModulationEdgeSnapshot`

**Acceptance criteria:**
1. `ModulationGrid` renders LFO tiles for each LFO in list
2. `ModulationGrid` shows "add" tile when slots available
3. `ModulationStrip` renders LFO cards with waveform/rate controls
4. `ModulationStrip` "Add Modulator" button visible when under max
5. `LfoPropertiesPanel` displays all LFO properties (waveform, rate, sync, phase, polarity)
6. `LfoPropertiesPanel` shows modulation targets with amounts
7. `ModulatableSpinnerShell` renders with modulation bar when active
8. `ModulatableSpinnerShell` responds to connect mode changes

**Required tests (in one file):**
- Test 1: ModulationGrid renders correct number of tiles
- Test 2: ModulationGrid add tile is present when lfos < max
- Test 3: ModulationStrip displays LFO cards
- Test 4: ModulationStrip shows "Add Modulator" button
- Test 5: LfoPropertiesPanel shows waveform dropdown and rate slider
- Test 6: LfoPropertiesPanel shows target edges
- Test 7: ModulatableSpinnerShell shows modulation bar when active
- Test 8: ModulatableSpinnerShell shows connect-mode pulse

**Manual verification:** `cd app_flutter && flutter test test/modulation_widget_test.dart`

---

## WP-12: Flutter Snapshot JSON Parsing (US-16-12)

**File:** `app_flutter/test/lfo_snapshot_parsing_test.dart`

**Behavior:** `LfoSnapshot.fromMap()` and `ModulationEdgeSnapshot.fromMap()`
correctly parse all fields from the JSON map structure emitted by the engine.

**Canonical names used:** `LfoSnapshot.fromMap()`, `ModulationEdgeSnapshot.fromMap()`

**Acceptance criteria:**
1. `LfoSnapshot.fromMap()` parses all 13 fields correctly
2. `LfoSnapshot.fromMap()` handles missing fields with defaults
3. `ModulationEdgeSnapshot.fromMap()` parses all 4 fields correctly
4. `ModulationEdgeSnapshot.fromMap()` handles missing fields with defaults
5. `ProjectSnapshot.fromMap()` correctly parses `lfos` and `modEdges` arrays
6. Edge cases: null values, negative amounts, zero IDs

**Required tests (in one file):**
- Test 1: LfoSnapshot.fromMap full field parsing
- Test 2: LfoSnapshot.fromMap missing field defaults
- Test 3: ModulationEdgeSnapshot.fromMap full field parsing
- Test 4: ModulationEdgeSnapshot.fromMap missing field defaults
- Test 5: ProjectSnapshot.fromMap with lfos + modEdges
- Test 6: Edge cases (null fields, negative amounts, zero IDs)

**Manual verification:** `cd app_flutter && flutter test test/lfo_snapshot_parsing_test.dart`

---

## WP-13: Flutter Modulation Persistence (US-16-13)

**File:** `app_flutter/test/modulation_persistence_test.dart`

**Behavior:** Save/load project with modulation data preserves LFOs and modulation edges
through the bridge.

**Canonical names used:** `EngineBridge`, `saveProject`, `loadProject`, `createLfo`,
`assignModulation`, `getProjectSnapshot`

**Acceptance criteria:**
1. Create project with LFO and modulation edge via bridge
2. Save project returns URI
3. Load project returns snapshot with LFO and modulation edge data
4. The loaded LFO has the same parameters as the saved one
5. The loaded modulation edge targets the same device/param/amount

**Required tests (in one file):**
- Test 1: Create LFO + assign modulation → save → load → verify LFO restored
- Test 2: Create LFO + assign modulation → save → load → verify modEdge restored
- Test 3: Multiple LFOs + edges survive save/load
- Test 4: Removing LFO before save means it's absent after load
- Test 5: Removing modulation edge before save means it's absent after load

**Manual verification:** `cd app_flutter && flutter test test/modulation_persistence_test.dart`