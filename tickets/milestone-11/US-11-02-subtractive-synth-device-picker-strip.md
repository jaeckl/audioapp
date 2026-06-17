# US-11-02: Subtractive synth device — picker, strip, save/load

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I can **add a Subtractive Synth** to a track (alongside the existing oscillator and sampler), tweak **cutoff** and **amp envelope** from a minimal strip, hear it from **MIDI clips** and the **Play** surface, and **save/reload** the project with settings intact.

## Goal

First **on-device wow moment** for M11 — PO plays a chord on pads/keyboard through the new instrument.

## UX flow

1. Select track → device strip → **Add instrument** → **Subtractive Synth** (oscillator and sampler still listed).
2. Minimal strip: cutoff knob, amp attack/release (or single “Amp” sub-panel).
3. Play transport with MIDI clip **or** Play tab pads → audible saw + filter.
4. Save project → reload → same timbre.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Add flow ≤ 3 taps; parameter drag does not block audio; success on save/load via existing shell feedback |

## Scope

- `subtractive_synth` in `ProjectJson.cpp` round-trip
- `EngineBridge` parameter set/get for v1 keys
- Device picker entry + strip card (minimal controls)
- `DeviceContainerTabs`: single body or placeholder until US-11-06
- Default patch: saw, moderate cutoff, short amp attack
- **Coexist** with `simple_oscillator` — both in picker, both in same project

## Out of scope

- Full Osc/Mix/Filter/Amp tab layout (US-11-05/06)
- Presets library (US-11-08)
- LFO

## Acceptance criteria

- [ ] User adds Subtractive Synth without removing other instrument types
- [ ] MIDI clip + live notes trigger 8-voice poly
- [ ] Strip cutoff/amp params change sound on device
- [ ] Save/load round-trip for all v1 parameters
- [ ] Bypass + track gain/pan (shared strip chrome) still work
- [ ] Widget test: picker lists `subtractive_synth`
- [ ] Manual on device (~45s demo)

## Demo script (on-device, ~45s)

1. New track → Add **Subtractive Synth** → open Play → hold 3 pads → chord audible.
2. Lower cutoff → darker tone → save → force-close → reload → same tone.

## Tests required

- [ ] `ProjectJson` serialization test for `subtractive_synth`
- [ ] Flutter widget test (picker + strip mounts)
- [ ] Manual on device

## User-visible result

A real instrument in the chain — not a hidden engine test.

## Depends on

US-11-01

## Companion stories

- [UX/UI](US-11-02-ux-ui.md)
- [Interaction](US-11-02-interaction.md)

## Status

**Todo**
