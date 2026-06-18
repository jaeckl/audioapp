# US-08-04: Parameter automation clips

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **producer**, I can place **automation clips** on a track timeline, link them to device parameters, edit breakpoint curves, and hear those values applied during playback.

## Goal

Clip-based parameter automation (not collapsible sub-lanes): arrangement clips with Link Mode assignment, curve editor, and engine playback — investor-demo ready with filter cutoff sweep.

## UX flow

1. Library → Automation → template (or long-press knob → **Automate this**).
2. Automation clip appears in lower half of track lane (purple curve preview).
3. Tap **Link** chip → device knobs pulse purple → tap target knob to assign.
4. Double-tap clip → fullscreen curve editor → Save.
5. Play → parameter follows envelope during clip range.

## Scope

- Engine: `AutomationClip` model, CRUD, JSON, block-rate playback in `processDeviceChain`
- Bridge: `createAutomationClip`, `assignAutomationTarget`, `setAutomationPoints`
- Flutter: arrangement renderer, Link Mode, curve editor, library templates
- Knob long-press **Automate this** on all instrument knobs (sampler, synth, oscillator, gain/pan)

## Out of scope

- Real-time automation **recording** while dragging (US-08-18 follow-up)
- Collapsible automation sub-lanes
- Master-track-only lanes

## Acceptance criteria

- [x] Create automation clip on track from library or knob gesture
- [x] Link Mode assigns `(deviceId, paramId)` via floating chip + knob tap
- [x] Curve editor read/write breakpoints
- [x] Playback applies automation during clip span (C++ test + offline render)
- [x] Save/load round-trip automation clips
- [ ] Manual on-device PO demo (US-08-20)

## Demo script (on-device, ~60s)

1. Track + subtractive synth + MIDI note clip.
2. Long-press **Filter** knob → automation clip created at playhead.
3. Double-tap clip → add sweep point → Save.
4. Play → audible filter movement.

## Tests required

- [x] `engine_juce/tests/automation_clip_test.cpp`
- [x] Flutter bridge unit tests for automation commands
- [ ] Manual on device

## Depends on

US-08-02 (device chain), US-04-11 (timeline clips)

## Companion stories

- [UX/UI](US-08-04-ux-ui.md)
- [Interaction](US-08-04-interaction.md)

## Status

**Done** (recording while performing deferred to US-08-18)
