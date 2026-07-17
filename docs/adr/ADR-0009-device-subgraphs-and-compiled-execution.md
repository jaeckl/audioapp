# ADR-0009: Device Subgraphs and Compiled Execution

## Status

Accepted — migration begins with the logical device-subgraph contract.

## Context

The engine has two different graph-like systems:

- `ProcessorGraphSnapshot` is a real, immutable top-level routing plan. It
  connects track/device insertion points for audio and MIDI, validates cycles,
  and creates a track execution order.
- A track's normal device path is still a linear `ProcessorArena` traversal.
  Input-panel behavior, device DSP, bypass, output mix/width, gain/pan,
  metering, automation, and modulation are split between `DeviceProcessor`,
  device-specific processors, and `DeviceChainOrchestrator`.

Virtual strips are nested device lists, not first-class graph definitions:

- Synth note FX and audio FX are flattened around their parent synth while a
  track playback snapshot is built.
- `ChainProcessor` owns a private linear arena and recursively calls the
  chain orchestrator.
- `DrumMachineProcessor` owns one private linear arena per pad and mixes pad
  output itself.

This works for the current product, but it obscures routing boundaries and
makes each new strip, side-chain, meter, or container require a special case.
It also makes the UI's input/device/output strip chrome look unlike the DSP
architecture it controls.

## Decision

Every `DeviceSlot` is modelled as a logical subgraph with three required
nodes, identified by the stable device ID:

```text
[input adapter] -> [device DSP] -> [output adapter]
```

The subgraph has typed audio and MIDI ports. The compiler may fuse the three
logical nodes into one tight audio-thread execution plan when there are no
observable intermediate routes. Fusing is mandatory for the default path:
the migration must not add per-device buffers, allocations, or virtual calls.

### Node responsibilities

| Node | Owns |
|---|---|
| Input adapter | signal admission, channel/event adaptation, future input trim and input-side routing |
| Device DSP | instrument/effect/utility algorithm and only its device-specific parameters |
| Output adapter | bypass crossfade, output mix/width, gain/pan, meter tap, output routing |

Common strip controls belong to the adapters, not to the device algorithm.
Existing DSP-specific input controls remain compatible until each family is
migrated to the generic input adapter.

### Containers

Containers are explicit nested `DeviceSubgraphDefinition` instances:

- Note FX: MIDI input adapter -> ordered Note-FX children -> instrument.
- Instrument audio FX: instrument -> ordered Audio-FX children -> output
  adapter.
- Chain: parent input adapter -> child graph -> parent output adapter.
- Drum pad: pad event input -> pad child graph -> pad output/mixer. The drum
  machine is a mixer/container graph, not a special global graph node.

The project graph connects only exposed container ports. The graph compiler
may flatten a nested graph into a single execution schedule, but the control
model and serialization retain the hierarchy.

### Lifecycle and real-time contract

- The control thread owns graph definitions and compiles immutable execution
  plans.
- The audio thread receives individual parameter commands and applies them at
  block boundaries; it never edits graph definitions.
- Structural edits compile an inactive playback state and publish it at a
  block boundary. Old state is reclaimed only after no audio callback pins it.
- Matching playback nodes share individually owned processor slots across
  double-buffered snapshots. Storage is released only after the final pinned
  snapshot releases it, so an inactive rebuild cannot destroy an active voice
  or effect tail. Slots can retain their state even when a neighbouring device
  is inserted, removed, or moves to another flattened index.

## Missing spots that the target model must cover

1. Typed ports need channel layout, MIDI/event capacity, and direction;
   `Audio`/`Midi` alone is insufficient for multichannel and side-chain work.
2. The compiler needs latency reporting and compensation before parallel
   branches, sends, or look-ahead processors are exposed.
3. Feedback must be explicit (`Delay`/one-block feedback edge), never an
   accidental cycle. Ordinary cycles remain rejected.
4. Automation and modulation targets must name logical node IDs and parameter
   IDs, not transient flattened device indices.
5. Meter, analyzer, and recording taps must be output-adapter ports so they
   do not alter signal order.
6. Buffer ownership must be part of compilation: preallocated scratch slots,
   in-place eligibility, fan-out copies, and deterministic overflow errors.
7. Save/load, undo, copy/paste, and preset application must preserve graph
   hierarchy and stable IDs while never serializing runtime processor state.
8. The Flutter API should expose graph edits as device/container operations
   initially; a raw `addNode/connect` API is deferred until UX and validation
   rules exist.
9. Plugin hosting is out of scope. The contract is for built-in devices and
   must not imply arbitrary third-party real-time code.

### Current top-level routing boundary

`AudioReceiver` is deliberately a **single-input stereo receiver**. The
compiler rejects more than one matching audio source and rejects channel-layout
conversion until an explicit Mixer/ChannelAdapter node exists. MIDI edge
capacity is compiled and enforced while copying events. Multi-input summing is
therefore not hidden in the receiver loop; it is future explicit graph-node
work. Existing per-device meters remain output-adapter/device-meter plumbing;
raw graph tap creation is deferred with the raw graph-edit API.

## Migration plan

1. Add logical three-node device subgraphs and fused execution plans with no
   behavioral change. **This ADR's implementation slice.**
2. Move universal output behavior fully into the output adapter and add
   explicit input-adapter policies per device family. **Implemented for pure
   `inputGain` trims** (dynamics and standard effects): the fused Input
   Adapter applies the trim after dry capture, then passes a neutralized
   parameter copy to DSP. Device-specific drive/feedback controls remain DSP
   parameters by design.
3. Compile synth Note-FX/Audio-FX as nested definitions, derive the flattened
   fused order from that hierarchy, and execute the prepared order in normal
   track playback. **Implemented.**
4. Compile `ChainProcessor` and drum-pad child playback into immutable nested
   graph schedules with stable device IDs, then derive a fixed child-index
   order consumed by the shared fused orchestrator. **Implemented.** The
   executor performs no hierarchy traversal or ID lookup on the audio thread.
5. Share compatible processor slots across structural swaps, keyed by the
   stable device ID and guarded by complete playback-node equivalence.
   **Implemented.** Future work can add compatible-state migration for an
   edited node rather than intentionally rebuilding it.
6. Generalise the top-level routing graph to typed ports, latency, and
   preallocated buffer-slot planning.

Each step must retain the current bridge schema and pass engine continuity,
serialization, offline-render, and phone-playback tests.

## Consequences

The graph becomes honest at the model level while the engine keeps its
allocation-free fused fast path. It adds a small compiler contract now, but
removes the need for new UI strip types to create bespoke DSP special cases.

## References

- [ADR-0003](ADR-0003-graph-based-engine.md)
- [Audio Graph](../architecture/audio_graph.md)
- [Device Model](../architecture/device_model.md)
- [Realtime Audio Rules](../architecture/realtime_audio_rules.md)
