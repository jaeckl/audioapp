# ADR-0010: Runtime Graph Taps and Compiled Parameter Control

## Status

Accepted — graph taps are implemented and hardened; compiled parameter control
follows in independently testable phases.

## Context

ADR-0009 reserved logical output-adapter ports for meter, analyzer, and recorder
taps, but the engine only carried a `GraphTapKind` tag on routed edges. That tag
was not executed, could not represent multiple observers, and disappeared when
an output had no routing receiver.

Live parameter processing is a separate concern. Manual changes currently queue
whole playback nodes, while automation and modulation repeatedly scan target
lists. Parameter smoothing also differs by processor. Conflating these control
flows with audio observation would make both APIs misleading.

## Decision: graph taps

A graph tap is a transient observer attached to the audio output port of a
logical device Output Adapter:

```text
Input Adapter -> Device DSP -> Output Adapter -> [tap observers] -> next node
```

Tap definitions target the stable Output Adapter node ID. The control thread
compiles definitions into a fixed-size tap array in the immutable
`ProcessorGraphSnapshot`. The audio thread compares numeric node IDs only; it
does not resolve strings, allocate, lock, edit topology, or build JSON.

Taps are independent of routing edges:

- they do not create receivers or dependencies;
- they do not consume route-buffer slots or change latency compensation;
- multiple tap kinds may observe the same output;
- they work when the output has no routing receiver;
- they preserve Input/DSP/Output fusion.

The initial target contract is device Output Adapter, stereo audio port zero.
Track, group, master, MIDI, side-chain, and arbitrary internal port taps require
their own explicit stable port identities and are deferred.

### Runtime kinds

| Kind | Audio-thread work | Control-thread readback |
|---|---|---|
| Meter | calculate and atomically publish peak/RMS | read latest coherent values |
| Analyzer | copy samples into a bounded SPSC ring | consume the newest window and calculate waveform/spectrum |
| Recorder | copy stereo samples into a bounded SPSC ring | drain bounded, ordered PCM chunks |

Meter state is latest-value state and cannot overflow. Analyzer overflow drops
new samples and reports a discontinuity. Recorder overflow latches an overflow
flag and never overwrites unread audio. No tap may block the callback.

Runtime slots carry generations. Removing a tap invalidates its generation
before a slot can be reused, so a callback holding an older immutable graph
cannot publish into a new tap. Tap definitions, IDs, buffers, and captured data
are session runtime state: they are not project JSON, undo state, presets, or
processor runtime serialization.

Nested Chain and Drum Machine orchestrators receive the same immutable tap plan
and runtime bank. Frozen device graphs do not execute, so their device taps do
not advance while frozen.

## API contract

The bridge exposes:

- `createGraphTap(deviceId, kind, capacityFrames)` -> stable session tap ID;
- `removeGraphTap(tapId)`;
- `readGraphTap(tapId, maxFrames)`.

Kinds are `meter`, `analyzer`, and `recorder`. Recorder/analyzer readback is
bounded; unbounded PCM JSON is forbidden. A later native typed-data or file
writer may consume the same ring without changing the compiled graph contract.

## Follow-up: compiled parameter control

Graph taps do not carry parameter values. A separate compiled control plan will
share stable node IDs and be delivered in these phases:

1. Add callback timing, command-flood, automation-accuracy, and modulation-
   continuity regression tests.
2. Compile `(node ID, parameter ID)` into dense handles and direct processor or
   adapter bindings.
3. Replace full-node/string gesture commands with compact per-parameter
   mailboxes and block-boundary consumption.
4. Compile automation clips and modulation edges into target-specific spans;
   evaluate each source once and fan it out.
5. Define one mandatory rate/smoothing policy for every parameter:
   `Discrete`, `Block`, `Smoothed`, `ControlRate`, or `AudioRate`.
6. Combine base value, automation, and modulation once per target, then produce
   only the constant, ramp, control block, or sample vector required by that
   policy.
7. Migrate every processor to the common parameter stream contract. Device-
   local ad-hoc smoothing is removed only after equivalence tests cover the
   migrated parameter.
8. Publish effective parameter values through a separate fixed atomic monitor
   array for coalesced Flutter knob animation.

Phase 1 is complete. The regression harness overrides allocation entry points
while the simulated callback runs, floods one realtime parameter command per
block, enables all 16 tap slots, and checks both zero allocations and the real
128-frame deadline. It also covers steady-state callbacks without commands.

The first slice of phases 2 and 3 is complete for common strip controls and every device kind
already covered by the normalized automation evaluator. Control-thread strings
resolve to a stable processor-node ID plus encoded parameter ID, then enter a
separate compact SPSC mailbox. The callback coalesces by numeric handle and
updates top-level or nested Chain/Drum processors without string comparison or
whole-node copying. Discrete parameters and device kinds missing a normalized
evaluator deliberately remain on the prior block-boundary fallback until phase
7 supplies their typed policy; fallback commands drain before compact values so
an older node snapshot cannot overwrite a newer gesture.

Consistency is part of the contract: every automatable or modulatable parameter
must declare its rate and smoothing behavior, and tests must reject missing
declarations. Discrete parameters never interpolate; continuous manual changes
must not step unless explicitly declared block-rate; automation and modulation
must use the same final smoothing/rate stage.

## Verification gates

Each phase requires targeted engine tests, offline-render equivalence where
applicable, callback allocation/deadline checks, Android build, phone deploy,
and a separate commit. Tap tests cover no-receiver execution, post-output
semantics, bypass, multiple observers, nested devices, generation-safe removal,
bit-exact recorder ordering, bounded overflow, and no project serialization.

## Consequences

The graph gains real observation ports without turning observers into DSP nodes
or weakening fusion. Parameter work remains an honest control-plane compiler
problem and gains an explicit path to uniform artifact-free behavior.

## References

- [ADR-0003](ADR-0003-graph-based-engine.md)
- [ADR-0009](ADR-0009-device-subgraphs-and-compiled-execution.md)
- [Realtime Audio Rules](../architecture/realtime_audio_rules.md)
