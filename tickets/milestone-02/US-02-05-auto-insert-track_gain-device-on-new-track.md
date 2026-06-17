# US-02-05: Auto-insert track_gain device on new track

## Type

Feature

## Milestone

Milestone 02 — Tracks & devices

## User story

As a **user**, I want **auto-insert track_gain device on new track** so my workflow on phone feels like a real DAW, not a demo.

## Goal

Ship **Auto-insert track_gain device on new track** as a complete vertical slice — demoable once on Android without follow-up fixes (M02).

## Background

- [roadmap.md](../../docs/milestones/roadmap.md) — US-02-05
- [AGENT.md](../../AGENT.md) §2.5–2.7 — vertical slice, JUCE JSON, system dialogs
- Relevant architecture docs under `docs/architecture/`

## UX flow

1. User opens the DAW and reaches the surface where **auto-insert track_gain device on new track** applies.
2. User performs the primary action (tap, drag, or system dialog).
3. On success → immediate visual and/or audible feedback; state persists in engine.
4. On cancel → prior state unchanged; no error toast.
5. On failure → short, visible error message (not silent empty state).

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Touch-first; system dialogs for save/open/export per ADR-0006; clear success/cancel/error |
| **Desktop (tests)** | File-path APIs for automated round-trip where applicable |

## Scope

- End-to-end wiring for **Auto-insert track_gain device on new track** (Flutter → bridge → C++ engine where applicable)
- Serialization round-trip when state is persisted (M02 save/load rules)
- C++ or widget tests for non-trivial logic
- On-device demo script passes

## Out of scope

- Features explicitly assigned to later stories in the same milestone
- Autosave, cloud sync, and desktop store builds unless named in this ticket

## Acceptance criteria

- [x] Primary user flow works end-to-end on Android device
- [x] Cancel leaves prior state unchanged
- [x] Failure shows clear message in UI (not silent empty state)
- [x] Uses JUCE JSON / platform primitives per AGENT.md §2.6 where persistence applies
- [x] Round-trip or playback proof when state or audio is involved

## Demo script (on-device, ~60s)

1. Launch app → exercise **auto-insert track_gain device on new track** per UX flow above.\n2. Verify success feedback and persistence if applicable.

## Tests required

- [x] C++ unit tests for engine/serialization logic (real JSON output, not mocks-only)
- [x] Flutter widget or integration test where UI dispatches bridge commands
- [x] Manual demo script on Android device

## User-visible result

User can **auto-insert track_gain device on new track** with immediate feedback — the milestone “wow moment” for this slice.

## Realtime/performance notes

Parse/serialize on control thread only; no JSON on audio thread. DSP changes must be realtime-safe.

## Documentation updates

- `docs/milestones/roadmap.md` status when shipped
- ADR update only if bridge or on-disk format changes

## Depends on

US-02-04

## Companion stories

- [UX/UI](US-02-05-ux-ui.md)
- [Interaction](US-02-05-interaction.md)

## Status

**Done**
