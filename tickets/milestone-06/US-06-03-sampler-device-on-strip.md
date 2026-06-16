# US-06-03: Sampler device on strip

## Type

Feature

## Milestone

Milestone 06 — Sample library & sampler

## User story

As a **user**, I can put a **Sampler** on my track’s device strip and **assign a library sample** to it.

## Goal

Sampler device type + assign sample command + strip UI — ready for MIDI trigger (US-06-04).

## Background

- [device_model.md](../../docs/architecture/device_model.md)

## UX flow

1. Select track → device strip → **Add device** → Sampler (or replace oscillator flow documented).
2. Sampler card shows **sample name** or “No sample”.
3. Tap **Choose sample** → opens library picker (or inline list).
4. Select sample → card updates → assignment stored in engine.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | One-handed flow from strip to library and back |

## Scope

- Device type `sampler` in C++
- `setSamplerSample(deviceId, sampleId)` or equivalent command
- Strip UI for sampler + sample name
- Lazy decode/load off audio thread

## Out of scope

- MIDI triggering (US-06-04)
- Trim (M07)

## Acceptance criteria

- [ ] User adds sampler to track from strip
- [ ] User assigns bundled or imported sample
- [ ] Assignment survives save/load (`project.json`)
- [ ] Missing sample → documented UX (placeholder + error on play)
- [ ] C++ tests for device + sample ref

## Demo script (on-device, ~45s)

1. Add sampler → assign kick from starter pack → see name on strip.

## Tests required

- [ ] C++ device + serialization tests
- [ ] Flutter widget tests
- [ ] Manual on device

## User-visible result

Device strip shows sampler with your chosen sound loaded.

## Depends on

US-06-01, US-06-02


## Companion stories

- [UX/UI](US-06-03-ux-ui.md)
- [Interaction](US-06-03-interaction.md)

## Status

**Todo**
