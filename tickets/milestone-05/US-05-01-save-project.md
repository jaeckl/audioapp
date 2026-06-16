# US-05-01: Save project

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I can save my project to a versioned folder with human-readable `project.json` so I can keep my work.

## Goal

`saveProject` command writes diffable folder structure.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- [ADR-0005](../../docs/adr/ADR-0005-diffable-project-format.md)

## Scope

- Folder layout: `project.json`, `assets/`, `metadata/`
- `project_format_version`, stable IDs, BPM, tracks, clips, devices, parameters
- Save UI (path picker or app documents dir)
- No large binary in JSON

## Out of scope

- Load (US-05-02)
- Export bundle with copied samples (M06+)
- Autosave, undo/redo implementation

## Acceptance criteria

- [ ] User can save from UI
- [ ] `project.json` is valid, diffable, versioned
- [ ] C++ serialization tests pass
- [ ] Saved state matches in-memory project

## Tests required

- [ ] C++ serialization tests
- [ ] Manual save smoke

## User-visible result

Project file on disk user can inspect in git/diff tool.

## Depends on

US-02-02 (minimum project content); ideally US-04-02

## Status

**Todo**
