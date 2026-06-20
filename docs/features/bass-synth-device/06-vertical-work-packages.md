# Vertical Work Packages: Bass Synth Device

## Package WP-1: Engine registration + instance + playback (cPP registry end-to-end)

**User-visibility**: Device can be created from C++ test via `DeviceRegistry::createDefault("bass_synth")`. JSON serialization round-trips. Playback builds a `DeviceNodePlayback` with `DeviceNodeKind::BassSynth`.

**Assigned files**:
- `engine_juce/include/audioapp/devices/DeviceTypeIds.hpp` (modify — add `kBasSynth`)
- `engine_juce/include/audioapp/devices/BassSynthDeviceType.hpp` (create)
- `engine_juce/include/audioapp/devices/instances/BassSynthInstance.hpp` (create)
- `engine_juce/src/devices/BassSynthDeviceType.cpp` (create)
- `engine_juce/include/audioapp/devices/DeviceSlot.hpp` (modify — add include + variant entry)
- `engine_juce/src/devices/DeviceRegistry.cpp` (modify — add include + register + variant check)
- `engine_juce/include/audioapp/DeviceChain.hpp` (modify — add `DeviceNodeKind::BassSynth`)
- `engine_juce/include/audioapp/LivePerformance.hpp` (modify — add `LiveInstrumentKind::BassSynth`)

**Canonical names used**: `kBasSynth`, `BassSynthDeviceType`, `BassSynthInstance`, `DeviceNodeKind::BassSynth`, `LiveInstrumentKind::BassSynth`

**API contracts used**: All from §3

**Dependencies**: None

**Acceptance criteria**:
1. `DeviceRegistry::createBuiltIn()` includes `BassSynthDeviceType`
2. `DeviceRegistry::find("bass_synth")` returns non-null
3. `DeviceRegistry::createDefault("bass_synth")` returns a slot with `BassSynthInstance`
4. `toSnapshotState` → `slotFromSnapshot` round-trip preserves all 16 params
5. `setParameter` handles all 16 bass param IDs + gain/pan/bypass
6. `buildPlaybackNode` returns `DeviceNodeKind::BassSynth` with valid `SubtractiveSynthParams`
7. `buildLiveInstrument` returns `LiveInstrumentKind::BassSynth` with valid `subtractive` field
8. `modulatableParams` returns at least the 16 bass params + gain/pan

**Required tests**: WP-6

**Parallel-safe**: YES — depends only on existing `SubtractiveSynth` headers (no other new work package)

---

## Package WP-2: DeviceState fields (C++ DTO)

**User-visibility**: JSON snapshot of BassSynth device includes bass-specific fields.

**Assigned files**:
- `engine_juce/include/audioapp/DeviceState.hpp` (modify — add 9 bass fields)

**Canonical names used**: `bassOscShape`, `bassSubMix`, `bassSubOctave`, `bassNoise`, `bassFilterResonance`, `bassDrive`, `bassSquash`, `bassOctave`, `bassVelocitySense`

**Dependencies**: WP-1 (must know field names and types)

**Acceptance criteria**:
1. All 9 bass fields present in `DeviceState` with correct types and defaults
2. Fields that overlap with existing `DeviceState` fields must not conflict

**Parallel-safe**: YES (after WP-1 contract stubs exist) — can run after WP-1 creates `DeviceState` stub

---

## Package WP-3: Automation and modulation dispatch (c++ playback routing)

**User-visibility**: Automation clips can target bass synth parameters. LFO modulation works on bass params.

**Assigned files**:
- `engine_juce/include/audioapp/AutomationTypes.hpp` (modify — add `ParamKind::BassSynth`, `BassSynthParam` enum)
- `engine_juce/src/AutomationPlayback.cpp` (modify — add BassSynth cases in all dispatch tables)

**Canonical names used**: `ParamKind::BassSynth`, `BassSynthParam`, `DeviceNodeKind::BassSynth`

**Dependencies**: WP-1 (must compile `DeviceNodeKind::BassSynth`) + WP-2 (DeviceState field names)

**Acceptance criteria**:
1. `paramKindFromDeviceNodeKind(DeviceNodeKind::BassSynth)` returns `ParamKind::BassSynth`
2. `paramIdFromString("bassOscShape", DeviceNodeKind::BassSynth)` returns valid packed ID
3. `paramIdToString` reverse-maps correctly
4. `applyAutomationValue` modifies `SubtractiveSynthParams` for each `BassSynthParam`
5. `paramDescriptorsForKind(DeviceNodeKind::BassSynth)` returns param descriptors

**Parallel-safe**: NO — sequential after WP-1

---

## Package WP-4: Device chain and live performance dispatch (c++ audio chain routing)

**User-visibility**: A BassSynth device in a track chain produces audio during playback and live performance.

**Assigned files**:
- `engine_juce/src/DeviceChain.cpp` (modify — add `case DeviceNodeKind::BassSynth:` in `processDeviceChain`)
- `engine_juce/src/LivePerformance.cpp` (modify — add `LiveInstrumentKind::BassSynth` handling)

**Implementation notes**:
- `DeviceChain.cpp`: The `BassSynth` case is IDENTICAL to `SubtractiveSynth` case — it uses `std::get<SubtractiveSynthParams>(modulatedParams)` and calls `mixSubtractiveMidiNotesBlock`. The only difference is `DeviceNodeKind::BassSynth` as the case label (but it shares the `continue`/`isInstrument` routing).
- Add `BassSynth` to `isInstrumentDeviceNodeKind()` helper.
- `LivePerformance.cpp`: Same as `SubtractiveSynth` — set `subtractive` runtime fields, call `renderSubtractiveLiveVoice`.

**Canonical names used**: `DeviceNodeKind::BassSynth`, `LiveInstrumentKind::BassSynth`

**Dependencies**: WP-1, WP-3

**Acceptance criteria**:
1. `processDeviceChain` with `DeviceNodeKind::BassSynth` renders audio using `mixSubtractiveMidiNotesBlock`
2. `LivePerformanceMixer::noteOn` with `LiveInstrumentKind::BassSynth` creates subtractive voice
3. `isInstrumentDeviceNodeKind(DeviceNodeKind::BassSynth)` returns true
4. `nodeHasDspAutomation` works with BassSynth
5. Automation clips that target BassSynth params are applied correctly

**Parallel-safe**: NO — sequential after WP-3

---

## Package WP-5: Flutter UI (picker → strip → panel → full editor)

**User-visibility**: Full end-to-end UI flow.

**Assigned files**:
- `app_flutter/lib/features/device_strip/bass_synth_device_panel.dart` (create)
- `app_flutter/lib/features/device_strip/bass_synth_device_strip.dart` (create)
- `app_flutter/lib/features/device_strip/device_picker_sheet.dart` (modify)
- `app_flutter/lib/features/device_strip/device_strip_slot.dart` (modify)
- `app_flutter/lib/features/device_strip/device_strip_theme.dart` (modify)
- `app_flutter/lib/features/device_strip/device_strip_metrics.dart` (modify)
- `app_flutter/lib/features/device_strip/device_container_tabs.dart` (modify)
- `app_flutter/lib/bridge/project_snapshot.dart` (modify)

**Panel layout (3 tabs)**:

**Tab 1 — TONE** (compact strip default):
| Row | Knobs |
|-----|-------|
| 1 | `bassOscShape` (morph), `bassSubMix`, `bassSubOctave` (int box) |
| 2 | `bassOctave` (int box), `bassNoise` |
| 3 | `attack`, `sustain`, `release` (ADSR-style, ADR with no decay — labeled A / S / R) |

**Tab 2 — FILTER**:
| Row | Knobs |
|-----|-------|
| 1 | `filterCutoff`, `bassFilterResonance` |
| 2 | `filterEnvAmount`, `filterDecay` |
| Envelope | Visual filter envelope preview (reuse `SubtractiveFilterPreview`-style) |

**Tab 3 — CHAR**:
| Row | Knobs |
|-----|-------|
| 1 | `bassDrive`, `bassSquash`, `glideMs` |
| 2 | `bassVelocitySense` |

**Strip density** (compact): Show TONE tab only with `bassOscShape`, `bassSubMix`, `filterCutoff`, `bassFilterResonance`, `bassDrive`.

**Visual identity**:
- Accent color: `Color(0xFF4ADE80)` — neon green, distinct from SubtractiveSynth's purple
- Section labels: "TONE", "FILTER", "CHAR" with styled text
- Panel variant: `PanelVariant.screen` for tab content, `PanelVariant.elevated` for section groups
- Header title: "Bass Synth"
- Card subtitle: "Mono · Sub"

**Design width**: `bassSynthDesignWidth = 420` (slightly narrower than SubtractiveSynth's 500)

**Acceptance criteria**:
1. Device picker shows "Bass Synth" with bass icon
2. Tapping adds a BassSynth device with correct default params
3. Strip shows compact TONE tab with 5 knobs
4. Full panel shows all 3 tabs with all 16 knobs/controls
5. Knob adjustments reach engine via `onParameterChanged`
6. Snapshot fields serialize/deserialize correctly via bridge
7. Automation, modulation, bypass, gain, pan all work

**Parallel-safe**: YES (can run in parallel with WP-1 — Flutter test skeleton works with mock engine)

---

## Package WP-6: Tests

**User-visibility**: Verified by CI.

**Assigned files**:
- `engine_juce/tests/bass_synth_test.cpp` (create)
- `app_flutter/test/bass_synth_snapshot_test.dart` (create)

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