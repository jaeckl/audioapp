# US-06-07: Sample clip readable width

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips (arrangement polish)

## User story

As a **user**, I want **sample clips to use available horizontal space** so I can read the clip name and see the waveform without zooming first.

## Goal

Short samples (kick, hat) often span less than one beat and render too narrow. **Visual clip width** expands to at least a readable minimum and fills free space up to the next clip or timeline end / viewport.

## UX flow

1. User inserts kick at bar 1 → clip block is wide enough to read "Kick".
2. If lane is empty to the right, clip expands into that space (engine `lengthBeats` unchanged).

## Scope

- `ArrangementTimelineMetrics.clipDisplayWidthPx`
- Sample clips use expanded width; MIDI clips keep beat-accurate width
- Clip uses full lane height (minimal vertical padding)

## Out of scope

- Changing engine clip duration
- Overlapping clips visually

## Acceptance criteria

- [x] Short sample clip ≥ 120px wide on default zoom
- [x] Width capped before next clip on same track
- [x] Clip name legible (`labelMedium`, bold)
- [x] Unit tests for width helper

## Demo script (~30s)

1. Insert Kick → name readable without pinch zoom.
2. Insert second clip later on track → first clip stops before second.

## Depends on

US-06-03, US-06-04

## Companion stories

- [UX/UI](US-06-07-ux-ui.md)
- [Interaction](US-06-07-interaction.md)

## Status

**Done**
