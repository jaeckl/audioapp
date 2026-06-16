# US-06-08: Pinch horizontal zoom

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips (arrangement polish)

## User story

As a **user**, I want to **pinch-zoom the arrangement horizontally** so I can see more detail when editing clips or find space for new inserts.

## Goal

Two-finger pinch on the timeline changes **pixels per beat** (zoom), keeping the focal point stable under the fingers.

## UX flow

1. User places two fingers on the timeline and pinches out → beats get wider.
2. Pinch in → more bars visible in the same viewport.
3. One-finger drag still scrolls horizontally (US-06-09).

## Scope

- Stateful `pixelsPerBeat` (default 64, range ~28–200)
- `ScaleGestureRecognizer` on timeline area
- Playhead and clips rescale with zoom

## Out of scope

- Vertical zoom
- Zoom buttons in toolbar (optional later)

## Acceptance criteria

- [x] Pinch out increases clip width in beats-per-pixel terms
- [x] Pinch in decreases
- [x] Zoom clamped to sensible min/max
- [x] Playhead position stays beat-accurate

## Demo script (~20s)

1. Insert sample → pinch out → waveform detail easier to see.

## Depends on

US-06-04

## Companion stories

- [UX/UI](US-06-08-ux-ui.md)
- [Interaction](US-06-08-interaction.md)

## Status

**Done**
