# US-15-03: Mono drum output panels

## Type

Feature

## Milestone

Milestone 15 — Device strip UX chrome

## User story

As a **producer**, I see **Gain and Velocity sensitivity** (not Pan) on mono drum generators — matching Bitwig-style drum strips — while stereo instruments keep Pan + Gain.

## Goal

Implement **`DrumMonoOutputPanel`** and wire all four M13 drum types.

## UX flow

1. Expand kick / snare / clap / cymbal slot.
2. Right column: **Vel sens** (top or bottom per layout sketch) + **Gain**.
3. No Pan knob; subtitle still `Mono · synth`.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Compact knobs (44–56px); automation/mod/LFO on Gain and `*Velocity` params |

## Scope

- `DrumMonoOutputPanel` widget — Gain (`gain`), Velocity sens (`kickVelocity` / `snareVelocity` / `clapVelocity` / `cymbalVelocity` per type)
- `DeviceOutputPanels` maps all four generator type IDs → `DrumMonoOutputPanel`
- Param id switch inside panel based on `device.type`
- Engine: optional peak normalization comment/ticket note in `KickGenerator.cpp` (adjust `kInstrumentOutputGain` or internal scale if needed)
- Remove Velocity from old drum **Amp** tabs when those tabs still exist (snare/clap/cymbal until bench migration)
- Widget test: kick slot does not find Pan; finds Vel sens label
- Update [kick_generator_ux_addendum.md](../../docs/design/drum_generators/kick_generator_ux_addendum.md) if labels change

## Out of scope

- Kick bench card body (US-15-02)
- Converting snare/clap/cymbal to single-page bench
- Hiding `pan` in engine (UI-only)

## Acceptance criteria

- [ ] All four drum types use `DrumMonoOutputPanel`
- [ ] Pan not shown for mono drums
- [ ] Gain + velocity sens change audible level / dynamics on Play pads
- [ ] Save/load round-trip for `gain` and `*Velocity`
- [ ] Modulation/automation hooks work on output panel knobs

## Demo script (on-device, ~25s)

1. Kick: Gain to 50% → quieter; Vel sens 0% → pads same level; 100% → velocity affects hit.
2. Snare: same rail layout.
3. Save/reload.

## Depends on

US-15-01


## Companion stories

- [UX/UI](US-15-03-ux-ui.md)
- [Interaction](US-15-03-interaction.md)

## Status

**todo**
