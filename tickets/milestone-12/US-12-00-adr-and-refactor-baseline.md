# US-12-00: ProjectEngine decomposition — ADR & architecture baseline

## Type

Spike / Documentation

## Milestone

Milestone 12 — ProjectEngine decomposition

## User story

As a **developer**, I want an accepted architecture decision and refactor roadmap so that M12 implementation stories have a shared target and do not re-debate structure mid-flight.

## Goal

ADR-0007 and `project_engine_refactor.md` are reviewed, linked from tickets, and define the module boundaries every subsequent US-12 story follows.

## Background

- `ProjectEngine` ~2,200 LOC god object — see [project_engine_refactor.md](../../docs/architecture/project_engine_refactor.md)
- US-10-01 fixed playback-layer variants only; control model still flat
- [device_model.md](../../docs/architecture/device_model.md) describes conceptual device interface not yet implemented in C++
- [ADR-0003](../../docs/adr/ADR-0003-graph-based-engine.md) — graph snapshots; M12 aligns control thread with that model

## Scope

- [x] Author [ADR-0007](../../docs/adr/ADR-0007-project-engine-decomposition.md) (status: Proposed → Accepted when PO/dev sign off)
- [x] Author [project_engine_refactor.md](../../docs/architecture/project_engine_refactor.md) with dependency graph and success metrics
- [x] Add M12 section to `tickets/story_manifest.yaml`
- [x] Link ADR from `docs/architecture/overview.md` (one line)
- [x] Update US-10-01 ticket to clarify it was **playback-layer only**; M12 continues control layer

## Out of scope

- C++ code changes
- Flutter / bridge changes

## Acceptance criteria

- [x] ADR lists all services to extract and realtime rules (no audio-thread virtual/JSON)
- [x] Refactor doc names exact new modules/files to create
- [x] Story dependency order documented (US-12-01 → … → US-12-20)
- [ ] PO/dev can answer: "Where does sampler filter cutoff live after M12?" → `SamplerDeviceType`

## Demo script (review, ~15 min)

1. Open ADR-0007 — confirm decision + consequences.
2. Open refactor plan — confirm mermaid diagram and phase table.
3. Pick "add reverb device" hypothetical — walk through ≤3 files touched.

## Tests required

- [ ] N/A (documentation only)

## Documentation updates

- ADR-0007, project_engine_refactor.md, overview.md, US-10-01 cross-link

## Depends on

None

## Status

In progress (docs landed; PO review pending)
