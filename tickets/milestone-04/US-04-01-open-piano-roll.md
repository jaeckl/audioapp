# US-04-01: Open piano roll

## Type

Feature

## Milestone

Milestone 04 — Mobile MIDI editing

## User story

As a **user**, I can open a mobile-friendly piano roll from a MIDI clip on the timeline to edit notes.

## Goal

Clip editor navigation and piano roll shell with grid, pitch rows, and time axis.

## Background

- [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)

## Scope

- Tap clip → open full-screen or sheet piano roll
- Grid aligned to fixed BPM / bar divisions
- Read-only display of existing notes from engine snapshot

## Out of scope

- Note mutations (US-04-02)
- Velocity, swing, MPE

## Acceptance criteria

- [ ] User opens editor from timeline clip
- [ ] Notes from engine displayed correctly
- [ ] Layout usable on phone (scroll/zoom basics)
- [ ] Widget test for editor open/close

## Tests required

- [ ] Widget tests
- [ ] Manual phone smoke

## User-visible result

Piano roll opens and shows clip notes.

## Depends on

US-03-02

## Status

**Todo**
