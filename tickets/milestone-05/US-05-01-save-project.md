# US-05-01: Save project

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I want to **save my project to a file I choose** using the phone’s normal save dialog, so I can keep my tracks, clips, and settings in a `.audioapp.zip` I can back up or share.

## Goal

One-tap Save opens the **system save-file dialog** and writes a valid `.audioapp.zip` that contains everything needed to continue later — no hidden paths, no “save later” follow-up.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- [ADR-0005](../../docs/adr/ADR-0005-diffable-project-format.md) — zip layout, diffable `project.json`
- [ADR-0006](../../docs/adr/ADR-0006-os-bridge-project-files.md) — Android Kotlin owns SAF I/O; C++ owns JSON schema
- AGENT.md §2.6–2.7 — JUCE JSON, complete vertical slice

## UX flow

1. User builds a project (at least one track; clip optional but typical).
2. User taps **Save** in the app chrome.
3. Android shows **system save-file dialog** (`CreateDocument`).
   - Suggested filename: `project.audioapp.zip`
   - MIME: `application/zip`
4. User confirms location → app writes archive → UI shows **success** (e.g. “Saved project”).
5. User cancels dialog → **no error**, project unchanged, no file written.
6. Write/permission failure → **red error** in UI with short reason (not silent failure).

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | SAF `CreateDocument`; binary zip write (not text mode); persistable URI when granted |
| **Desktop (tests)** | `ProjectArchive.cpp` file path API for automated round-trip |

## Scope

- Zip layout: `project.json`, `assets/samples/`, `metadata/` (folders may be empty in M05)
- `project.json`: `project_format_version`, stable IDs, BPM, tracks, clips, devices, parameters
- C++ serialization via **`juce::JSON` / `juce::var`** (control thread only)
- Flutter **Save** control wired to bridge `saveProject`
- Kotlin `ProjectArchiveStore` builds zip bytes from C++ JSON string
- Remember last saved document URI when OS allows

## Out of scope

- Load (US-05-02) — but save output must be loadable by US-05-02
- Sample binary copy into archive (M06+)
- Autosave, “Save as” duplicate flow, cloud sync
- Undo/redo for save

## Acceptance criteria

- [ ] Tap Save → **system save dialog** appears (not folder tree, not internal path)
- [ ] Default name `project.audioapp.zip` (or equivalent suggestion)
- [ ] Archive contains valid, versioned, pretty-printed `project.json`
- [ ] Saved JSON includes **all current tracks, clips, devices, parameters** (matches in-memory engine)
- [ ] C++ tests round-trip **actual** `getProjectFileJson()` output through parse + load
- [ ] Cancel → no error toast, no partial file
- [ ] I/O error → visible error in UI
- [x] Serialization uses JUCE JSON API (no custom string parser)

## Demo script (on-device, ~60s)

1. Fresh launch → add track → add MIDI clip (optional: edit a note).
2. Tap **Save** → pick `myloop.audioapp.zip` in Downloads (or similar).
3. See “Saved project” (or equivalent success).
4. (Continue in US-05-02) Force-stop app → Load → same file → arrangement matches.

## Tests required

- [ ] C++ `project_serialization_test.cpp` — add track/clip, serialize, parse, assert track count and names
- [ ] C++ `project_archive_test.cpp` — zip write/read round-trip
- [ ] Flutter widget test — Save dispatches bridge command
- [ ] **Manual:** demo script on Android device

## User-visible result

Tap Save → familiar Android save sheet → file on disk the user chose → clear success feedback.

## Realtime/performance notes

Serialization and zip I/O off audio thread only.

## Documentation updates

- ADR-0005/0006 if format or bridge contract changes
- AGENT.md §9 if schema rules change

## Depends on

US-03-01 (clips), US-02-01 (tracks)

## Technical debt / follow-up

- None


## Companion stories

- [UX/UI](US-05-01-ux-ui.md)
- [Interaction](US-05-01-interaction.md)

## Status

**Done**
