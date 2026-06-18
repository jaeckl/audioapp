# US-12-08: Extract PlaybackSnapshotBuilder

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want playback snapshot rebuild isolated so that sample-bank PCM resolution and per-device playback nodes are built through the device registry, not a monolithic function in `ProjectEngine`.

## Goal

`PlaybackSnapshotBuilder::rebuild(tracks, sampleBank, modulationGraph, out[])` replaces `rebuildTrackPlaybackLocked()`.

## Background

- Builds `TrackPlaybackSnapshot`: MIDI notes from clips, sample regions, `DeviceNodePlayback[]` via device types
- US-10-01 variant params filled here — must use `IDeviceType::buildPlaybackNode`
- Called after most mutations — builder invoked from `ProjectEngine` after repo/device changes

## Scope

- [ ] Extract `PlaybackSnapshotBuilder` from `ProjectEngine.cpp`
- [ ] MIDI note flattening from clips → `PlaybackNote` array (unchanged logic)
- [ ] Sample region flattening with `SampleBank` lookup
- [ ] Device chain: iterate `DeviceSlot`s, call type's `buildPlaybackNode`
- [ ] `ProjectEngine` holds `TrackPlaybackSnapshot trackPlayback_[kMaxTracks]` — builder writes into it
- [ ] `trackPlaybackCount_` atomic updated by builder

## Out of scope

- Changing snapshot memory layout
- DeviceChain processing changes

## Acceptance criteria

- [ ] `device_chain_test`, `subtractive_synth_test` pass unchanged
- [ ] Sampler without loaded PCM still silent at playback
- [ ] New unit test: builder output for mixed device chain matches golden struct dump

## Demo script (developer, ~5 min)

1. Run device chain + subtractive synth tests.
2. Run new `playback_snapshot_builder_test`.

## Tests required

- [ ] `playback_snapshot_builder_test.cpp`
- [ ] `device_chain_test.cpp`, `subtractive_synth_test.cpp`

## Realtime/performance notes

Rebuild on control thread only. Audio thread still reads prebuilt snapshots.

## Depends on

US-12-02, US-12-03, US-12-07

## Status

Todo
