# US-02-02: Select track

## Type

Feature

## Milestone

Milestone 02 — Track & device strip

## User story

As a **user**, I can **tap a track** to select it so the device strip shows that track’s devices.

## Goal

Selection is authoritative in C++ and mirrored in Flutter — device strip updates without duplicate state.

## Background

- [project_model.md](../../docs/architecture/project_model.md) — `selectedTrackId`
- AGENT.md §4.3

## UX flow

1. User taps a track row in the arrangement.
2. Track highlights as selected.
3. Bottom **device strip** appears/updates for that track.
4. Tapping another track moves selection.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Clear selected state (color/border); strip does not cover transport |

## Scope

- Bridge: `selectTrack` with `trackId`
- C++ validates track exists
- Flutter updates `selectedTrackId` from snapshot
- Device strip visible when a track is selected

## Out of scope

- Multi-select tracks
- Clip selection (M03+)

## Acceptance criteria

- [x] Tap track → visual selected state
- [x] Engine `selectedTrackId` matches UI
- [x] Device strip shows selected track’s devices
- [x] Invalid `trackId` → structured bridge error (no crash)
- [x] C++ + Flutter tests

## Demo script (on-device, ~30s)

1. Add two tracks → tap first → strip shows devices.
2. Tap second → strip updates to second track.

## Tests required

- [x] C++ select track tests
- [x] Flutter widget test
- [x] Manual on device

## User-visible result

Tapping tracks feels like a real DAW — strip follows selection.

## Depends on

US-02-01


## Companion stories

- [UX/UI](US-02-02-ux-ui.md)
- [Interaction](US-02-02-interaction.md)

## Status

**Done**
