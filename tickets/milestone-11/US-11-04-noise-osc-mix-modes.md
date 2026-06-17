# US-11-04: Noise generator + oscillator mix modes

## Type

Feature

## Milestone

Milestone 11 — Subtractive synth instrument

## User story

As a **user**, I can blend **osc1**, **osc2**, and **white noise**, and choose how the two oscillators combine (**mix**, **neg**, **am**, **sign**, **max**) for classic subtractive textures.

## Goal

Complete the **signal path before the filter** — noise + mix modes are demo-able in one take.

## Mix modes (osc1 × osc2, per sample)

| Mode | Formula (conceptual) |
|------|----------------------|
| mix | linear blend by osc2 level |
| neg | osc1 − osc2 |
| am | osc1 × osc2 |
| sign | sign(osc1) × osc2 |
| max | max(abs(osc1), abs(osc2)) × sign |

Document exact implementation in engine header comment.

## Parameter keys

| Key | Notes |
|-----|--------|
| `noise_level` | 0–1 |
| `osc_mix_mode` | mix \| neg \| am \| sign \| max |
| `osc1_level` | 0–1 |

## Scope

- White noise generator (RT-safe, e.g. LCG or xorshift — no alloc)
- Mix mode enum in DSP + JSON
- Audible verification per mode at default levels

## Out of scope

- Pink noise
- LFO
- UI tab layout (US-11-05/06)

## Acceptance criteria

- [ ] Noise audible when `noise_level` > 0
- [ ] Each mix mode produces distinct timbre vs `mix` at same pitch
- [ ] No zipper noise when switching modes (crossfade or click-free policy documented)
- [ ] Save/load preserves mode + levels
- [ ] C++ test: at least two modes differ in RMS/hash

## Demo script (on-device, ~40s)

1. Noise only + LP12 sweep → hi-hat-ish texture.
2. Cycle mix → neg → am on held note → obvious character change.

## Tests required

- [ ] C++ golden tests per mix mode (or parameterized)
- [ ] Serialization enum round-trip

## Depends on

US-11-03

## Companion stories

- [UX/UI](US-11-04-ux-ui.md)
- [Interaction](US-11-04-interaction.md)

## Status

**Todo**
