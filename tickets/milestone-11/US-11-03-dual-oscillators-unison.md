# US-11-03: Dual oscillators + unison

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I can run **two detunable oscillators** with **unison** (stacked detuned copies per osc) so pads and leads sound wide and animated without exceeding the **8-voice** poly budget.

## Goal

Richer timbre — second oscillator and unison are clearly audible on device.

## Architecture notes

- **8-voice poly** = 8 note slots, not 8×unison copies eating the pool (unison duplicates are **per-voice internal**, mixed before filter)
- Shared osc params: waveform, octave, semitone, fine detune apply per osc bank
- Unison: voice count (e.g. 1–4) + detune spread — document CPU cost; cap so RT stays safe

## Parameter keys (additions)

| Key | Notes |
|-----|--------|
| `osc2_wave`, `osc2_octave`, `osc2_semi`, `osc2_detune` | Mirror osc1 |
| `osc2_level` | 0–1 |
| `unison_voices` | 1–4 per oscillator group |
| `unison_detune` | cents spread |

## Scope

- DSP: osc2 + unison mix into voice pre-filter bus
- Serialization + bridge for new keys
- Strip: expose osc2 level + unison (minimal until US-11-05)

## Out of scope

- Mix modes (US-11-04)
- Waveform preview painters (US-11-05)
- LFO

## Acceptance criteria

- [ ] Osc2 audible when level > 0
- [ ] Unison widens spectrum vs single osc (measurable or A/B on device)
- [ ] Still max 8 note voices; no runaway CPU with max unison
- [ ] Save/load round-trip
- [ ] C++ test: dual osc output ≠ single osc output at same pitch

## Demo script (on-device, ~30s)

1. Enable osc2, detune +5 semi → play fifth interval.
2. Raise unison → play held chord → width obvious.

## Tests required

- [ ] C++ offline comparison test
- [ ] Serialization test

## Depends on

US-11-02

## Companion stories

- [UX/UI](US-11-03-ux-ui.md)
- [Interaction](US-11-03-interaction.md)

## Status

**Todo**
