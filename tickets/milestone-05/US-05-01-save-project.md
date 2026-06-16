# US-05-01: Save project

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I can save my project as a `.audioapp.zip` archive with diffable `project.json` inside so I can keep and share my work.

## Goal

`saveProject` writes a zip archive via the system save-file dialog.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- [ADR-0005](../../docs/adr/ADR-0005-diffable-project-format.md)
- [ADR-0006](../../docs/adr/ADR-0006-os-bridge-project-files.md)

## Scope

- Zip layout: `project.json`, `assets/samples/`, `metadata/`
- `project_format_version`, stable IDs, BPM, tracks, clips, devices, parameters
- **System save-file dialog** (SAF `CreateDocument`, `application/zip`, default `project.audioapp.zip`)
- No large binary inside JSON

## Out of scope

- Load (US-05-02)
- Export bundle with copied samples (M06+)
- Autosave, undo/redo implementation

## Acceptance criteria

- [x] User can save from UI
- [x] Archive contains valid, diffable, versioned `project.json`
- [x] C++ serialization + archive tests pass
- [x] Saved state matches in-memory project
- [x] System **save-file** dialog (not folder-tree consent)
- [x] User cancel → no save, no error
- [x] Last document URI remembered

## Tests required

- [x] C++ `project_archive_test.cpp`
- [x] Flutter integration test (mocked channel)
- [ ] Manual save on device

## User-visible result

Tap Save → system save dialog → `project.audioapp.zip` at chosen location.

## Status

**Done**
