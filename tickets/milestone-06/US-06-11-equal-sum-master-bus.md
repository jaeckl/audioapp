# US-06-11: Equal-sum master bus to device out

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips

## User story

As a **user**, I want **all tracks mixed at equal level into master** so playback matches a simple DAW mix bus to the phone speaker.

## Goal

Each track contributes MIDI oscillator + sample clips at **equal gain** (`1 / N` tracks). Master output drives AAudio / default device out. Soft limit on master.

## Background

Aligns with `audio_graph.md` step 4–5: track outputs summed to master, then device.

## Scope

- `ProjectEngine::readMasterMix`
- Per-track playback snapshot (all tracks, not selected-only)
- `MasterMix.cpp` sine helper
- EngineHost Android + JUCE callbacks use master mix only

## Out of scope

- Per-track volume/pan
- Send/receive buses
- Master gain automation

## Acceptance criteria

- [x] Two tracks both audible when playing
- [x] Equal gain (1/N) per track
- [x] Master → stereo device output
- [x] C++ test `master_mix_test.cpp`

## Demo script (~45s)

1. Add two tracks, different oscillator frequencies.
2. Play → hear both tones mixed.
3. Add kick on track 1, snare on track 2 → hear both samples.

## Depends on

US-06-05, US-06-10

## Companion stories

- [UX/UI](US-06-11-ux-ui.md)
- [Interaction](US-06-11-interaction.md)

## Status

**Done**
