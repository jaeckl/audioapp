# ADR-0007: Decompose ProjectEngine into domain services + per-device types

## Status

Proposed (M12)

## Context

`ProjectEngine` has become the project's **god object** (~2,200 lines across `.hpp`, `.cpp`, and `_live.cpp`). It currently owns:

| Concern | Examples today |
|---------|----------------|
| Project model | tracks, clips, ID counters, selection |
| Device model | flat `Device` struct (45+ fields), per-type defaults, parameter dispatch (~69 `device->type` branches) |
| Transport | BPM, playhead, loop, playing |
| Modulation | LFO CRUD, modulation edges, LFO playback snapshot |
| Playback snapshots | `rebuildTrackPlaybackLocked`, sample-bank PCM resolution |
| Arrangement mix | `readMasterMix*`, per-track device chain + sample regions + LFO eval |
| Live performance | note in/out, capture-to-clip, live instrument building |
| Serialization glue | `toProjectFileData`, `loadFromProjectFileData`, `snapshot()` |

US-10-01 improved the **audio-thread playback layer** (`DeviceNodePlayback` + `std::variant` params in `DeviceChain.cpp`) but did **not** refactor the control-thread model inside `ProjectEngine`. The flat `Device` / `DeviceState` structs and giant `setDeviceParameter` chain remain.

Adding a fifth device type today requires edits in at least six places: defaults in `addDeviceToTrack`, parameter handlers, state copy helpers, JSON field mapping, playback rebuild, and live instrument builder.

## Decision

Decompose `ProjectEngine` into **focused control-thread services** with a thin orchestrator, and give each built-in device type its **own class** on the control thread.

### Target shape

```text
ProjectEngine (facade, ≤ ~400 LOC — mutex + delegation only)
├── ProjectModel          — tracks, clips, master, ID counters, selection
├── DeviceRegistry        — maps type id → IDeviceType
│   ├── OscillatorDeviceType
│   ├── SamplerDeviceType
│   ├── TrackGainDeviceType
│   └── SubtractiveSynthDeviceType
├── TransportController   — bpm, playhead, loop, playing atomics
├── ModulationGraph       — lfos, modEdges, rebuildLfoPlaybackLocked
├── PlaybackSnapshotBuilder — trackPlayback_[], resolves SampleBank PCM
├── ArrangementMixer      — readMasterMix*, offline render orchestration
└── LivePerformanceSession — note I/O, capture, live instrument from selected track
```

### Per-device type contract (`IDeviceType`, control thread only)

Each device type class owns:

1. **Type metadata** — `typeId`, display name, category (instrument/effect/utility)
2. **Instance state** — typed struct (not a flat superset)
3. **Factory** — `createDefault(id)` when inserting into a track
4. **Parameter API** — `setParameter`, `setStringParameter`, list of modulatable param ids
5. **Serialization** — read/write its slice of `project.json` via `juce::var` (§2.6 AGENT.md)
6. **Playback build** — given instance + `SampleBank`, fill one `DeviceNodePlayback` slot
7. **Live instrument build** (optional) — fill `LiveInstrumentSnapshot` for play mode

Track device chains store **`DeviceInstance`** as `std::variant<OscillatorInstance, SamplerInstance, …>` plus shared fields (`id`, `gain`, `pan`, `bypassed`) or a small wrapper struct.

### Realtime rules (unchanged)

- **No virtual dispatch on the audio thread.** Control thread builds immutable `TrackPlaybackSnapshot` arrays; audio thread reads them exactly as today.
- `DeviceChain.cpp` keeps `processDeviceChain` + `DeviceVariantParams` (US-10-01). M12 only changes **who builds** those nodes, not how they process.
- No JSON parsing, locks, or heap growth on the audio callback.

### Migration strategy

Incremental vertical slices — **each M12 story must leave all existing C++ + Flutter tests green**:

1. ADR + registry skeleton (no behavior change)
2. One device type migrated end-to-end (Oscillator — smallest)
3. Remaining device types
4. Extract non-device services (transport, modulation, mixer, live)
5. Delete dead code from `ProjectEngine.cpp`; facade delegates only

## Consequences

**Easier**

- New device = new `IDeviceType` subclass + register + playback hook — no edits to `ProjectEngine` if-else chains
- Unit tests per device type and per service
- Clear ownership: clips don't know about filter cutoff; devices don't know about playhead
- Aligns with [device_model.md](../architecture/device_model.md) conceptual interface

**Harder**

- Short-term churn across engine tests and `ProjectJson.cpp`
- Careful mutex boundaries while splitting (single `ProjectEngine` mutex remains until proven otherwise)

**Risks**

- Over-abstraction (forbidden by AGENT.md §2.8) — mitigate by keeping interfaces concrete and file count modest (~10 new headers, not a plugin framework)
- Regression in save/load — every device migration story requires JSON round-trip test

## References

- [audio_graph.md](../architecture/audio_graph.md)
- [device_model.md](../architecture/device_model.md)
- [project_engine_refactor.md](../architecture/project_engine_refactor.md) — story breakdown
- US-10-01 — playback-layer variant refactor (prerequisite, done)
- M12 tickets `tickets/milestone-12/`
