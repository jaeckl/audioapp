# US-08-01: Effect device chain

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **user**, I can add gain, pan, and filter devices after my instrument and hear the mix change when I adjust their parameters.

## Goal

Three effect devices on device chain with audible DSP.

## Background

- [device_model.md](../../docs/architecture/device_model.md)
- [audio_graph.md](../../docs/architecture/audio_graph.md)

## Scope

- Gain, Pan, Filter devices
- `addDeviceToTrack` for effects
- Parameter UI on device strip
- Linear chain: instrument → effects → track out

## Out of scope

- Automation (US-08-02)
- Send/receive buses

## Acceptance criteria

- [ ] User adds each effect type to chain
- [ ] Parameter changes alter audio measurably
- [ ] Golden tests: gain amplitude, pan, filter response
- [ ] No NaN in output

## Tests required

- [ ] C++ golden/offline render tests per device
- [ ] Manual device smoke

## User-visible result

Shape tone with built-in effects on the strip.

## Depends on

US-02-02

## Status

**Todo**
