# Architecture Migration Plan

This folder contains the migration plan from the current "flat struct / if-else" architecture toward a DAW-scale architecture.

## Background

As the project grows from MVP prototype toward full DAW, the current architecture has accumulating technical debt:

| Problem | Where | Scale |
|---------|-------|-------|
| **If-else bridge dispatch** | `BridgeHost::handleCommand()` — 440-line function | ~40 command branches |
| **Full-snapshot return on every mutation** | Every `set*` calls `getProjectSnapshotJson()` | ~30 mutation commands |
| **Stringly-typed parameters** | `IDeviceType::setParameter(string, float)` | ~21 device × ~10 params = ~200 runtime string compares |
| **3x redundant model mapping** | Dart `fromMap()` + C++ `varToSlot()` + Kotlin `mapToJson()` | Each new field requires 3 edits |
| **JUCE underutilized** | No `AudioProcessorGraph`, `RangedAudioParameter`, `ValueTree`, `UndoManager` | Custom reimplementation of all four |
| **No incremental snapshot** | Flutter gets entire project tree on every mutation | Wastes CPU + Binder bandwidth |

## Documents

| Document | Scope |
|----------|-------|
| [Phase 1 — Parameter Registry](phase-01-parameter-registry.md) | Kill string-switch parameter dispatch, single source of truth for all device params |
| [Phase 2 — Command Registry](phase-02-command-registry.md) | Kill 440-line if-else bridge; plugin-architecture for commands |
| [Phase 3 — Incremental Snapshots](phase-03-incremental-snapshot.md) | Delta-based UI updates; stop serializing unchanged state |
| [Phase 4 — ValueTree Control Model](phase-04-valuetree-control-model.md) | Leverage JUCE's state tree for change listeners, undo, serialization |
| [Phase 5 — JUCE AudioProcessorGraph](phase-05-processor-graph.md) | Replace custom DeviceChainOrchestrator |
| [Prioritization & Roadmap](roadmap.md) | What to do first, what to defer, risk/effort matrix |

## What stays untouched

The **audio thread hot path** is correct and **must not be changed**:

- `ProcessorArena` placement-new arena — keep
- `TrackPlaybackSnapshot` fixed-size arrays — keep
- `ModulatorArena` double-buffer with atomic slot flip — keep
- `TransportController` atomics-only — keep
- `thread_local` scratch buffers — keep
- `shared_mutex` read path — keep

All 5 phases target only the **control thread** and **bridge layer**.