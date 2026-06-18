# US-12-11: Slim ProjectEngine facade

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want `ProjectEngine` to orchestrate services rather than implement everything so that the entry point is readable and future features have an obvious home.

## Goal

`ProjectEngine.cpp` ≤ ~400 LOC; `.hpp` exposes public API but private members are service handles + mutex + snapshot storage only.

## Background

- [project_engine_refactor.md](../../docs/architecture/project_engine_refactor.md) success metrics
- `EngineHost` continues to delegate to `ProjectEngine` — no API break
- Dead code from extraction must be deleted, not commented out

## Scope

- [ ] Wire all extracted services in constructor or `createProject`
- [ ] Each public method: lock → delegate → rebuild snapshots if needed
- [ ] Remove obsolete private structs/methods
- [ ] Single `std::mutex` on facade (document: finer locking deferred)
- [ ] File layout under `engine_juce/include/audioapp/`:
  - `devices/` — registry + types
  - `model/` — track/clip repos, project model
  - `transport/` — transport controller
  - `modulation/` — modulation graph
  - `playback/` — snapshot builder, arrangement mixer
  - `live/` — live performance session

## Out of scope

- EngineHost refactor
- Breaking bridge commands

## Acceptance criteria

- [ ] `wc -l ProjectEngine.cpp` ≤ 400
- [ ] Grep: zero device-specific logic outside `devices/` and `playback/`
- [ ] All engine tests + Flutter 51/51 green
- [ ] `snapshot()` and `toProjectFileData()` produce same JSON as pre-M12 fixtures

## Demo script (developer, ~5 min)

1. Line count check.
2. Full test suite.

## Tests required

- [ ] Full C++ test suite (compile individually per AGENTS.md pattern)
- [ ] `flutter test`

## Documentation updates

- ADR-0007 status → Accepted
- [overview.md](../../docs/architecture/overview.md) — update component diagram

## Depends on

US-12-04, US-12-05, US-12-06, US-12-07, US-12-08, US-12-09, US-12-10

## Status

Todo
