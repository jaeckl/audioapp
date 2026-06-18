# US-08-18: Parameter automation lane data

## Type

Feature

## Milestone

Milestone 08 — Effects & automation

## User story

As a **producer**, I can **author and edit** automation breakpoint data for a parameter on the timeline and have it persist in the project.

## Goal

Lane/clip data model + editing UX — curve breakpoints stored per automation clip, editable after creation.

## Scope (delivered in automation MVP)

- `AutomationClip` with `points[{beat, value}]` on track
- Fullscreen curve editor (drag points, double-tap to add)
- JSON serialization round-trip
- Duplicate clip clears target for re-link

## Out of scope (follow-up)

- Touch-and-drag **recording** while transport runs
- Touch latch on knob writes breakpoints live
- Copy/paste curves between clips

## Acceptance criteria

- [x] Breakpoints stored per automation clip
- [x] Editor creates/moves/adds points
- [x] Save/load restores curves
- [ ] Record mode while playing (future)

## Tests required

- [x] `automation_clip_test.cpp` serialize path
- [x] Flutter curve editor save via bridge

## Depends on

US-08-04-parameter-automation

## Status

**Done** (manual breakpoint editing; live recording deferred)
