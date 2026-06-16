# US-02-01: Add track

## Type

Feature

## Milestone

Milestone 02 — Track & device strip

## User story

As a **user**, I can **add a new track** from the arrangement so I can build a multi-part project.

## Goal

Tap **+ Track** → a named track appears in the timeline, backed by the C++ engine with a stable ID.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- AGENT.md §2.7, §4.3

## UX flow

1. User taps **Add track** (or equivalent) in the arrangement chrome.
2. Engine creates track with default name (e.g. `Track 1`).
3. Track row appears in the arrangement list/timeline.
4. New track becomes selected (or selection rules documented in US-02-02).

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Thumb-reachable add control; no modal required for default add |

## Scope

- Bridge command: `addTrack`
- C++ `ProjectEngine::addTrack`
- Flutter arrangement reflects new track from snapshot
- Default instrument device created on track (oscillator — see US-02-03)

## Out of scope

- Track rename, delete, reorder (later)
- Multiple track types (audio track — later)

## Acceptance criteria

- [x] User can add a track from UI
- [x] Track appears with engine-assigned stable ID and name
- [x] Snapshot returned to Flutter includes new track
- [x] C++ unit tests for `addTrack`
- [x] Flutter widget test dispatches add and shows track

## Demo script (on-device, ~30s)

1. Fresh project → tap **Add track**.
2. See **Track 1** (or next index) in arrangement.

## Tests required

- [x] C++ `project_engine_test.cpp`
- [x] Flutter widget / bridge tests
- [x] Manual on device

## User-visible result

Arrangement shows a new track row immediately.

## Depends on

US-01-01


## Companion stories

- [UX/UI](US-02-01-ux-ui.md)
- [Interaction](US-02-01-interaction.md)

## Status

**Done**
