# US-08-01: Gain device

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **user**, I can add a **Gain** effect after my instrument and change level so the mix is louder or quieter.

## Goal

First effect in chain — audible, measurable, one investor increment. PO: **one effect per story**.

## Background

- [device_model.md](../../docs/architecture/device_model.md)
- [audio_graph.md](../../docs/architecture/audio_graph.md)

## UX flow

1. Select track → device strip → **Add effect** → Gain.
2. Gain slider (dB or linear) on strip card.
3. Play → level changes clearly audible.
4. Save/load preserves gain value.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Slider + numeric readout; avoid clipping without warning at extreme values |

## Scope

- `gain` device DSP in C++
- `addDeviceToTrack` inserts after instrument
- Parameter `gain` in serialization
- Golden test: known input → expected RMS change

## Out of scope

- Pan, Filter (US-08-02/03)
- Automation (US-08-04)

## Acceptance criteria

- [ ] User adds Gain to chain from strip
- [ ] Parameter change alters output level measurably
- [ ] C++ golden/offline test passes
- [ ] No NaN/inf in output
- [ ] Save/load round-trip
- [ ] Manual on device

## Demo script (on-device, ~45s)

1. Play loop at unity → add Gain → boost → clearly louder.

## Tests required

- [ ] C++ golden render test
- [ ] Serialization test
- [ ] Manual on device

## User-visible result

First mixing control — level shaping on the strip.

## Depends on

US-02-03

## Status

**Todo**
