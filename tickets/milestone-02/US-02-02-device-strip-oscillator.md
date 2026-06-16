# US-02-02: Device strip controls oscillator

## Type

Feature

## Milestone

Milestone 02 — Track & device strip

## User story

As a **user**, I see the device strip for my selected track and change an oscillator parameter so the sound changes when I press Play.

## Goal

First instrument on device chain; parameter command from Flutter to C++ with audible result.

## Background

- [device_model.md](../../docs/architecture/device_model.md)
- [audio_graph.md](../../docs/architecture/audio_graph.md)

## Scope

- Commands: `addDeviceToTrack`, `setDeviceParameter`
- Simple Oscillator device on selected track’s chain
- Device strip shows real chain from snapshot
- At least one parameter UI (e.g. frequency)
- Play routes through track graph

## Out of scope

- MIDI clip input (M03)
- `project.json` save (M05) — document serialization design only

## Acceptance criteria

- [ ] Device strip shows oscillator for selected track
- [ ] User changes frequency (or equivalent); sound changes audibly
- [ ] Project state owned by C++; Flutter is projection only
- [ ] Serialization design documented for track/device/parameter
- [ ] C++ tests for parameter application
- [ ] No duplicate project rules in Dart

## Tests required

- [ ] C++ unit tests
- [ ] Widget/integration test for parameter change
- [ ] Manual audio verification on device

## User-visible result

Track + bottom strip controlling real audio.

## Realtime/performance notes

- Parameter updates via atomic or lock-free queue to audio thread

## Documentation updates

- [ ] `device_model.md`, `project_model.md`

## Depends on

US-02-01

## Status

**Todo**
