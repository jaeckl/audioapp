# US-06-09: Horizontal scroll arrangement

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips (arrangement polish)

## User story

As a **user**, I want to **scroll the arrangement horizontally** so I can reach bars beyond the first screen and place clips further along the song.

## Goal

One-finger horizontal pan on the timeline scrolls the clip area. Timeline length extended to **32 bars** at default zoom.

## UX flow

1. User drags timeline left/right → content scrolls with momentum (bounce physics).
2. Track icon gutter stays fixed; only lanes scroll.
3. Works alongside pinch zoom without stealing two-finger gestures.

## Scope

- `ScrollController` on horizontal `SingleChildScrollView`
- Fixed icon gutter + scrolling lanes
- `timelineBeats = 32`

## Out of scope

- Scroll-linked ruler (future)
- Auto-scroll during playback follow mode

## Acceptance criteria

- [x] One-finger horizontal drag scrolls timeline
- [x] Headers stay fixed while lanes scroll
- [x] Content wider than viewport when zoomed in or many bars
- [x] Does not break clip tap / piano roll open

## Demo script (~20s)

1. Scroll right → empty bars visible for future clips.

## Depends on

US-03-01

## Companion stories

- [UX/UI](US-06-09-ux-ui.md)
- [Interaction](US-06-09-interaction.md)

## Status

**Done**
