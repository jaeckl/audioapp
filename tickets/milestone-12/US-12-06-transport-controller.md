# US-12-06: Extract TransportController

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want transport state (BPM, playhead, loop, playing) isolated so that arrangement code and audio mix code share one small transport API.

## Goal

`TransportController` owns atomics + loop logic; `ProjectEngine::advancePlayhead`, `setPlaying`, etc. delegate.

## Background

- Transport atomics today: `playing_`, `playheadBeats_`, `bpm_`, `loopEnabled_`, `loopLengthBeats_`
- `advancePlayhead` implements loop wrap — must remain deterministic for offline render
- `EngineHost` exposes transport via `ProjectEngine`

## Scope

- [ ] `TransportController` class with same public behavior as current methods
- [ ] Move `advancePlayhead`, `setPlayheadBeats`, `resetPlayhead`, loop setters, `setBpm`
- [ ] `ProjectEngine` holds `TransportController` member; thin forwards
- [ ] Snapshot includes transport fields via controller getters

## Out of scope

- Ableton-style scene launch
- Tempo automation

## Acceptance criteria

- [ ] Loop wrap behavior unchanged (test if not covered)
- [ ] Offline render length uses same playhead advancement
- [ ] Atomic reads on audio thread unchanged (no new locks)

## Demo script (developer, ~3 min)

1. Run any transport-related tests; manual verify loop wrap in offline render if test exists.

## Tests required

- [ ] Unit test for loop wrap at boundary (add `transport_controller_test.cpp` if needed)

## Depends on

US-12-00

## Status

Todo
