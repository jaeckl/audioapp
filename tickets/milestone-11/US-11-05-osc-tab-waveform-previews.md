# US-11-05: Osc tab + waveform preview painters

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I see an **Osc** tab on the subtractive synth strip with **waveform selectors** and **live waveform previews** for osc1/osc2, matching the Bitwig-style device chrome used by the sampler.

## Goal

Visual polish that sells “real synth” — previews update when wave/octave/detune/unison change.

## UX flow

1. Select subtractive synth on strip → header tab **Osc**.
2. Tap waveform icons (sine, tri, saw, square, pulse) per oscillator.
3. Preview canvas redraws on parameter change (CustomPainter, not engine FFT).

## Scope

- `DeviceContainerTabs` registration: Osc tab
- `SubtractiveSynthOscPanel` (or shared pattern with sampler)
- Static preview curves per wave + pulse width if applicable
- Wire to existing bridge params from US-11-03

## Out of scope

- Mix tab (US-11-06)
- Fullscreen layout (US-11-07)
- LFO

## Acceptance criteria

- [ ] Osc tab appears in device header tabs
- [ ] Wave change updates preview within one frame of param ack
- [ ] Octave/semi/detune/unison controls on Osc tab
- [ ] Portrait + landscape strip layouts per US-07-09 scale rules
- [ ] Widget golden/pump test for Osc panel

## Demo script (on-device, ~30s)

1. Open Osc tab → tap saw → square → previews change.
2. Detune osc2 → preview shows offset phase/frequency cue.

## Depends on

US-11-04

## Companion stories

- [UX/UI](US-11-05-ux-ui.md)
- [Interaction](US-11-05-interaction.md)

## Status

**Todo**
