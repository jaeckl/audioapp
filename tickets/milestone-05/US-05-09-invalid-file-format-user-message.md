# US-05-09: Invalid file format user message

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I want **invalid file format user message** so my workflow on phone feels like a real DAW, not a demo.

## Goal

Ship **Invalid file format user message** as a complete vertical slice — demoable once on Android without follow-up fixes (M05).

## Background

- [roadmap.md](../../docs/milestones/roadmap.md) — US-05-09
- [AGENT.md](../../AGENT.md) §2.5–2.7 — vertical slice, JUCE JSON, system dialogs
- Relevant architecture docs under `docs/architecture/`

## UX flow

1. User opens the DAW and reaches the surface where **invalid file format user message** applies.
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

- End-to-end wiring for **Invalid file format user message** (Flutter → bridge → C++ engine where applicable)
- Serialization round-trip when state is persisted (M05 save/load rules)
- C++ or widget tests for non-trivial logic
- On-device demo script passes

## Out of scope

- Features explicitly assigned to later stories in the same milestone
- Autosave, cloud sync, and desktop store builds unless named in this ticket

## Acceptance criteria

- [ ] Primary user flow works end-to-end on Android device
- [ ] Cancel leaves prior state unchanged
- [ ] Failure shows clear message in UI (not silent empty state)
- [ ] Uses JUCE JSON / platform primitives per AGENT.md §2.6 where persistence applies
- [ ] Round-trip or playback proof when state or audio is involved

## Demo script (on-device, ~60s)

1. Launch app → exercise **invalid file format user message** per UX flow above.\n2. Verify success feedback and persistence if applicable.

## Tests required

- [ ] C++ unit tests for engine/serialization logic (real JSON output, not mocks-only)
- [ ] Flutter widget or integration test where UI dispatches bridge commands
- [ ] Manual demo script on Android device

## User-visible result

User can **invalid file format user message** with immediate feedback — the milestone “wow moment” for this slice.

## Realtime/performance notes

Parse/serialize on control thread only; no JSON on audio thread. DSP changes must be realtime-safe.

## Documentation updates

- `docs/milestones/roadmap.md` status when shipped
- ADR update only if bridge or on-disk format changes

## Depends on

US-05-08

## Companion stories

- [UX/UI](US-05-09-ux-ui.md)
- [Interaction](US-05-09-interaction.md)

## Status

**Todo**
