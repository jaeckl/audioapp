# US-06-10: Master track row in arrangement

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips

## User story

As a **user**, I want a **master track row pinned to the bottom** of the arrangement so I can see where all tracks sum before device output.

## Goal

Visual master lane (speaker icon + “Master → Device out”) anchored below track lanes; scrolls horizontally in sync with the timeline.

## Background

Graph-based engine (ADR-0003, `audio_graph.md`) targets `Track → Master → device out`. This story delivers the **UI anchor** for that bus.

## UX flow

1. User opens arrangement → master row always visible at bottom.
2. Horizontal scroll on tracks or master stays aligned.
3. Playhead line drawn through master lane during transport.

## Scope

- `MasterTrackSnapshot` in engine snapshot JSON
- `_MasterHeader` + `_MasterLane` in Flutter
- Synced horizontal scroll controllers

## Out of scope

- Master fader / meter (M08)
- Selecting master for editing

## Acceptance criteria

- [x] Master row visible with tracks and when tracks empty
- [x] Master scroll synced with timeline
- [x] Snapshot includes `master` object

## Depends on

US-02-01

## Companion stories

- [UX/UI](US-06-10-ux-ui.md)
- [Interaction](US-06-10-interaction.md)

## Status

**Done**
