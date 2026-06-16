# US-07-01: Open fullscreen sampler

## Type

Feature

## Milestone

Milestone 07 — Sampler fullscreen editor

## User story

As a **user**, I can **tap my sampler** on the device strip and open a **fullscreen sampler editor** focused on one sound.

## Goal

Dedicated editing surface — not cramped strip UI. Entry/exit navigation polished.

## Background

- AGENT.md §7 Fullscreen sampler view
- [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)

## UX flow

1. Select track with sampler + assigned sample.
2. Tap sampler device card → **fullscreen** editor opens.
3. Shows sample name, duration, current trim summary (if any).
4. Back/close → returns to arrangement with strip visible.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Edge-to-edge editor; system back closes editor; status bar readable |

## Scope

- Navigation: strip → fullscreen route
- Pass `deviceId` / `sampleId` to editor
- Placeholder layout for waveform region (US-07-02)

## Out of scope

- Waveform + trim interaction (US-07-02)
- Destructive audio edit

## Acceptance criteria

- [ ] Tap sampler opens fullscreen from strip
- [ ] Correct sample metadata shown
- [ ] Close returns to DAW shell without losing project state
- [ ] Widget test navigation
- [ ] Manual on device

## Demo script (on-device, ~30s)

1. Open sampler fullscreen → see sample name → close → back to timeline.

## Tests required

- [ ] Flutter navigation tests
- [ ] Manual on device

## User-visible result

Sampler feels like a first-class instrument, not a tiny card.

## Depends on

US-06-03

## Status

**Todo**
