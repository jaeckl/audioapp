# US-09-01: Export project WAV

## Type

Feature

## Milestone

Milestone 09 — Offline render

## User story

As a **user**, I can export/render my project to a local WAV file faster than realtime so I can share my work outside the app.

## Goal

Offline render path using same engine graph; progress feedback to UI.

## Background

- AGENT.md § Milestone 09
- [performance_budgets.md](../../docs/testing/performance_budgets.md)

## Scope

- Command: `renderProject` (output path, format WAV default)
- Offline engine bypasses realtime device; uses graph snapshot
- Progress callback to Flutter (throttled)
- Error handling for disk/graph failures
- Output to project `renders/` or user-chosen path

## Out of scope

- Stems export
- Cloud upload

## Acceptance criteria

- [ ] User triggers export from UI
- [ ] Render completes faster than realtime for simple test project
- [ ] Output WAV is non-silent for known fixture project
- [ ] Deterministic hash/RMS for golden test project
- [ ] Does not require realtime playback

## Tests required

- [ ] C++ offline render golden test
- [ ] Manual export smoke

## User-visible result

WAV file on device storage user can share.

## Depends on

US-05-02, US-08-01 (minimum graph richness)

## Status

**Todo**
