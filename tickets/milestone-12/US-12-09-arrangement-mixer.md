# US-12-09: Extract ArrangementMixer

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want arrangement-time audio mixing in its own module so that `ProjectEngine` is not responsible for LFO evaluation, per-track summing, and master gain on the audio path.

## Goal

`ArrangementMixer` implements `readMasterMix`, `readMasterMixStereo`, `mixAtPlayheadBeat*`, and `renderOffline` orchestration using prebuilt snapshots + `processDeviceChain`.

## Background

- ~200 lines in `mixAtPlayheadBeatStereo` — LFO per-frame buffer, track iteration, sample regions + device chain
- Uses `trackPlayback_[]`, `lfoPlayback_[]`, `modEdgePlayback_[]`, transport `playing_` atomic
- `renderOffline` on control thread calls mix path repeatedly

## Scope

- [ ] Move mix methods to `ArrangementMixer` (or `ArrangementRenderer`)
- [ ] Constructor/refs: playback snapshots, transport atomics, modulation playback arrays, master gain atomic
- [ ] `ProjectEngine::readMasterMix*` forwards to mixer
- [ ] Preserve `thread_local` LFO buffer strategy (no audio-thread alloc after warm-up)
- [ ] `activeOscillatorFrequencyHz` — move to mixer or small helper reading snapshots

## Out of scope

- Master limiter redesign
- Solo/mute (future M08 stories)
- Live mix path (`readLiveMix` stays in live session US-12-10)

## Acceptance criteria

- [ ] Offline render output unchanged for fixed project fixture (within float tolerance)
- [ ] Silence when transport stopped
- [ ] No new allocations on audio thread after warm-up
- [ ] `device_chain_test` engine integration section passes

## Demo script (developer, ~5 min)

1. Run offline render test if exists; else `device_chain_test` integration block.

## Tests required

- [ ] Existing mix/device chain tests
- [ ] Optional: short golden WAV compare for offline render

## Depends on

US-12-08

## Status

Todo
