# US-02-01: Add and select track

## Type

Feature

## Milestone

Milestone 02 — Track & device strip

## User story

As a **user**, I can add a track and select it in the arrangement so I can work on one track at a time.

## Goal

C++-authoritative track list reflected in Flutter; selection drives UI state.

## Background

- [project_model.md](../../docs/architecture/project_model.md)
- [flutter_native_bridge.md](../../docs/bridge/flutter_native_bridge.md)

## Scope

- Commands: `createProject`, `addTrack`, `selectTrack`
- C++ project model with stable track IDs
- Flutter arrangement shows real tracks from engine snapshot
- Selection highlights track row

## Out of scope

- Devices on strip (US-02-02)
- MIDI clips (M03)
- Persistence (M05)

## Acceptance criteria

- [ ] User can add at least one track from UI
- [ ] Track appears in arrangement with name/id from engine
- [ ] Tapping track updates selection in Flutter and engine
- [ ] C++ unit tests for add/select commands
- [ ] Flutter widget test for track list update

## Tests required

- [ ] C++ unit tests
- [ ] Widget tests
- [ ] Manual device smoke

## User-visible result

Real tracks in the timeline, not placeholders.

## Documentation updates

- [ ] `docs/architecture/project_model.md` if schema differs

## Depends on

US-01-01

## Status

**Todo**
