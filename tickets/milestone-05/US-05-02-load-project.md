# US-05-02: Load project

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I can open a saved `.audioapp.zip` and continue with tracks, clips, devices, and parameters restored.

## Goal

`loadProject` restores authoritative C++ state from a zip archive via the system open-file dialog.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- [ADR-0006](../../docs/adr/ADR-0006-os-bridge-project-files.md)

## Scope

- Command: `loadProject`
- Restore from `project.json` inside the archive
- Flutter UI reflects loaded snapshot
- **System open-file dialog** (SAF `OpenDocument`, zip filter)

## Out of scope

- Cloud sync
- Opening raw `project.json` without zip wrapper

## Acceptance criteria

- [x] User can load from UI
- [x] Arrangement, device strip, parameters match saved archive
- [x] Playback works after load
- [x] C++ round-trip archive tests
- [x] Flutter integration test (mocked)
- [x] System **open-file** dialog
- [x] Invalid archive → clear error
- [x] User cancel → unchanged state

## Tests required

- [x] C++ archive tests
- [x] Integration test (mocked)
- [ ] Manual load on device

## User-visible result

Save archive → kill app → Load → pick same `.audioapp.zip` → continue editing.

## Status

**Done**
