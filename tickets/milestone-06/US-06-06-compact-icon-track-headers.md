# US-06-06: Compact icon track headers

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips (arrangement polish)

## User story

As a **user**, I want **compact icon-only track headers** so the timeline gets maximum horizontal space on a phone.

## Goal

Replace wide text track names in the arrangement gutter with a **narrow icon column** (~44dp). Full track name remains available via tooltip / accessibility.

## Icon choice

- **Font Awesome** (`font_awesome_flutter`) includes music glyphs (guitar, drum, microphone, etc.) but not a full DAW instrument set.
- **This iteration:** built-in **Material icons** (piano, EQ, mic, audiotrack, …) — no new dependency. FA can be swapped in later if desired.

## UX flow

1. User adds tracks → each row shows a lane icon in a slim gutter.
2. Tap icon → select track (same as before).
3. Long-press / tooltip → shows track name (e.g. "Track 1").

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | 44×44dp min touch target; tooltip on long-press |

## Scope

- `TrackLaneIcon` helper + `_TrackHeader` icon gutter
- Remove 120px text header column

## Out of scope

- Per-track custom icon picker
- Font Awesome dependency (optional follow-up)

## Acceptance criteria

- [x] Header column ≤ 48dp wide
- [x] Track name in tooltip / semantics
- [x] Selection highlight preserved
- [x] Widget tests still pass

## Demo script (~20s)

1. Add two tracks → see two icons, more timeline width.
2. Long-press icon → track name tooltip.

## Depends on

US-02-01

## Companion stories

- [UX/UI](US-06-06-ux-ui.md)
- [Interaction](US-06-06-interaction.md)

## Status

**Done**
