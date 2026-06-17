# US-06-04: Waveform in arrangement

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips

## User story

As a **user**, I want to **see the waveform of a sample clip in the arrangement view** so I can recognize sounds and edit timing visually.

## Goal

Each sample clip block on the timeline shows a **readable waveform** (not just a flat color rectangle).

## Background

- PO refinement: waveform in **arrangement**, not only fullscreen editor (M07)
- [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)

## UX flow

1. User has one or more sample clips on a track (US-06-03).
2. In the arrangement timeline, each sample clip draws a **mini waveform** inside the clip bounds.
3. Zoom/scroll: waveform scales with clip width (static peak cache OK for MVP).
4. MIDI clips unchanged; only sample clips show waveform.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Waveform readable on phone clip width ≥ 1 bar; dark theme contrast |

## Scope

- Engine or Flutter: peak/waveform cache per `sampleId` (generate off audio thread)
- Arrangement widget: paint waveform inside sample clip rect
- Invalidate cache when sample imported/changed
- Performance: cache peaks; do not decode full PCM every frame

## Out of scope

- Trim handles on waveform (M07)
- Pinch-zoom waveform only inside clip
- Stereo lanes

## Acceptance criteria

- [ ] Sample clips show waveform; MIDI clips do not
- [ ] Waveform matches correct sample after insert
- [ ] Scrolling timeline does not stutter (cached peaks)
- [ ] Save/load: waveform redraws from same sample ref
- [ ] Widget test: sample clip renders waveform placeholder or golden
- [ ] Manual: visually distinct kick vs snare waveforms

## Demo script (on-device, ~45s)

1. Insert kick + snare on same track → see different waveforms in two clips.

## Tests required

- [ ] C++ or Dart peak extraction unit test on fixture WAV
- [ ] Widget test
- [ ] Manual on device

## User-visible result

Arrangement looks like a DAW — you **see** your audio.

## Depends on

US-06-03

## Companion stories

- [UX/UI](US-06-04-ux-ui.md)
- [Interaction](US-06-04-interaction.md)

## Status

**Done**
