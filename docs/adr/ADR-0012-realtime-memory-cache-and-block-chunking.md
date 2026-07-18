# ADR-0012: Realtime Memory, Cache Locality, and Block Chunking

## Status

Accepted. Predictable callback allocation is implemented and audited at maximum
modulation/tap capacity. Arbitrary block chunking and cache-layout decisions
remain subsequent phases.

## Context

The callback uses fixed scratch for most DSP, but modulation vectors can grow in
the callback. Several public render paths clamp work to 4096 frames and silence
or ignore the remainder. Fixed worst-case graph and track banks are predictable
but create a large hot-thread memory footprint.

`ProcessorArena` gives snapshot-safe processor lifetime, but its separately
allocated 64 KiB slots are not a contiguous cache-local arena.

## Decision

### Predictable allocation

- Runtime capacity is calculated and allocated on the control thread before a
  snapshot becomes active.
- No audio callback may call `reserve`, capacity-growing `resize`, `new`, delete,
  or a potentially allocating container operation.
- Snapshot publication includes the required LFO, per-note, graph-edge and tap
  capacities. Unsupported topology is rejected during compilation rather than
  degraded in the callback.
- The realtime allocation audit runs both warmed steady state and capacity-change
  scenarios.

### Block chunking

The engine accepts arbitrary positive callback sizes. A callback larger than the
internal quantum is processed as ordered chunks no larger than the scratch
capacity. Each chunk advances:

- playhead and loop position;
- automation beat evaluation;
- LFO/per-note clocks;
- delay, feedback and tail state;
- graph-tap sequence positions.

The final short chunk is processed normally. It is never padded into audible
state and never discarded. FFT devices use their own accumulation windows and
must not require callback sizes to be powers of two.

### Cache policy

Optimization follows measured misses and bandwidth. First reduce unnecessary
buffer clears/copies and allocate only compiled graph buffer slots. Then split
hot execution metadata from cold model/lifetime data. Processor storage layout
is changed only if profiling shows processor indirection to be material.

Graph parallelism is not a substitute for locality. If later introduced, it
uses persistent realtime workers, independent heavy branches and a measured work
threshold; no callback may create threads or wait on UI/control work.

## Verification

- Allocation counter remains zero during first callback after every legal
  non-structural update and after activating a maximum-capacity snapshot.
- Rendering the same project with chunk sequences `4096`, `1024`, `513/511`, and
  randomized positive tails is equivalent within the declared DSP tolerance.
- Requests above 4096 produce the complete frame count without a silent suffix.
- Sanitizer/debug tests cover one-frame blocks and block boundaries at note,
  clip, loop, automation and feedback transitions.

## Consequences

Memory requirements become explicit and failures move to compilation/control
time. Chunking adds orchestration complexity, but removes a correctness trap and
decouples platform callback behavior from internal DSP capacity.
