# US-12-06: Extract TransportController

## Type

Refactor

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want transport state (BPM, playhead, loop, playing) isolated so that arrangement code and audio mix code share one small transport API.

## Goal

`TransportController` owns atomics + loop logic; `ProjectEngine::advancePlayhead`, `setPlaying`, etc. delegate.

## Scope

- [x] `TransportController` class with same public behavior as current methods
- [x] Move `advancePlayhead`, `setPlayheadBeats`, `resetPlayhead`, loop setters, `setBpm`
- [x] `ProjectEngine` holds `TransportController` member; thin forwards
- [x] Snapshot includes transport fields via controller getters

## Acceptance criteria

- [x] Loop wrap behavior unchanged (test if not covered)
- [x] Offline render length uses same playhead advancement
- [x] Atomic reads on audio thread unchanged (no new locks)

## Tests required

- [x] Unit test for loop wrap at boundary (`transport_controller_test.cpp`)

## Depends on

US-12-00

## Status

Done
