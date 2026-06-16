# US-09-01: Offline render engine

## Type

Feature

## Milestone

Milestone 09 — Offline render

## User story

As a **developer/PO**, the engine can **render the current project to a WAV buffer** faster than realtime without using the live audio device.

## Goal

C++ offline render path with deterministic golden output — prerequisite for export UX (US-09-02).

## Background

- AGENT.md Milestone 09
- [performance_budgets.md](../../docs/testing/performance_budgets.md)

## UX flow

N/A (engine-facing). Validated via tests and internal command.

## Scope

- `renderProject` command (output path or buffer)
- Offline graph: same devices/effects as playback
- Bypass AAudio; write IEEE float or PCM WAV
- Progress callback hook (throttled) for Flutter
- Bounded memory for MVP project sizes

## Out of scope

- Stems/multitrack export
- Flutter save dialog (US-09-02)

## Acceptance criteria

- [ ] Renders fixture project faster than realtime
- [ ] Output WAV non-silent for known project
- [ ] Deterministic golden hash/RMS vs reference
- [ ] No realtime device required
- [ ] Errors structured (`render_failed`, etc.)

## Demo script

Engine test harness: render fixture → compare golden file.

## Tests required

- [ ] C++ offline render golden test
- [ ] Performance smoke (simple project < 10s render for 30s audio)

## User-visible result

(Internal) Engine ready for user-facing export.

## Depends on

US-08-03 (minimum graph richness)

## Status

**Todo**
