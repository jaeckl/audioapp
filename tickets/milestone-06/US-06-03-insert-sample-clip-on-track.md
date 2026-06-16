# US-06-03: Insert sample clip on track

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips

## User story

As a **user**, I want to **insert a sample clip from the sample library onto a track** so I can build an arrangement with audio regions, not only MIDI.

## Goal

Pick a sample in the library → place an **audio/sample clip** on the selected track at a chosen timeline position (parallel to MIDI clips).

## Background

- [project_model.md](../../docs/architecture/project_model.md) — extend with `sampleClips` or `audioClips` on track
- AGENT.md §6 — arrangement-first
- PO refinement: clips on timeline, not sampler-in-strip as M06 core

## UX flow

1. User selects a track in the arrangement.
2. User opens **Sample library** (or inline picker).
3. User taps a sample → **Insert on track** (or drag-to-timeline when ready).
4. Sample clip appears on the timeline at default or chosen start beat with length = sample duration (or default bar length).
5. Clip shows label (sample name); waveform in US-06-04.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Insert flow ≤ 3 taps from library; clip visible immediately |

## Scope

- C++ model: sample clip entity (`id`, `sampleId`, `startBeat`, `lengthBeats`, optional trim refs for M07)
- Bridge: `createSampleClip(trackId, sampleId, startBeat, lengthBeats?)`
- Flutter: library action **Insert on track**; arrangement renders clip block
- Project serialization via `juce::JSON`
- Uses sample registry from US-06-01 / US-06-02

## Out of scope

- Waveform drawing (US-06-04)
- Playhead audition (US-06-05)
- Piano-roll-style sample editor (M07)
- MIDI-triggered sampler device (deferred — see milestone-06.md)

## Acceptance criteria

- [ ] User inserts bundled or imported sample onto selected track
- [ ] Clip appears at correct timeline position/length
- [ ] Stable clip + sample IDs in engine
- [ ] Save/load restores sample clips and references
- [ ] C++ round-trip tests
- [ ] Flutter widget test: insert flow

## Demo script (on-device, ~60s)

1. Select track → open library → insert kick → see clip block on timeline.
2. Save → force-stop → Load → clip still there.

## Tests required

- [ ] C++ sample clip create + serialization
- [ ] Flutter widget test
- [ ] Manual on device

## User-visible result

**Wow:** audio on the timeline from your library — like a real DAW.

## Depends on

US-06-01, US-06-02, US-02-02

## Companion stories

- [UX/UI](US-06-03-ux-ui.md)
- [Interaction](US-06-03-interaction.md)

## Status

**Todo**
