# Architecture Migration — Roadmap & Prioritization

> **Goal:** Order the 5 phases by risk, impact, and dependency to minimize disruption while delivering maximum value per increment.

## Dependency Graph

```
Phase 1: Param Registry
    │
    ▼
Phase 2: Command Registry
    │
    ▼
Phase 3: Incremental Snapshots
    │
    ▼
Phase 4: ValueTree Control Model
    │
    ▼
Phase 5: AudioProcessorGraph (DEFER)
```

Phases 1 and 2 are **independent of each other** and can be done in parallel. Phase 3 depends on Phase 2 (the delta replaces full-snapshot return). Phase 4 depends on Phase 1 (ValueTree uses `ParamId` for property keys). Phase 5 is deferred.

## Risk / Effort / Impact Matrix

| Phase | Effort | Risk | Impact | Parallelizable |
|-------|--------|------|--------|----------------|
| **P1: Param Registry** | 10.5 days | Low | Medium — cleans up the worst string-switch code | Yes — independent of P2 |
| **P2: Command Registry** | 6.25 days | Low-Medium | Medium — simplifies adding new commands | Yes — independent of P1 |
| **P3: Incremental Snapshots** | 8 days | Medium | High — biggest UX perf win | No — depends on P2 |
| **P4: ValueTree** | 14.5 days | Medium-High | High — enables undo, listeners, serialization | No — depends on P1 |
| **P5: ProcessorGraph** | 6.5 days | Medium | Low — defer unless routing requirements emerge | — (deferred) |

## Recommended Order

### Sprint 1 — Foundation (Phase 1 + Phase 2 in parallel)

**Goal:** Stop the bleeding. Kill the if-else ladders and string-switch chains. No visible behavior change.

| Week | Work | Verifiable outcome |
|------|------|-------------------|
| 1 | P1: `ParamDef`, `ParamRegistry` skeleton | Registry works for TrackGain device |
| 1 | P2: `CommandHandler`, `CommandRegistry` skeleton, migrate `ping` command | Bridge still works, no regressions |
| 2-3 | P1: Migrate remaining 20 device types | All 21 device types use int-switch `setParameter` |
| 2 | P2: Split commands into domain files, simplify Kotlin bridge | Bridge `handleCommand()` < 20 lines |
| 2-3 | P1 + P2: Tests + bugfixes | All existing tests pass |

**Risk:** Low — both phases are pure refactors with no behavioral changes.

**Doneness criteria:**
- No `if (parameterId == "...")` chains remain in any `*DeviceType.cpp`
- `BridgeHost::handleCommand()` delegates to registry (≤ 10 lines)
- Kotlin `when` has 5 OS-interactive branches + 1 generic fallback
- All existing tests pass

---

### Sprint 2 — Snapshot Performance (Phase 3)

**Goal:** Stop serializing the full project on every mutation.

| Week | Work | Verifiable outcome |
|------|------|-------------------|
| 4 | P3: Delta struct + serialization | `SnapstonDelta::toJson()` produces correct delta |
| 4-5 | P3: Return delta from ProjectEngine mutations | Dragging a slider returns 200 bytes instead of 50KB |
| 5 | P3: Dart `SnapshotStore` + merge logic | Flutter correctly applies partial updates |
| 5-6 | P3: Migrate Flutter screens from raw bridge to `SnapshotStore` | UI updates correctly on deltas |
| 6 | P3: Performance benchmark + tests | Full measure of bandwidth/CPU savings |

**Risk:** Medium — Dart merge logic must match C++ truth. Mitigation: full `getProjectSnapshot()` still available for "sync" button or assertion.

**Doneness criteria:**
- Simple param changes return delta JSON, not full snapshot
- Structural changes (add/remove track) still return `fullRefresh: true`
- Flutter `SnapshotStore` correctly applies deltas and updates UI
- Performance benchmark shows ≥ 90% reduction in bridge payload for slider drags

---

### Sprint 3 — Future-Proofing (Phase 4)

**Goal:** JUCE-native state management with undo, listeners, and structured serialization.

| Week | Work | Verifiable outcome |
|------|------|-------------------|
| 7-8 | P4: `ProjectTree` type/property identifiers | ValueTree builds correctly |
| 7-8 | P4: Migrate TrackState → ValueTree | All mutations operate on ValueTree |
| 8-9 | P4: JSON backward-compat adapter | Old project files still load correctly |
| 9 | P4: `UndoManager` integration | Undo/redo works for basic param changes |
| 9 | P4: Change listeners auto-trigger `rebuildTrackPlayback` | Removing explicit rebuild calls, relying on listeners |
| 10 | P4: Tests + verification | All existing tests + new ValueTree tests pass |

**Risk:** Medium-High — ValueTree migration touches the entire control-thread state. Mitigation: keep the old `TrackState` vector as a parallel data structure during migration (dual-write), then remove.

**Doneness criteria:**
- All project state lives in `juce::ValueTree`
- Old `project.json` format loads correctly via adapter
- ValueTree change listeners auto-trigger playback rebuilds
- UndoManager performs undo/redo of basic operations
- All audio-thread code unchanged

---

### Deferred — Phase 5

**Do not start until** the project needs parallel routing, sidechain, or send/return tracks.

## Summary

| Sprint | Duration | Delivers | Risk |
|--------|----------|----------|------|
| Sprint 1 | 3 weeks | No if-else ladders, no string-switch params | Low |
| Sprint 2 | 2-3 weeks | 90% bridge payload reduction | Medium |
| Sprint 3 | 3-4 weeks | Undo, listeners, serialization via JUCE | Medium-High |
| Phase 5 | Indefinitely deferred | Graph routing | — |

**Total active work:** ~8-10 weeks for 3 sprints.

## Risks to the Plan

| Risk | Impact | Mitigation |
|------|--------|------------|
| Adding new features during migration | Schedule slip | Freeze non-critical features during sprints; ship Phase 1 + 2 as silent refactors |
| ValueTree backward compat breaks legacy projects | Data loss | Adapter layer; write golden test files; verify every project file format |
| Undo across complex operations (add device + modulate) | Buggy undo | Start with simple undo (param changes, BPM); skip structural undo until stable |
| Team context switching | Slower progress | One developer focuses on migration; other on features using old API |
| JUCE version bump (8.0.x → 8.1) | API deprecations | Pin to 8.0.4 until migration is complete |