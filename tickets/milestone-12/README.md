# Milestone 12 — ProjectEngine decomposition

**Theme:** Separation of concerns — per-device control classes, extracted domain services, thin `ProjectEngine` facade.

**Type:** Developer / architecture refactor (no user-facing UX change unless regression).

## Why now

US-10-01 refactored the **playback snapshot** (`DeviceNodePlayback` variant + `DeviceChain.cpp`) but left `ProjectEngine` as a ~2,200-line god object with flat `Device` structs and ~69 type-dispatch branches. Every new device type still requires editing `ProjectEngine.cpp` in multiple places.

## Architecture docs

- [ADR-0007](../../docs/adr/ADR-0007-project-engine-decomposition.md) — decision record
- [project_engine_refactor.md](../../docs/architecture/project_engine_refactor.md) — full plan + dependency graph

## Phases

| Phase | Stories | Deliverable |
|-------|---------|-------------|
| **P0 Plan** | US-12-00 | ADR + docs accepted |
| **P1 Device framework** | US-12-01, US-12-02 | `IDeviceType`, registry, 4 device classes |
| **P2 Control model** | US-12-03, US-12-04 | `DeviceSlot` variant; param dispatch extracted |
| **P3 Domain services** | US-12-05, US-12-06, US-12-07 | Tracks/clips, transport, modulation |
| **P4 Audio path** | US-12-08, US-12-09 | Snapshot builder + arrangement mixer |
| **P5 Facade** | US-12-10, US-12-11 | Live session + slim ProjectEngine |
| **P6 Gate** | US-12-20 | Full regression demo |

## Realtime invariant

Control thread builds snapshots; audio thread reads them. **No virtual calls or JSON on the audio callback.** US-10-01 playback code stays; M12 changes who fills the snapshots.

## Demo / sign-off

US-12-20: run full C++ test suite + Flutter tests + 60s manual playback/save/load smoke on device. User-visible behavior identical to pre-M12.

## Depends on

- US-10-01 (playback variant refactor) — done

## Out of scope

- New instruments/effects
- Bridge/API changes
- Flutter UI work
