# US-04-08: Multi-select notes (lasso or long-press)

## Type

Feature

## Milestone

Milestone 04 — Piano roll

## User story

As a **user**, I want **multi-select notes (lasso or long-press)** so my workflow on phone feels like a real DAW, not a demo.

## Goal

Ship **Multi-select notes (lasso or long-press)** as a complete vertical slice — demoable once on Android without follow-up fixes (M04).

## Background

- [roadmap.md](../../docs/milestones/roadmap.md) — US-04-08
- [AGENT.md](../../AGENT.md) §2.5–2.7 — vertical slice, JUCE JSON, system dialogs
- Relevant architecture docs under `docs/architecture/`

## UX flow

1. User opens the DAW and reaches the surface where **multi-select notes (lasso or long-press)** applies.
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

- End-to-end wiring for **Multi-select notes (lasso or long-press)** (Flutter → bridge → C++ engine where applicable)
- Serialization round-trip when state is persisted (M04 save/load rules)
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

1. Launch app → exercise **multi-select notes (lasso or long-press)** per UX flow above.\n2. Verify success feedback and persistence if applicable.

## Tests required

- [ ] C++ unit tests for engine/serialization logic (real JSON output, not mocks-only)
- [ ] Flutter widget or integration test where UI dispatches bridge commands
- [ ] Manual demo script on Android device

## User-visible result

User can **multi-select notes (lasso or long-press)** with immediate feedback — the milestone “wow moment” for this slice.

## Realtime/performance notes

Parse/serialize on control thread only; no JSON on audio thread. DSP changes must be realtime-safe.

## Documentation updates

- `docs/milestones/roadmap.md` status when shipped
- ADR update only if bridge or on-disk format changes

## Depends on

US-04-07

## Companion stories

- [UX/UI](US-04-08-ux-ui.md)
- [Interaction](US-04-08-interaction.md)

## Status

**Todo**
