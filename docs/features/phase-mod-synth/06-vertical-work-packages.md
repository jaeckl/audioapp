# Vertical Work Packages: Phase Modulation Synth Device

## Package WP-1: DSP core engine (PhaseModSynth)

**User-visibility**: The PM synth engine can render audio from a `PhaseModSynthParams` struct. This is not user-facing alone — it enables playback in WP-4.

**Assigned files**:
- `engine_juce/include/audioapp/PhaseModSynth.hpp` (create)
- `engine_juce/src/PhaseModSynth.cpp` (create)

**What to implement**:
- `PhaseModSynthParams` struct (all operator, filter, amp, LFO, global fields)
- `PhaseModSynthVoiceRuntime` struct (per-voice state: phase accumulators, envelope state, filter state, LFO phase)
- `PhaseModSynthRuntime` struct (voice pool of 8 voices + steal index)
- `phaseModVoiceSample()` — renders one sample for one voice, handles:
  - Per-operator phase accumulation + modulation from source operators per algorithm
  - Feedback on operator 1
  - Waveform shape (sine/tri/saw/square via `subtractiveMorphWaveSample()` or inline implementation)
  - Per-operator ADSR envelope (attack/decay/sustain/release with linear segments)
  - Algorithm routing (8 algorithms, simple switch statement)
  - Output summing for carriers
  - Filter biquad via `SamplerFilter`/`SamplerFilterKernel`
  - Amp envelope
  - Pan, gain, master volume
  - Unison (1-4 voices with detune)
  - LFO (rate, shape, destination)
  - Portamento/glide
  - Velocity sensitivity
- `mixPhaseModMidiNotesBlock()` — block renderer taking MIDI notes + automation + LFO
- `renderPhaseModLiveVoice()` — live play renderer
- Unity build helper `MixedPhaseModBlock()` for the live mixer

**Canonical names used**: `PhaseModSynthParams`, `PhaseModSynthVoiceRuntime`, `PhaseModSynthRuntime`, `phaseModVoiceSample`, `mixPhaseModMidiNotesBlock`, `renderPhaseModLiveVoice`

**API/data contracts used**: PhaseModSynthParams from §4, algorithm table from §1 (architecture), all operator/envelope/LFO fields

**Dependencies**: `SamplerFilter.hpp` (existing biquad), `AutomationTypes.hpp` (modulation/automation arrays)

**Acceptance criteria**:
1. `phaseModVoiceSample()` produces non-zero output when called with valid params
2. Phase modulation actually works: a modulator at ratio N creates sidebands at carrier ± N
3. The 8 algorithm routings produce audibly different output
4. ADSR envelopes reach correct levels (attack reaches peak, sustain holds, release fades)
5. Filter biquad shapes output correctly
6. Memory is zero-initialized (no NaN on first sample)
7. Unison produces multiple detuned voices
8. LFO modulates the selected destination

**Parallel-safe**: YES — only depends on existing headers (SamplerFilter, AutomationTypes)

---

## Package WP-2: Engine device registration + instance + serialization (C++)

**User-visibility**: Device can be created from C++ test via `DeviceRegistry::createDefault("phase_mod_synth")`. JSON serialization round-trips. Playback builds a `DeviceNodePlayback` with `DeviceNodeKind::PhaseModSynth`.

**Assigned files**:
- `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp` (modify — add `kPhaseModSynth`)
- `engine_juce/include/audioapp/devices/PhaseModSynthDeviceType.hpp` (create)
- `engine_juce/include/audioapp/devices/instances/PhaseModSynthInstance.hpp` (create)
- `engine_juce/src/devices/PhaseModSynthDeviceType.cpp` (create)
- `engine_juce/include/audioapp/devices/DeviceSlot.hpp` (modify — add include + variant entry)
- `engine_juce/src/devices/DeviceRegistry.cpp` (modify — add include + register + variant check)
- `engine_juce/include/audioapp/DeviceChain.hpp` (modify — add `DeviceNodeKind::PhaseModSynth` + `PhaseModSynthParams` to `DeviceVariantParams`)
- `engine_juce/include/audioapp/LivePerformance.hpp` (modify — add `LiveInstrumentKind::PhaseModSynth` + `phaseMod` field to `LiveInstrumentSnapshot`)

**Canonical names used**: `kPhaseModSynth`, `PhaseModSynthDeviceType`, `PhaseModSynthInstance`, `PhaseModSynthParams`, `DeviceNodeKind::PhaseModSynth`, `LiveInstrumentKind::PhaseModSynth`

**API/data contracts used**: All from §3, PhaseModSynthInstance from §2, PhaseModSynthParams from §4

**Dependencies**: WP-1 (PhaseModSynth.hpp must exist for PhaseModSynthParams struct)

**Acceptance criteria**:
1. `DeviceRegistry::createBuiltIn()` includes `PhaseModSynthDeviceType`
2. `DeviceRegistry::find("phase_mod_synth")` returns non-null
3. `DeviceRegistry::createDefault("phase_mod_synth")` returns a slot with `PhaseModSynthInstance`
4. `slotToVar()` → JSON → `varToSlot()` round-trip preserves all params
5. `setParameter()` handles all PM-specific param IDs + gain/pan/bypass + existing shared filter/amp fields
6. `setStringParameter('pmAlgo', 'stack_4')` sets algoIndex to 0
7. `buildPlaybackNode` returns `DeviceNodeKind::PhaseModSynth` with valid `PhaseModSynthParams`
8. `buildLiveInstrument` returns `LiveInstrumentKind::PhaseModSynth` with valid `phaseMod` field

**Parallel-safe**: YES (after WP-1 creates PhaseModSynth.hpp)

---

## Package WP-3: Automation and modulation dispatch (C++)

**User-visibility**: Automation clips can target PM synth parameters. LFO modulation works on PM params.

**Assigned files**:
- `engine_juce/include/audioapp/AutomationTypes.hpp` (modify — add `ParamKind::PhaseModSynth`, `PhaseModSynthParam` enum)
- `engine_juce/src/AutomationPlayback.cpp` (modify — add PhaseModSynth cases in all dispatch tables)

**Canonical names used**: `ParamKind::PhaseModSynth`, `PhaseModSynthParam`, `DeviceNodeKind::PhaseModSynth`

**Dependencies**: WP-1 (PhaseModSynthParams struct for param offsets), WP-2 (DeviceNodeKind::PhaseModSynth)

**Acceptance criteria**:
1. `paramKindFromDeviceNodeKind(DeviceNodeKind::PhaseModSynth)` returns `ParamKind::PhaseModSynth`
2. `paramIdFromString("pmOp1Level", DeviceNodeKind::PhaseModSynth)` returns valid packed ID
3. `paramIdToString` reverse-maps correctly for all PhaseModSynthParam values
4. `applyAutomationValue` modifies `PhaseModSynthParams` for each `PhaseModSynthParam`
5. `paramDescriptorsForKind(DeviceNodeKind::PhaseModSynth)` returns param descriptors

**Parallel-safe**: NO — sequential after WP-2

---

## Package WP-4: Device chain and live performance dispatch (C++)

**User-visibility**: A PhaseModSynth device in a track chain produces audio during playback and live performance.

**Assigned files**:
- `engine_juce/src/DeviceChain.cpp` (modify — add case for `DeviceNodeKind::PhaseModSynth` in `processDeviceChain`, `isInstrumentDeviceNodeKind`, `nodeHasDspAutomation`)
- `engine_juce/src/LivePerformance.cpp` (modify — add `LiveInstrumentKind::PhaseModSynth` handling)

**Implementation notes**:
- `DeviceChain.cpp`: The `PhaseModSynth` case dispatches to `mixPhaseModMidiNotesBlock()` with `std::get<PhaseModSynthParams>(modulatedParams)`
- Add `PhaseModSynth` to `isInstrumentDeviceNodeKind()` helper
- `LivePerformance.cpp`: Set `phaseMod` runtime fields, call `renderPhaseModLiveVoice`

**Canonical names used**: `DeviceNodeKind::PhaseModSynth`, `LiveInstrumentKind::PhaseModSynth`

**Dependencies**: WP-1 (DSP engine functions), WP-2 (DeviceNodeKind enum), WP-3 (automation dispatch)

**Acceptance criteria**:
1. `processDeviceChain` with `DeviceNodeKind::PhaseModSynth` renders audio using `mixPhaseModMidiNotesBlock`
2. `LivePerformanceMixer::noteOn` with `LiveInstrumentKind::PhaseModSynth` creates PM voice
3. `isInstrumentDeviceNodeKind(DeviceNodeKind::PhaseModSynth)` returns true
4. `nodeHasDspAutomation` works with PhaseModSynth

**Parallel-safe**: NO — sequential after WP-3

---

## Package WP-5: Flutter UI (picker → strip → panel → fullscreen editor + presets)

**User-visibility**: Full end-to-end UI flow.

**Assigned files**:
- `app_flutter/lib/features/device_strip/phase_mod_synth_device_panel.dart` (create)
- `app_flutter/lib/features/device_strip/phase_mod_synth_device_strip.dart` (create)
- `app_flutter/lib/features/device_strip/phase_mod_synth_editor_screen.dart` (create)
- `app_flutter/lib/features/device_strip/phase_mod_synth_presets.dart` (create)
- `app_flutter/lib/features/device_strip/device_picker_sheet.dart` (modify)
- `app_flutter/lib/features/device_strip/device_strip_slot.dart` (modify)
- `app_flutter/lib/features/device_strip/device_strip_theme.dart` (modify)
- `app_flutter/lib/features/device_strip/device_strip_metrics.dart` (modify)
- `app_flutter/lib/features/device_strip/device_container_tabs.dart` (modify)
- `app_flutter/lib/bridge/project_snapshot.dart` (modify)

**Panel layout (4 tabs)**:

**Tab 1 — ALGO (Algorithm)**:
| Row | Widgets |
|-----|---------|
| 1 | Algorithm matrix visual (2×4 grid of operator boxes + arrows showing routing) — custom widget `_algorithmVisual()` |
| 2 | Algorithm dropdown/selector — 8 preset algorithms as named buttons or dropdown |
| 3 | Feedback knob + label |

**Tab 2 — OP (Operator editor)**:
| Row | Widgets |
|-----|---------|
| 1 | Operator selector buttons (1/2/3/4) — highlights selected op |
| 2 | Frequency: Ratio dropdown (0.5, 1, 1.5, 2, 3, 4, 5, 6, 8) + Fine knob (cents detune) |
| 3 | Level knob + Waveform dropdown (Sine/Tri/Saw/Square/Noise) |
| 4 | ADSR envelope: A, D, S, R knobs (reuse `_adsrRow()` from SubtractiveSynth pattern) |
| 5 | Velocity Sense knob + Key Track knob |

**Tab 3 — MOD (Modulation & LFO)**:
| Row | Widgets |
|-----|---------|
| 1 | Global LFO: Rate knob, Shape dropdown (Sine/Tri/Saw/Square/S&H), Amount knob |
| 2 | LFO Destination dropdown (Off/Pitch/Filter/Amp/PM Amt) |
| 3 | Vibrato: Rate knob, Depth knob |

**Tab 4 — TONE (Filter & Global)**:
| Row | Widgets |
|-----|---------|
| 1 | Filter section: Cutoff, Resonance, Filter Type dropdown, Envelope Amount |
| 2 | Filter envelope: A, D, S, R knobs (reuse `_adsrRow()`) |
| 3 | Amp envelope: A, D, S, R knobs |
| 4 | Master Volume, Pan, Unison Voices, Unison Spread |
| 5 | Glide, Mono Toggle, Legato Toggle |

**Strip density** (compact card): Show all 4 tabs with smaller knobs (same pattern as SubtractiveSynth/BassSynth strips). Same `BassPanelDensity.strip` / `Density.strip` pattern — smaller `RotaryKnob` widgets but all tabs remain accessible.

**Visual identity**:
- Accent color: `Color(0xFFFF6B35)` — vibrant orange (distinct from SubtractiveSynth's purple and BassSynth's green)
- Section labels: "ALGO", "OP", "MOD", "TONE" with styled text
- Panel variant: `PanelVariant.screen` for tab content, `PanelVariant.elevated` for section groups
- Header title: "Phase Mod Synth"
- Card subtitle: "4-OP"
- Design width: `phaseModSynthDesignWidth = 520` (same as SubtractiveSynth — 4 tabs need space)

**Preset selection**:
- 16 factory presets in `phase_mod_synth_presets.dart` as a `List<Map<String, dynamic>>`
- Each preset is a map of parameter_id → value (only the values that differ from defaults)
- Presets are loaded via the `onParameterChanged` callback — no special bridge call needed
- Presets stored as Dart constants with descriptive names: `_ep1`, `_bell1`, `_brass1`, etc.
- Loaded by iterating over the preset map and calling `onParameterChanged(id, value)` for each entry

**Acceptance criteria**:
1. Device picker shows "Phase Mod Synth" with PM icon
2. Tapping adds a PhaseModSynth device with correct default params
3. Strip shows compact ALGO tab with algorithm selector + feedback + master volume
4. Full panel shows all 4 tabs with all controls
5. Knob adjustments reach engine via `onParameterChanged`
6. Algorithm visual updates when algoIndex changes
7. Operator tab updates when selecting different operator
8. Preset loading sets all device parameters correctly
9. Snapshot fields serialize/deserialize correctly via bridge
10. Automation, modulation, bypass, gain, pan all work

**Parallel-safe**: YES (can run in parallel with WP-1/WP-2 — Flutter works with mock engine)

---

## Package WP-6: Tests

**User-visibility**: Verified by CI.

**Assigned files**:
- `engine_juce/tests/phase_mod_synth_test.cpp` (create)
- `app_flutter/test/phase_mod_synth_snapshot_test.dart` (create)

**Dependencies**: WP-1, WP-2, WP-5 (contract stubs exist)

**Acceptance criteria**:
1. All tests pass

**Parallel-safe**: YES (can be designed from contract documents before implementation)

---

## Integration-only package WP-INT: Build + manual verification

**User-visibility**: Final integration.

**Assigned files**: All above

**Dependencies**: All packages

**Tasks**:
1. Build engine: `cmake --build build/engine --target audioapp_engine`
2. Build Flutter APK: `cd app_flutter && flutter build apk --debug`
3. Manual verification on device (local developer only)
4. Fix any integration errors

**Parallel-safe**: NO — last step