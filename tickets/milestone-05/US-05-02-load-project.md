# US-05-02: Load project

## Type

Feature

## Milestone

Milestone 05 — Save & load

## User story

As a **user**, I want to **open a saved `.audioapp.zip`** using the phone’s normal file picker, so I can continue exactly where I left off — tracks, clips, devices, and parameters visible and playable.

## Goal

One-tap Load opens the **system open-file dialog**, restores authoritative C++ state, and refreshes the UI. A successful load must **never** show an empty arrangement when the file contained tracks.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- [ADR-0006](../../docs/adr/ADR-0006-os-bridge-project-files.md)
- AGENT.md §2.6–2.7
- Pairs with US-05-01 (same zip format)

## UX flow

1. User taps **Load** in the app chrome.
2. Android shows **system open-file dialog** (`OpenDocument`).
   - Filter: zip / octet-stream (broad enough for file managers)
3. User picks a `.audioapp.zip` saved by this app (or US-05-01 demo file).
4. App extracts `project.json`, loads into engine, pushes snapshot to Flutter.
5. UI shows **success** (e.g. “Loaded project”) and arrangement + device strip match file.
6. User cancels → **no error**, previous session state unchanged.
7. Missing `project.json`, corrupt zip, wrong version, parse error → **red error** with short message — **not** empty arrangement with success text.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | SAF `OpenDocument`; read zip as binary; grant read URI permission |
| **Desktop (tests)** | `loadProjectFromArchive` path API |

## Scope

- Command: `loadProject`
- Kotlin reads archive bytes → extract `project.json` → C++ `loadProjectFileJson`
- Flutter applies returned snapshot (tracks, clips, devices, parameters, selection)
- Playback works immediately after load (no extra “refresh” step)
- Clear error propagation to Flutter `PlatformException` → UI `_error`

## Out of scope

- Cloud sync, recent-files list UI (optional later)
- Opening raw `project.json` without zip wrapper
- Import from other DAW formats

## Acceptance criteria

- [ ] Tap Load → **system open dialog** (not folder tree)
- [ ] After load: track count, clip positions, device parameters **match** saved archive
- [ ] Play after load hears same content as before save
- [ ] **Kill app** between save and load → demo still passes
- [ ] Cancel → no error, state unchanged
- [ ] Invalid/corrupt archive → **visible error**, arrangement not falsely cleared to “success”
- [ ] Successful load with N tracks → UI shows N tracks (guard against silent parse-to-empty)
- [ ] C++ tests: save archive in test → load → assert track names and clip count
- [ ] Deserialize via **`juce::JSON`** (no custom parser)

## Demo script (on-device, ~60s)

1. Complete US-05-01 demo (save `myloop.audioapp.zip` with ≥1 track + clip).
2. Force-stop app from Android settings.
3. Relaunch app (empty or default project is OK).
4. Tap **Load** → pick `myloop.audioapp.zip`.
5. See track + clip on timeline; device strip shows saved frequency; Play works.

**Sign-off:** PO runs steps 1–5 once without developer assistance.

## Tests required

- [ ] C++ `project_archive_test.cpp` — full round-trip after `addTrack` + `createMidiClip`
- [ ] C++ serialization test parses **pretty-printed** JSON from `projectFileToJson` (whitespace after `:`)
- [ ] Flutter integration test — load returns snapshot with tracks (mocked channel)
- [ ] **Manual:** demo script on Android device

## User-visible result

Save → kill app → Load → **“wow”**: arrangement back, ready to play and edit.

## Realtime/performance notes

Parse and load on control thread; audio graph updated before Play.

## Documentation updates

- Bridge doc if load response shape changes

## Depends on

US-05-01

## Technical debt / follow-up

- [ ] Migrate `ProjectJson.cpp` to `juce::JSON` (AGENT.md §2.6)
- [ ] Optional: show loaded track count in success message for PO clarity


## Companion stories

- [UX/UI](US-05-02-ux-ui.md)
- [Interaction](US-05-02-interaction.md)

## Status

**Done**
