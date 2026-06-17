# US-11-09: Glide + velocity sensitivity (no LFO)

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I can add **portamento/glide** between legato notes and **velocity** affects amp level so performances from the Play keyboard feel expressive.

## Goal

Performance polish to close M11 — explicitly **without** adding an LFO or mod matrix.

## Parameter keys

| Key | Notes |
|-----|--------|
| `glide_ms` | 0–2000 ms, 0 = off |
| `velocity_sensitivity` | 0–1, scales amp env peak from MIDI velocity |

## Scope

- Per-voice glide: target pitch ramps on legato noteOn when previous voice same channel
- Velocity scales amp envelope sustain/peak (document curve)
- Strip: Amp tab or Osc tab — glide + velocity knobs
- **Document in ticket + README: LFO deferred to future milestone**

## Out of scope

- LFO, mod wheel, aftertouch
- Filter key tracking (optional stretch)
- Mono legato mode (poly glide only unless trivial)

## Acceptance criteria

- [ ] Glide audible on overlapping notes from Play keyboard
- [ ] Hard velocity vs soft velocity clearly different level
- [ ] glide_ms = 0 disables portamento
- [ ] Save/load round-trip
- [ ] No alloc on noteOn path

## Demo script (on-device, ~30s)

1. Glide 300 ms → play legato melody on keyboard → pitch slides.
2. Velocity sensitivity max → soft vs hard tap on pad → level difference obvious.

## Depends on

US-11-08

## Companion stories

- [UX/UI](US-11-09-ux-ui.md)
- [Interaction](US-11-09-interaction.md)

## Status

**Todo**
