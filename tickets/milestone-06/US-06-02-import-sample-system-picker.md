# US-06-02: Import sample (system picker)

## Type

Feature

## Milestone

Milestone 06 — Sample library & sampler

## User story

As a **user**, I can **import my own audio file** via the system file picker so it appears in my sample library alongside the starter pack.

## Goal

SAF **open-file** for audio → sample registered in engine → visible in library list.

## Background

- ADR-0006 OS bridge pattern (mirror M05 save/load)
- AGENT.md §2.6, §2.7

## UX flow

1. User opens sample library → taps **Import**.
2. Android **Open document** dialog (audio MIME filter + `*/*` fallback).
3. User picks `.wav` / `.mp3` / `.ogg` (document supported formats).
4. Sample appears in **Imported** section with filename.
5. Cancel → no error, list unchanged.
6. Invalid/unreadable file → clear error in UI.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | SAF `OpenDocument`; persistable URI when granted; binary read off RT thread |

## Scope

- Kotlin: read audio bytes/metadata from URI
- C++: register imported sample (ID, display name, URI/path reference)
- Flutter: import button + error/success feedback
- `project.json` stores sample **reference** by ID (not embedded binary)

## Out of scope

- Copy sample into zip on save (future enhancement)
- Format conversion
- Waveform analysis

## Acceptance criteria

- [ ] Import opens **system file picker** (not raw path field)
- [ ] Imported sample appears in library list
- [ ] Preview works for imported sample
- [ ] Cancel → no error
- [ ] Bad file → visible error
- [ ] Save/load project preserves sample reference ID

## Demo script (on-device, ~60s)

1. Import a WAV from Downloads → see in library → preview plays.
2. Save project → load project → imported sample still listed.

## Tests required

- [ ] Kotlin URI read tests (or instrumented)
- [ ] C++ serialization of sample refs
- [ ] Flutter widget test
- [ ] Manual on device

## User-visible result

Bring your own sounds into the app like a professional workflow.

## Depends on

US-06-01

## Status

**Todo**
