# UX Flow Contract: Time‑Based Effects Suite

## UX Summary
- **User Goal**: Add, configure, and automate high‑quality time‑based effects (Delay, Reverb, Chorus, Phaser) on any track.
- **Main Flow**: Device picker → Add Effect → Expand Effect card → Adjust parameters → Enable/disable → Automate → Save/Load project.
- **Secondary Flows**:
  - Copy/paste effect chain.
  - Quick‑bypass via header toggle.
  - Global preset import/export (future feature).
- **Non‑Goals**: Multi‑channel processing, built‑in preset library, external VST/AU hosting.

## Screen Map
| Screen/Area | Purpose | Entry point | Exit / Next action |
|------------|---------|--------------|--------------------|
| Device Picker | List all available devices, including the four effects. | App home → open device picker. | Selecting an effect adds a card to the chain.
| Effect Device Strip (compact card) | Shows header with enable toggle and device type label. | Effect added to chain. | Tap header to expand or toggle.
| Effect Panel (expanded) | Parameter UI for a specific effect. | Tap card body. | Adjust knobs/sliders → changes reflected in audio.
| Automation / Modulation Overlay | Show modulated/automated state, assign LFOs. | Long‑press a knob. | Save automation or dismiss.
| Project Save/Load | Persist snapshot JSON. | UI toolbar → save or load. | Return to chain view.

## User Flows
### Add Effect
- **Trigger**: User opens Device Picker and taps *Delay* (or other effect).
- **Steps**:
  1. Device card appears in chain with header only.
  2. Header shows effect name, enable toggle (on by default), and a small expand icon.
  3. User taps card body to expand the panel.
  4. Panel loads with effect‑specific controls.
- **Feedback**: Card animates into place, toggle changes colour, panel slides down.
- **Success State**: Effect audible, UI reflects parameter values.
- **Error State**: If factory fails, a disabled placeholder card with error icon and tooltip appears.

### Adjust Parameters
- **Trigger**: User manipulates a knob, dropdown, or toggle within an expanded panel.
- **Steps**:
  1. Parameter change sent via MethodChannel `setEffectParameter`.
  2. UI shows live value label update.
  3. Audio thread reads snapshot atomically; audible change occurs instantly.
- **Feedback**: Real‑time value label, optional modulation highlight.
- **Success**: Audio changes match UI.
- **Error**: Invalid range is clamped; log entry appears, UI shows subtle warning colour.

### Automate / Modulate
- **Trigger**: Long‑press a knob.
- **Steps**:
  1. Overlay appears with *Automation* and *Modulation* buttons.
  2. Tap *Automation* opens the automation editor for that parameter.
  3. Tap *Modulation* opens LFO assignment dialog.
- **Feedback**: Overlay fades in, selected state highlighted.
- **Success**: Automation curve or LFO attached; knob shows modulation/automation active icons.
- **Error**: If LFO slot unavailable, toast informs user.

### Enable / Bypass Effect
- **Trigger**: Tap enable toggle in card header.
- **Steps**:
  1. Toggle flips visual state (green ↔ grey).
  2. MethodChannel `enableEffect` called.
  3. Audio thread disables processing for that device.
- **Feedback**: Header background dimmed when disabled.
- **Success**: Effect silent while other chain remains.
- **Error**: None (toggle is always safe).

## Layout Contract
| Screen/Area | Regions | Grouping | Visual Hierarchy | Primary Action | Secondary Actions | Forbidden Layout Choices |
|------------|---------|----------|------------------|----------------|-------------------|--------------------------|
| Effect Panel | Header, Parameter Grid, Envelope (Reverb & Chorus), Modulation Row | Parameters grouped by function (Time, Mix, Tone) | Header > Parameter Grid > Envelope > Modulation | Adjust primary knob (e.g., *Time* for Delay) | Dropdown for mode selection, toggle for bypass, link icon for automation | No scrollbars inside panel; avoid nested cards.
| Effect Card (compact) | Accent stripe, Header, Expand icon | Single column – header only | Accent stripe > Header > Expand icon | Tap to expand | Long‑press for context menu | No overlapping controls.

## Component Contract
| UI need | Component / pattern | Data required | Notes |
|--------|---------------------|----------------|-------|
| Effect Header | `DeviceStripCard` with `headerOnly:true` | `deviceType`, `enabled` flag | Uses `DeviceStripTheme` for colours.
| Parameter Knob | `RotaryKnob` (custom) | `paramId`, `value`, `min/max` (implicit) | Shows modulation/automation icons.
| Dropdown for Mode | `DropdownButtonHideUnderline` + `DropdownButton` | `options list`, `selected index` | Used for filter type in Chorus/Phaser, mix mode.
| Envelope Editor | Re‑used `ADSRS` row from synth panel | `attack, decay, sustain, release` | Same visual style, custom prefix per effect.
| Modulation Indicator | Small overlay badge on knob | `isModulated` boolean | Colour coded (blue) per design system.
| Automation Indicator | Link icon on knob | `isAutomated` boolean | Shows tooltip on hover.

## State Contract
| Screen / Component | Empty state | Loading state | Ready / Active state | Editing state | Saving state | Error state | Disabled state |
|--------------------|------------|---------------|----------------------|---------------|--------------|------------|----------------|
| Effect Panel | No parameters displayed (should never happen) | Spinner while snapshot loads | All knobs show current values | Knob being dragged – highlight | Show spinner on top of panel while snapshot is being persisted | Red border + toast message | Greyed out when effect disabled.
| Effect Card (compact) | Placeholder grey box (if device failed to instantiate) | Fade‑in animation | Normal coloured header with accent stripe | Tap expands – panel slides down | No explicit saving UI – handled by project save flow. | Show error icon with tooltip. | Header dimmed, toggle off.

## Responsive Behavior
- **Compact (phone portrait)**: Card width fills available space; panel uses single‑column grid, knobs sized to fit.
- **Normal (tablet)**: Two‑column grid for parameters where applicable (Delay: Time | Feedback | Mix; Reverb: Room Size | Damping | Mix).
- **Wide (desktop / large tablet)**: Three‑column layout for advanced effects (Chorus, Phaser) adding *Depth* and *Rate* columns.
- **Overflow**: If screen too small, panel becomes vertically scrollable; knobs remain visible.

## Accessibility Expectations
- All interactive elements have semantic labels (`Semantics` widget) matching canonical vocabulary (e.g., "Delay time", "Reverb room size").
- Focus order follows visual order: Header → Primary knob → Secondary knobs → Dropdowns → Buttons.
- Keyboard shortcuts: Arrow keys adjust focused knob; Enter toggles enable.
- Contrast: Use `DeviceStripTheme` colours; meet WCAG AA for text and interactive elements.
- Screen reader: Announces current value and modulation/automation status.

## UX Risks
| Risk | Potential Impact | Mitigation |
|------|------------------|-----------|
| Overcrowded panel on small screens | Users cannot reach all knobs | Collapse secondary groups into accordion sections.
| Inconsistent naming across effects | Confusion when switching between Delay and Reverb | Enforce canonical names from `Canonical Vocabulary` (e.g., *Time* vs *Room Size*).
| Missing empty / error states | Crash or silent failure | Show disabled placeholder with explanatory tooltip.
| Touch target too small | Miss taps on knobs | Minimum 48 dp hit area enforced by `RotaryKnob`.

## Implementation Notes
- **Binding**: UI must call `engine/effect` MethodChannel with `setEffectParameter`, `enableEffect`, `disableEffect`.
- **Data contracts**: Follow `EffectParams` structs defined in `02-canonical-vocabulary.md` – field names must match exactly (`delayTime`, `reverbMix`, etc.).
- **Binding of UI to snapshot**: Use `EffectPanel` widgets that read snapshot via `getEffectSnapshot` on init and subscribe to updates.
- **Binding constraints**: Do not modify the JSON schema; only add UI‑level defaults if missing.
- **Design bindings**: All colours, fonts, and spacing must use `DeviceStripTheme` and `LibraryTheme` to stay consistent with other device panels.
- **Future adjustments**: If new parameters are added, extend the grid but keep existing layout hierarchy.
