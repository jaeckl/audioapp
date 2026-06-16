# US-06-01: Bundled sample library

## Type

Feature

## Milestone

Milestone 06 — Sample library & audio clips

## User story

As a **user**, I can open a **sample library** with a **starter pack** of built-in sounds so I can begin producing without importing files first.

## Goal

Library UI + engine index of bundled samples with stable IDs — first M06 investor increment.

## Background

- AGENT.md §7 Sample Library
- PO decision: **bundled starter pack + user import** (US-06-02)

## UX flow

1. User opens **Sample library** from app chrome or device strip entry point.
2. Sees categories or flat list of **bundled** samples (kick, snare, hat, etc.).
3. Tap sample → preview play (short audition, non-destructive).
4. Tap **Insert on track** (wired in US-06-03) or preview only in this story.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Bundled assets in APK/assets; list scrolls smoothly on phone |

## Scope

- Ship `assets/samples/bundled/` (or equivalent) in app package
- C++ sample registry: `id`, `displayName`, `source` (bundled vs imported)
- Flutter library screen (list + preview trigger)
- Preview playback off control thread

## Out of scope

- User import (US-06-02)
- Sample clip on timeline (US-06-03)
- Copying samples into `.audioapp.zip` on save (references only for MVP; document)

## Acceptance criteria

- [ ] Library screen opens from clear entry point
- [ ] ≥ 8 bundled samples visible with names
- [ ] Tap preview → hear sample (≤ 2s start latency)
- [ ] Each sample has stable engine ID
- [ ] Widget tests for list + navigation
- [ ] No crash if preview interrupted

## Demo script (on-device, ~45s)

1. Open library → scroll starter pack → preview kick → preview snare.

## Tests required

- [ ] C++ sample registry tests
- [ ] Flutter widget tests
- [ ] Manual on device

## User-visible result

App feels like a real music tool — sounds included out of the box.

## Depends on

US-05-02


## Companion stories

- [UX/UI](US-06-01-ux-ui.md)
- [Interaction](US-06-01-interaction.md)

## Status

**Todo**
