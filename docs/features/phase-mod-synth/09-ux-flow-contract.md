# UX Flow Contract: Phase Modulation Synth Device

## UX Summary

- **User Goal**: Design and play expressive phase modulation / FM tones by configuring 4 operators, algorithm routing, LFO/modulation, filter, and amp envelope on a dedicated synth device.
- **Main Flow**: Device picker → Add "Phase Mod Synth" → Configure across 4 tabs (ALGO, OP, MOD, TONE) → Play MIDI notes → Hear PM tone.
- **Secondary Flows**:
  - Load one of 16 factory presets.
  - Quick-bypass via header toggle.
  - Save/Load project with full PM synth parameter persistence.
  - Access fullscreen landscape editor.
- **Non-Goals**:
  - No arpeggiator or sequencer.
  - No multi-timbral operation.
  - No graphical envelope editor (knob-based ADSR only).
  - No DX7 SysEx import.
  - No user preset saving UI beyond the 16 factory presets.
  - No MIDI learn or external controller mapping.

## Screen Map

| Screen/Area | Purpose | Entry point | Exit / Next action |
|---|---|---|---|
| Device Picker | List all available devices, including "Phase Mod Synth". | App home → open device picker. | Tapping "Phase Mod Synth" adds a device strip to the chain and closes the picker. |
| PM Synth Device Strip (compact card) | Shows header with enable toggle, device type label "Phase Mod Synth · 4-OP", and compact 4-tab parameter area. | Device added to chain from picker. | Tap card body to expand full panel. Tap header to toggle/bypass. |
| PM Synth Panel (expanded card) | Full 4-tab parameter editor within the chain — ALGO / OP / MOD / TONE. | Tap compact strip body. | Tap anywhere outside or collapse button to return to compact strip. |
| PM Synth Editor Screen (fullscreen) | Fullscreen landscape editor for the device (reuses `DeviceLandscapeShell` pattern). | Tap fullscreen icon on expanded panel. | Close button returns to chain view. |
| Preset Selector | List of 16 factory presets by name. | Menu icon or button on the panel header. | Tapping a preset loads all device parameters instantly. Dismiss to return to current tab. |
| Project Save / Load | Persist snapshot JSON including all 54 PM-specific fields. | UI toolbar → save or load project. | Return to chain view with all PM parameters restored. |

## User Flows

### Add Phase Mod Synth

- **Trigger**: User opens Device Picker and taps "Phase Mod Synth".
- **Steps**:
  1. Device card appears in chain with header showing "Phase Mod Synth · 4-OP".
  2. Header shows enable toggle (on by default), device type label, and orange accent stripe (`Color(0xFFFF6B35)`).
  3. Compact strip shows ALGO tab as default, with small rotary knobs and controls in strip density mode.
  4. User can tap the card body to expand into full panel.
- **Feedback**: Card animates into chain; toggle shows on state; accent stripe visible.
- **Success State**: Device audible with default electric-piano-like patch (algorithm 0, stack routing). Filter fairly open. LFO off.
- **Error State**: If factory default fails, a disabled placeholder card with error icon and tooltip appears.

### Select Algorithm (ALGO tab)

- **Trigger**: User taps the ALGO tab.
- **Steps**:
  1. Algorithm matrix visual (2×4 grid of operator boxes with arrows showing modulation routing) is displayed.
  2. Algorithm dropdown or selector buttons show 8 preset algorithms by name (e.g., "4-op stack", "3→1", "3→2", "2→1×2", "4→1", "1→2 pair", "1→1×2", "All mod").
  3. User selects a different algorithm.
  4. Matrix visual updates instantly to show new routing.
  5. Feedback knob adjusts self-modulation amount for operator 1.
- **Feedback**: Matrix visual redraws with new arrow paths; audio routing changes instantly.
- **Success State**: Algorithm routing changes are audible when playing notes.
- **Error State**: If algorithm index is out of range, clamp to [0, 7]; show no error to user.

### Edit Operator (OP tab)

- **Trigger**: User taps the OP tab.
- **Steps**:
  1. Operator selector buttons 1–4 appear at top; operator 1 is selected by default.
  2. Controls for the selected operator appear below: Ratio, Fine, Level, Waveform, ADSR, Velocity Sense, Key Track.
  3. User taps operator 2 to edit its parameters.
  4. Controls update to show operator 2's values.
  5. User adjusts Ratio dropdown (0.5, 1, 1.5, 2, 3, 4, 5, 6, 8), Fine knob (±50 cents), Level knob, Waveform dropdown (Sine/Tri/Saw/Square/Noise), ADSR knobs (A, D, S, R), Velocity Sense knob, Key Track knob.
- **Feedback**: Knob values update in real-time; operator selection button highlights; envelope changes audible on next note-on.
- **Success State**: Each operator parameter change is reflected in the audio output.
- **Error State**: Invalid ratio mapped to nearest valid discrete value; out-of-range values clamped.

### Configure LFO / Modulation (MOD tab)

- **Trigger**: User taps the MOD tab.
- **Steps**:
  1. LFO section shows Rate knob, Shape dropdown (Sine/Tri/Saw/Square/S&H), Amount knob.
  2. Destination dropdown shows options: Off / Pitch / Filter / Amp / PM Amt.
  3. User selects a non-zero LFO amount and a destination (e.g., Pitch).
  4. Vibrato section shows Rate and Depth knobs.
- **Feedback**: LFO modulation is audible when playing sustained notes; parameter values display in real-time.
- **Success State**: LFO modulates the selected destination parameter. Vibrato adds pitch wobble.
- **Error State**: If LFO amount is zero, no modulation occurs (expected behavior, not an error). No invalid destination can be selected.

### Shape Tone (TONE tab)

- **Trigger**: User taps the TONE tab.
- **Steps**:
  1. Filter section: Cutoff, Resonance, Filter Type dropdown (LPF/HPF/BPF/Notch/etc.), Envelope Amount.
  2. Filter ADSR: A, D, S, R knobs.
  3. Amp ADSR: A, D, S, R knobs.
  4. Global section: Master Volume, Pan.
  5. Performance section: Unison Voices (1–4), Unison Detune, Glide, Mono toggle, Legato toggle.
- **Feedback**: Filter sweep audible when playing; amp envelope shapes note dynamics; unison thickens sound.
- **Success State**: Tone shaping is audible and matches filter/amp settings.
- **Error State**: Invalid filter type clamped to valid range.

### Play PM Sound

- **Trigger**: User plays MIDI notes on a connected keyboard or on-screen pads.
- **Steps**:
  1. PhaseModSynth engine renders audio based on current parameter set (algorithm, operator configs, mod, filter, amp).
  2. Up to 8 voices of polyphony; voice stealing when limit exceeded.
  3. Unison (1–4 voices per note) adds detuned layers.
  4. Portamento/glide if enabled.
  5. Mono/Legato if enabled.
- **Feedback**: Rich PM/FM tone heard immediately.
- **Success State**: Notes play with correct pitch, timbre, envelope, filter.
- **Error State**: Silence if no carrier operator is routed to output (algorithm-dependent — this may be intentional experimental behavior).

### Load Factory Preset

- **Trigger**: User taps preset selector button on panel header.
- **Steps**:
  1. Preset list appears (16 entries with descriptive names like "EPiano", "Bell", "Brass", "Bass", "Pad").
  2. User taps a preset name.
  3. All device parameters update to preset values via `onParameterChanged` callbacks.
  4. Current tab UI updates to reflect new parameter values.
  5. Preset selector dismisses.
- **Feedback**: Parameter values update across all 4 tabs; knob positions change; algorithm visual updates if preset changed algo.
- **Success State**: Device sound matches the factory preset.
- **Error State**: If a preset map contains an unknown parameter ID, it is silently skipped.

### Bypass Device

- **Trigger**: Tap enable toggle in card header.
- **Steps**:
  1. Toggle flips visual state (green accent ↔ grey).
  2. MethodChannel `enableDevice` called.
  3. Audio thread disables processing for this device; signal passes through (or is muted per chain routing).
- **Feedback**: Header background dimmed when disabled; entire strip dimmed.
- **Success State**: Device silent; audio chain continues.
- **Error State**: None (toggle is always safe).

### Save / Load Project

- **Trigger**: User saves or loads project via toolbar.
- **Steps** (save):
  1. All 54 PM-specific parameters serialized via `slotToVar()` with `pm*` JSON field names.
  2. Shared filter/amp fields (`filterCutoff`, `attack`, etc.) serialized as existing.
- **Steps** (load):
  1. JSON deserialized via `varToSlot()`.
  2. `DeviceSnapshot.fromMap` reads all `pm*` fields.
  3. UI updates to reflect restored parameters.
- **Feedback**: PM synth state restored exactly on load.
- **Success State**: Full round-trip fidelity for all parameters.
- **Error State**: Missing JSON fields fall back to default values (graceful degradation).

## Layout Contract

### PM Synth Device Strip (compact) — strip density

| Regions | Grouping | Visual Hierarchy | Primary Action | Secondary Actions | Forbidden Layout Choices |
|---|---|---|---|---|---|
| Header row, Tab bar (ALGO/OP/MOD/TONE), Active tab content strip | Header (accent stripe + toggle + label + subtitle "4-OP") > Tab bar > Strip content | Orange accent stripe > Header row > Tab bar > Active tab controls | Tap card body to expand full panel | Tab tap to switch active tab in strip, Enable toggle | No scrolling within strip; all strip controls must fit without overflow. No nested expandable sections in strip mode. |

### PM Synth Panel (expanded) — 4 tabs

| Region | Grouping | Visual Hierarchy | Primary Action | Secondary Actions | Forbidden Layout Choices |
|---|---|---|---|---|---|
| ALGO tab: algorithm matrix visual, algorithm selector, feedback knob | Section box per row: visual group → selector group → feedback group | Algorithm matrix (most prominent) > Algorithm selector > Feedback | Select algorithm from matrix or dropdown | Adjust feedback knob | No scroll within algorithm visual (ensure it fits). Avoid cluttered matrix — use simple boxes + arrows. |
| OP tab: operator selector (1/2/3/4), selected operator controls | Operator selector row, then Ratio + Fine, Level + Waveform, ADSR row (A, D, S, R), Velocity Sense + Key Track | Operator selector > Ratio/Fine > Level/Waveform > ADSR > VelSense/KeyTrack | Select operator to edit | All knobs and dropdowns per operator | Do not show all 4 operators' controls simultaneously. Never exceed single-column layout within the operator content area. |
| MOD tab: LFO Rate, LFO Shape, LFO Amount, LFO Destination, Vibrato Rate, Vibrato Depth | LFO section box, Vibrato section box | LFO section > Vibrato section | Set LFO destination and amount | Adjust LFO rate/shape, vibrato | Do not group vibrato inside LFO card — they are separate sections. |
| TONE tab: Filter section, Filter ADSR, Amp ADSR, Global section, Performance section | Filter controls row, Filter ADSR row, Amp ADSR row, Master/Pan row, Unison/Glide/Mono/Legato row | Filter (most impactful) > Filter envelope > Amp envelope > Global > Performance | Adjust filter cutoff | All other knobs and toggles | Do not place performance controls (unison, glide) above filter section. Do not split related controls across sections. |

### PM Synth Editor Screen (fullscreen)

| Regions | Grouping | Visual Hierarchy | Primary Action | Secondary Actions | Forbidden Layout Choices |
|---|---|---|---|---|---|
| Fullscreen landscape layout via `DeviceLandscapeShell` | Header bar (close + title + preset) > Tab bar > Tab content (full height) | Tab content fills screen | Configure current tab parameters | Close editor, switch tabs, load preset | No sidebar navigation; tabs must be horizontal bar at top. |

## Component Contract

| UI need | Component / pattern | Data required | Notes |
|---|---|---|---|
| Device picker entry | `ListTile` in `DevicePickerSheet` | `deviceType: "phase_mod_synth"`, label "Phase Mod Synth" | Use `device_strip_theme.dart` for accent color. |
| Device strip (compact) | `DeviceStripCard` with tab bar + strip content | All `pm*` fields + filter/amp fields for strip knobs | Uses `DeviceStripTheme` with `phaseModSynthAccent`. Subtitle "4-OP". |
| Device card header | Re-used header pattern with `enableToggle` | `enabled` flag, device name, subtitle | Orange accent stripe, title "Phase Mod Synth", subtitle "4-OP". |
| Tab bar | Re-used `DeviceTabBar` from `device_container_tabs.dart` | 4 tab labels: "ALGO", "OP", "MOD", "TONE" | Must match existing `DeviceTabBar` pattern. Current tab highlighted in accent color. |
| Algorithm matrix visual | Custom widget `_algorithmVisual()` (new) | `pmAlgoIndex` (0–7) | 2×4 grid of operator boxes with SVG/canvas arrow paths showing routing. Only 8 variants — draw statically per algo index. |
| Algorithm selector | `DropdownButtonHideUnderline` + `DropdownButton` or segmented-button pattern | 8 named algorithm strings, `pmAlgoIndex` selected | Label: "Algorithm". Options: "4-op stack", "3→1", "3→2", "2→1×2", "4→1", "1→2 pair", "1→1×2", "All mod". |
| Parameter Knob | `RotaryKnob` (reused) | `paramId`, `value`, `min`/`max` | All knobs use existing `RotaryKnob` widget. Shows value label on drag. Supports modulation/automation indicators. |
| Ratio dropdown | Re-used `DropdownButton` | `pmOp{1-4}Ratio` (normalized, maps to discrete ratios) | Options: "0.5", "1", "1.5", "2", "3", "4", "5", "6", "8". Label: "Ratio". |
| Waveform dropdown | Re-used `DropdownButton` | `pmOp{1-4}Wave` (normalized, maps to waveforms) | Options: "Sine", "Tri", "Saw", "Square", "Noise". Label: "Wave". |
| ADSR envelope knobs (operator) | Re-used `_adsrRow()` pattern | `pmOp{1-4}Attack`, `Decay`, `Sustain`, `Release` | 4 knobs in row: A, D, S, R. Small knob size. |
| Filter Type dropdown | Re-used `DropdownButton` | `filterMode` | Same options as SubtractiveSynth filter. |
| Filter ADSR knobs | Re-used `_adsrRow()` pattern | `filterAttack`, `filterDecay`, `filterSustain`, `filterRelease` | 4 knobs in row: A, D, S, R. |
| Amp ADSR knobs | Re-used `_adsrRow()` pattern | `attack`, `decay`, `sustain`, `release` | 4 knobs in row: A, D, S, R. |
| LFO Shape dropdown | Re-used `DropdownButton` | `pmLfoShape` (normalized, maps to shapes) | Options: "Sine", "Tri", "Saw", "Square", "S&H". |
| LFO Destination dropdown | Re-used `DropdownButton` | `pmLfoDest` (0–4) | Options: "Off", "Pitch", "Filter", "Amp", "PM Amt". |
| Operator selector | Row of 4 toggle buttons (1/2/3/4) | Selected operator index (0–3) | Highlight selected operator in accent color. Touch target min 48dp. |
| Unison Voices | `DraggableIntValueBox` or knob | `pmUnisonVoices` | Range 1–4. |
| Mono / Legato toggle | Re-used toggle switch | `pmMono`, `pmLegato` | Boolean toggles. Mono must be on for Legato to be active. |
| Preset selector | Button + dropdown/menu overlay | List of 16 preset names and parameter maps | Button label "Presets". Opens overlay list. |
| Fullscreen toggle | Icon button on expanded panel header | — | Opens `PhaseModSynthEditorScreen` via `DeviceLandscapeShell`. |

## State Contract

| Screen / Component | Empty state | Loading state | Ready / Active state | Editing state | Saving state | Error state | Disabled state |
|---|---|---|---|---|---|---|---|
| PM Synth Device Strip (compact) | Placeholder grey box if device failed to instantiate (should not happen on add). | Spinner during initial parameter load across bridge. | Normal accent-colored header with orange stripe, 4 tabs showing compact controls. | Tab tap switches strip content. Knob drag updates value. | No explicit saving UI — handled by project save flow. | Error icon with tooltip if device failed. | Header dimmed, toggle off, controls greyed out when bypassed. |
| ALGO tab | Should never be empty — always shows current algorithm + feedback. | Spinner while algorithm data loads. | Matrix visual shows current algorithm routing. Dropdown shows selected algo. Feedback knob at current value. | Algorithm selection highlights new choice. Matrix redraws. | No explicit saving UI. | Clamped algorithm index if out of range — no error shown. | Matrix and controls greyed out when device bypassed. |
| OP tab | Should never be empty — always shows operator 1 controls as default. | Spinner while operator data loads. | Selected operator controls show current values. Operator selector highlights active op. | Selected operator changes. Knob drag updates value. | No explicit saving UI. | Invalid operator index clamped to [0,3]. Invalid ratio snaps to nearest valid value. | Controls greyed out when device bypassed. |
| MOD tab | Should never be empty — always shows LFO and vibrato controls. | Spinner while mod data loads. | LFO rate/shape/amount/dest + vibrato rate/depth at current values. | Knob drag updates LFO/vibrato. | No explicit saving UI. | Invalid LFO dest clamped to [0,4]. | Controls greyed out when device bypassed. |
| TONE tab | Should never be empty — always shows filter, amp, global controls. | Spinner while tone data loads. | Filter controls, amp ADSR, master vol, pan, unison, glide, mono/legato at current values. | Any knob drag or toggle flip updates value. | No explicit saving UI. | Invalid filter mode clamped to [0,5]. | Controls greyed out when device bypassed. |
| PM Synth Panel (expanded) | Should never load without 4 tabs. | Spinner in loading tab while snapshot loads. | All 4 tabs show current parameter values. Tab bar shows active tab. | Active tab's controls being manipulated. | Spinner overlay on panel while snapshot being persisted (rare — project save only). | Red border + toast on panel if snapshot load fails. | Greyed out when device bypassed. |
| PM Synth Editor Screen (fullscreen) | Should never load without content. | Spinner while editor loads in `DeviceLandscapeShell`. | Fullscreen landscape with active tab's controls. | Same as panel editing states. | No explicit saving UI. | Red border + toast if editor fails. | Greyed out when device bypassed. |
| Preset Selector | Should never be empty (16 factory presets always available). | Spinner while preset list populates (local constant — near-instant). | List of 16 preset names. Tapping loads preset. | Tapping a preset highlights it, then loads parameters. | Brief loading overlay while all `onParameterChanged` calls propagate. | If a preset contains an unknown param ID, skip silently. Show toast if no presets load. | Disabled when device bypassed. |

## Responsive Behavior

- **Compact (phone portrait)**: Card width fills available space. Each tab uses single-column layout. Knobs use small size (`RotaryKnob` small variant). ADSR rows use 4 small knobs side-by-side. Algorithm matrix scales to fit width. All content within each tab fits without scrolling (tabs are designed to be short).
- **Normal (phone landscape / small tablet)**: Tabs can show more horizontal space. Algorithm matrix uses full available width. OP tab shows operator selector and two columns: left column Ratio/Fine, right column Level/Waveform. Filter, amp, and global controls distributed across 2-column grid where possible.
- **Wide (tablet / large tablet landscape)**: TONE tab uses 3-column layout: filter | filter envelope | amp envelope + global. OP tab shows 2+ columns for selected operator controls. MOD tab side-by-side LFO and Vibrato sections.
- **Fullscreen editor (landscape)**: Uses `DeviceLandscapeShell` — tab content fills entire screen with larger knobs and wider spacing. Tab bar remains at top.
- **Overflow**: If tab content exceeds available height (unlikely given sparse layout per tab), the tab content area becomes vertically scrollable. All knobs remain within scroll. Non-scrollable: algorithm matrix, operator selector bar, tab bar.

## Accessibility Expectations

- All interactive elements have semantic labels (`Semantics` widget) matching canonical vocabulary (e.g., "pmOp1Ratio — Operator 1 frequency ratio", "pmAlgoIndex — Algorithm selector", "pmLfoRate — LFO rate").
- Focus order follows tab bar order: ALGO → OP → MOD → TONE, then within each tab by visual reading order (top to bottom, left to right).
- Keyboard shortcuts: Arrow keys adjust focused knob value; Tab navigates between controls; Shift+Tab reverse navigates; Enter or Space activates dropdowns and toggles.
- Contrast: Use `DeviceStripTheme` with `phaseModSynthAccent` (`Color(0xFFFF6B35)`) — ensure WCAG AA contrast ratio against backgrounds. Orange on dark backgrounds requires sufficient brightness contrast — use sparingly for accent only, not for body text.
- Screen reader: Announces current value and unit on knob focus ("Ratio: 2.0"). Announces dropdown selection. Announces operator selector state ("Operator 2 selected"). Announces toggle states ("Mono: on", "Legato: off").
- Touch targets: Minimum 48dp hit area for all interactive elements enforced by `RotaryKnob` and toggle widgets.

## UX Risks

| Risk | Potential Impact | Mitigation |
|---|---|---|
| Overcrowded TONE tab (filter + amp + global + performance on one tab) | User cannot find controls; feels overwhelming | Group into clearly labeled section boxes. Filter section first (most used), then filter env, amp env, global, performance last. |
| Algorithm matrix too complex on small screen | User cannot distinguish routing arrows at small size | Keep operator boxes simple (just number), use 2×4 grid, arrows as simple directional lines. On very small screens, fall back to algorithm name + simplified diagram. |
| 4 tabs feel overwhelming for new users | User does not know where to start | ALGO tab is default — simplest entry point. OP tab has clear operator selector. Tooltip or hint text on first use (optional). |
| OP tab: switching operator hides previous operator's controls | User forgets what they set on op 2 after switching to op 3 | Show a brief summary indicator per operator (e.g., small level meter or ratio readout on the selector buttons). Clearly label each operator button with its number. |
| Inconsistent control naming with existing synths (SubtractiveSynth, BassSynth) | User confusion when switching devices | Reuse existing shared field names exactly (`filterCutoff`, `attack`, `decay`, etc.). Add `pm` prefix only for PM-specific fields. Follow existing `DeviceState` field conventions. |
| Missing empty/error states on factory preset load | Silent failure if preset data is malformed | Skip unknown param IDs silently. Show toast if no parameters could be loaded from a preset. |
| LFO applied per-voice (not truly global) | Each voice starts LFO at different phase — modulation may sound inconsistent across note-ons | Document this limitation for MVP. Note as future enhancement in implementation notes. |
| Touch target too small for operator selector buttons (1/2/3/4) | Miss-taps on small knobs | Ensure minimum 48dp hit area for each operator button. Use larger touch targets than visible area if needed. |
| User cannot tell which operators are carriers vs modulators in algorithm visual | Confusion about why some operators affect output while others don't | Visually distinguish carriers (filled box, brighter) from modulators (outlined box, dimmer) in the algorithm matrix. Add small "OUT" label next to carrier operators. |

## Implementation Notes

- **Binding**: UI must call `setParameter` MethodChannel with exact parameter IDs from `02-canonical-vocabulary.md` (e.g. `'pmOp1Ratio'`, `'pmAlgoIndex'`, `'pmLfoRate'`, `'filterCutoff'`, `'attack'`). Parameter IDs must match exactly — case-sensitive.
- **Algorithm selection**: UI may use either `setParameter('pmAlgoIndex', floatValue)` with normalized index (0.0–1.0 mapped to 0–7) or `setStringParameter('pmAlgo', 'stack_4')` with named algorithms. Prefer string-based selection for readability in code and dropdown labels.
- **Operator selector**: The selected operator index (0–3) is UI-local state only — the engine stores per-operator parameter values individually (`pmOp1*`, `pmOp2*`, etc.). The UI must read/write the appropriate `pmOp{N}*` field based on which operator is selected.
- **Data contracts**: Follow `PhaseModSynthParams` struct field names exactly. Ratio uses discrete mapping (0.5, 1, 1.5, 2, 3, 4, 5, 6, 8) — UI must snap to nearest value. Waveform uses 5 discrete values (Sine, Tri, Saw, Square, Noise) — UI must map normalized [0,1] to these indices.
- **Binding of UI to snapshot**: Use existing `DeviceSnapshot` pattern — read `pm*` fields from snapshot on init, write via `copyWith(pmOp1Ratio: newValue)` and send to bridge. Subscribe to snapshot updates for real-time parameter changes.
- **Shared field reuse**: Do not prefix existing shared fields (`filterCutoff`, `attack`, `decay`, etc.) with `pm` — they are reused from `DeviceState` and their existing param IDs are unchanged.
- **Design bindings**: All colours, fonts, and spacing must use `DeviceStripTheme` and the new `phaseModSynthAccent` (`Color(0xFFFF6B35)`) from `device_strip_theme.dart`. Panel variant: use `PanelVariant.screen` for tab content, `PanelVariant.elevated` for section boxes.
- **Strip density mode**: The compact strip shows all 4 tabs with smaller knobs (follow `DeviceStripDensity.strip` pattern — same as SubtractiveSynth/BassSynth). Strip design width: `phaseModSynthDesignWidth = 520`.
- **Preset loading**: Call `onParameterChanged(paramId, value)` for each entry in the preset map. Preset maps contain only the values that differ from defaults. Order does not matter — each call updates one parameter.
- **Mono/Legato dependency**: When `pmMono` is off (0), `pmLegato` must be forced off (0) regardless of its stored value. The UI should disable the Legato toggle when Mono is off.
- **Known MVP limitation**: LFO runs per-voice, not truly globally. Each voice starts LFO at phase 0 on note-on. This is acceptable for MVP but documented as a future enhancement.
- **Future adjustments**: If new parameters are added (e.g., additional LFO, FX send per operator), extend the relevant tab(s) while keeping existing layout hierarchy and tab structure.