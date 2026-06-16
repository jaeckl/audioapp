# US-05-02: Load project

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I can load a saved project and continue with tracks, clips, devices, and parameters restored.

## Goal

`loadProject` command restores authoritative C++ state and Flutter projection.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- Migration placeholder for future format versions

## Scope

- Command: `loadProject`
- Restore tracks, clips, devices, parameters, BPM
- Flutter UI reflects loaded snapshot
- Basic migration hook (no-op for v1)

## Out of scope

- Sample file copy on load (references only until export)
- Cloud sync

## Acceptance criteria

- [ ] User can load saved project from UI
- [ ] Arrangement, device strip, parameters match saved file
- [ ] Playback works after load
- [ ] C++ round-trip save→load tests
- [ ] Flutter integration test for save/load flow where practical

## Tests required

- [ ] C++ serialization + migration placeholder tests
- [ ] Integration test
- [ ] Manual close/reopen smoke

## User-visible result

Create project → save → kill app → load → continue editing.

## Depends on

US-05-01

## Status

**Todo**
