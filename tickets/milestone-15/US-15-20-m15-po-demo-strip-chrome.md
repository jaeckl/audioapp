# US-15-20: M15 PO demo — device strip chrome

## Type

Demo / QA

## Milestone

Milestone 15 — Device strip UX chrome

## User story

As a **PO**, I can **demo device-appropriate strip chrome** in one session: kick bench, drum output rail, dynamics input/output — without explaining missing tabs or wrong Pan knobs.

## Goal

End-to-end demo on Android device proving M15 vertical slices.

## Demo script (~60s)

1. **Kick bench** — insert Kick; show one-page knobs + model row (808); Vel sens + Gain on right; play MIDI clip.
2. **Dynamics** — add Compressor after kick; point out input column + GR on right; adjust threshold.
3. **Contrast** — add Subtractive Synth on another track; show Pan + Gain still present.
4. **Persistence** — save project → reload → layouts and params intact.

## Acceptance criteria

- [ ] All steps completable without developer shortcuts
- [ ] No universal Pan on kick or compressor
- [ ] PO sign-off on [milestone-15.md](../../docs/milestones/milestone-15.md)

## Depends on

US-15-02, US-15-03, US-15-04

## Status

**todo**
