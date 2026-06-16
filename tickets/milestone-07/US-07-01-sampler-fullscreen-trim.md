# US-07-01: Sampler fullscreen trim

## Type

Feature

## Milestone

Milestone 07 — Sampler fullscreen editor

## User story

As a **user**, I can open the sampler fullscreen, set trim start/end, and hear playback respect trim without modifying the original audio file.

## Goal

Fullscreen sampler editor with non-destructive trim metadata.

## Background

- AGENT.md §7 Sampler fullscreen view

## Scope

- Tap sampler device → fullscreen view
- Sample info display; waveform if feasible in slice
- Trim start/end controls
- Playback uses trim metadata
- Source file unchanged on disk

## Out of scope

- Destructive edit, slicing, root note pads
- Time-stretch

## Acceptance criteria

- [ ] Fullscreen opens from device strip
- [ ] Trim changes affect playback
- [ ] Original file byte-identical after session
- [ ] Trim stored in project serialization
- [ ] Tests for trim metadata round-trip

## Tests required

- [ ] C++ playback with trim bounds
- [ ] Widget test for editor
- [ ] Manual smoke

## User-visible result

Shape sample start/end in a dedicated editor.

## Depends on

US-06-02

## Status

**Todo**
