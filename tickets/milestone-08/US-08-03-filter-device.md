# US-08-03: Filter device

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **user**, I can add a **Filter** (cutoff) after my instrument and shape brightness of the sound.

## Goal

Third effect increment — timbral control with measurable frequency response.

## UX flow

1. Add **Filter** to chain.
2. Cutoff slider sweeps low-pass (or documented mode).
3. Play → brightness changes clearly.
4. Combine with Gain + Pan in chain order documented.

## Scope

- `filter` device with `cutoffHz` parameter
- Stable DSP (biquad or JUCE `juce_dsp` if linked on desktop; mobile-safe impl)
- Golden test: cutoff high vs low spectral difference

## Out of scope

- Resonance Q automation UI complexity (fixed Q OK)
- Automation (US-08-04)

## Acceptance criteria

- [ ] Filter addable; cutoff changes timbre audibly
- [ ] Golden test documents expected attenuation
- [ ] Chains: instrument → gain → pan → filter (or documented order)
- [ ] Save/load round-trip

## Demo script (on-device, ~45s)

1. Play bright oscillator → add filter → sweep cutoff down → hear dulling.

## Tests required

- [ ] C++ golden filter test
- [ ] Manual on device

## Depends on

US-08-02

## Status

**Todo**
