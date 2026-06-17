# US-11-07: Fullscreen subtractive synth editor + test note

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I open a **fullscreen subtractive synth editor** with the same tabs as the strip, plus a **hold-to-test** note so I can sound-design without the Play tab or transport.

## Goal

Parity with sampler fullscreen (US-07-01 / US-07-10) for the flagship instrument.

## UX flow

1. Device strip → expand/fullscreen affordance on subtractive synth.
2. Fullscreen shows Osc | Mix | Filter | Amp + level panel.
3. **Test note** button (or key) sends live `noteOn` while held; releases on up.
4. Back returns to arrangement with state preserved.

## Scope

- Route: fullscreen device chain or dedicated `SubtractiveSynthEditorScreen`
- Shared panel widgets with strip (no duplicate param logic)
- Live note uses existing `noteOn`/`noteOff` bridge (US-10-02)
- Default test pitch: C4 (document in interaction ticket)

## Out of scope

- Preset browser in fullscreen (US-11-08 uses library fly-in)
- LFO

## Acceptance criteria

- [ ] Fullscreen opens from strip in ≤ 2 taps
- [ ] Test note audible while transport stopped
- [ ] Parameter edits in fullscreen reflect on strip and vice versa
- [ ] Back navigation does not reset patch
- [ ] Manual on device both orientations

## Demo script (on-device, ~40s)

1. Open fullscreen → Filter tab → sweep cutoff while holding test note → back → strip shows same cutoff.

## Depends on

US-11-06

## Companion stories

- [UX/UI](US-11-07-ux-ui.md)
- [Interaction](US-11-07-interaction.md)

## Status

**Todo**
