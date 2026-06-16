# US-09-02: Export WAV (system save dialog)

## Type

Feature

## Milestone

Milestone 09 — Offline render

## User story

As a **user**, I can **export my project to a WAV file** using the **system save dialog** and share it outside the app.

## Goal

M09 **wow moment:** Tap Export → render progress → pick location → playable WAV. PO: **SAF save dialog** (like M05).

## Background

- ADR-0006 OS bridge pattern
- AGENT.md §2.7 complete vertical slice

## UX flow

1. User taps **Export** in app chrome.
2. Optional: short format confirm (WAV, 44.1kHz stereo — document defaults).
3. Engine renders offline with **progress** indicator (percent or indeterminate + cancel).
4. Android **Create document** save dialog → default `export.wav` or `project.wav`.
5. Kotlin writes rendered bytes to URI.
6. Success message → user can open file in another app.
7. Cancel dialog → no file written; cancel render if in progress.
8. Failure → clear error (disk full, render error).

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | SAF `CreateDocument` `audio/wav` or `application/octet-stream`; binary write; same patterns as M05 zip |

## Scope

- Flutter Export UI + progress
- Bridge: `exportProject` / `renderProject` with Kotlin file write
- Reuse offline engine from US-09-01
- Cancel and error paths

## Out of scope

- Share sheet (PO chose save dialog primary)
- MP3/AAC export
- Cloud upload

## Acceptance criteria

- [ ] Export opens **system save dialog**
- [ ] Render completes faster than realtime for demo project
- [ ] WAV plays in external player
- [ ] Progress visible during render
- [ ] Cancel → no partial file / clean state
- [ ] Errors visible in UI
- [ ] Manual demo on device

## Demo script (on-device, ~90s)

1. Project with MIDI loop + sampler or oscillator → Export → save `mybeat.wav` → open in Files/Music app → plays.

## Tests required

- [ ] C++ golden render (US-09-01)
- [ ] Flutter widget test (export dispatches command)
- [ ] Manual on device

## User-visible result

**Wow:** take your beat out of the app — investor-shareable file.

## Depends on

US-09-01, US-05-01

## Status

**Todo**
