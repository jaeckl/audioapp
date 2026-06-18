# US-08-20: M08 PO demo — filter sweep + automation on cutoff

## Type

Demo / acceptance

## Milestone

Milestone 08 — Effects & automation

## User story

As a **product owner**, I can demo **parameter automation** once on device: MIDI loop + filter cutoff sweep driven by an automation clip.

## Demo script (~90s)

1. New project → add track → add **Subtractive Synth**.
2. Add MIDI clip with held note (4 bars).
3. Library → Automation → **Filter cutoff** (or long-press Filter knob → Automate this).
4. Double-tap automation clip → lower cutoff at bar 2 → Save.
5. Play from start → hear brightness change mid-clip.
6. Duplicate clip → Link chip → re-assign to same filter → Play (reuse workflow).

## Acceptance criteria

- [x] End-to-end path exists in app (no engine-only gap)
- [x] Link Mode + curve editor + playback implemented
- [ ] PO signs off on physical device

## Depends on

US-08-04, US-08-18, US-08-19

## Status

**In progress** (awaiting on-device PO sign-off)
