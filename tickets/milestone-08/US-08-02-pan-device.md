# US-08-02: Pan device

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **user**, I can add a **Pan** effect and move the sound left/right in the stereo field.

## Goal

Second effect increment — stereo placement audible on headphones.

## UX flow

1. Add **Pan** after instrument (or after Gain if present).
2. Pan knob/slider centered = mono; left/right = audible shift.
3. Play → position changes with parameter.
4. Save/load preserves pan.

## Scope

- `pan` device DSP (constant-power pan law documented)
- Strip UI control
- Golden test: hard left vs hard right channel energy

## Out of scope

- Automation (US-08-04)

## Acceptance criteria

- [ ] Pan device addable from strip
- [ ] Hard pan measurable in L/R channels (offline test)
- [ ] Audible on headphones on device
- [ ] Serialization round-trip

## Demo script (on-device, ~30s)

1. Play loop centered → pan hard left → hear left bias → pan hard right.

## Tests required

- [ ] C++ golden pan test
- [ ] Manual on device

## Depends on

US-08-01


## Companion stories

- [UX/UI](US-08-02-ux-ui.md)
- [Interaction](US-08-02-interaction.md)

## Status

**Todo**
