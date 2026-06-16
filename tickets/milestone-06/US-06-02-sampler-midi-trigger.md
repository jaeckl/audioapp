# US-06-02: Sampler MIDI trigger

## Type

Feature

## Milestone

Milestone 06 — Sample library & sampler

## User story

As a **user**, I can load a sample into a sampler device and trigger it from a MIDI clip to make a simple sample-based loop.

## Goal

Simple Sampler device + MIDI note → sample playback on device chain.

## Background

- [device_model.md](../../docs/architecture/device_model.md)

## Scope

- Simple Sampler device type
- Load sample into device (command + UI)
- MIDI clip triggers sample voices
- Project stores sample reference by ID
- Lazy sample decode off audio thread

## Out of scope

- Trim editor (M07)
- Time-stretch / pitch-shift

## Acceptance criteria

- [ ] User assigns sample to sampler on device strip
- [ ] MIDI notes trigger correct sample
- [ ] Project save/load preserves sample reference
- [ ] C++ tests: trigger + serialization
- [ ] Manual loop on device

## Tests required

- [ ] C++ sampler + golden render test
- [ ] Serialization tests
- [ ] Manual smoke

## User-visible result

Simple sample-based beat or loop.

## Realtime/performance notes

- Voice pool; no alloc per note in RT

## Depends on

US-06-01, US-03-02

## Status

**Todo**
