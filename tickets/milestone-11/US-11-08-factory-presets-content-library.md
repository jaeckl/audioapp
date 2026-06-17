# US-11-08: Factory presets + content library

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I browse **subtractive synth presets** in the **content library** fly-in and load one onto the selected synth so I can start from usable bass, pad, and lead sounds.

## Goal

Preset round-trip proves serialization of the full parameter set — investor-ready variety in one demo.

## UX flow

1. Select subtractive synth → library tool rail → **Presets** category (or Devices → Synth presets).
2. Tap preset → parameters apply → audible change.
3. Save project → preset choice / parameter values reload correctly.

## Scope

- Bundled JSON presets under assets (or catalog module mirroring sample library)
- `library_catalog.dart` entries for subtractive presets
- Apply preset = batch `setDeviceParameter` on control thread
- At least **6 factory presets** (bass, pad, pluck, lead, noise sweep, init)

## Out of scope

- User save preset to disk (defer SAF export story)
- LFO-heavy presets (no LFO in engine)

## Acceptance criteria

- [ ] Library lists synth presets when subtractive synth selected
- [ ] Load preset updates all tabs’ visible values
- [ ] Save/load project preserves loaded patch
- [ ] Cancel/error if no synth selected (clear snackbar)
- [ ] C++ test: one preset JSON parses into engine snapshot

## Demo script (on-device, ~45s)

1. Init patch → library → **Warm Pad** → hold test note → save → reload → still pad.

## Depends on

US-11-07, content library fly-in (shipped)

## Companion stories

- [UX/UI](US-11-08-ux-ui.md)
- [Interaction](US-11-08-interaction.md)

## Status

**Todo**
