# ADR-0011: Common-Control Execution Modes and SIMD Kernels

## Status

Accepted — phase 1 implements effects, routing/container outputs, and Track
Gain. Instrument kernels remain on the compatible dynamic-array adapter until
they are migrated and compared device by device.

## Context

Every fused device subgraph currently prepares 4096-capable per-frame gain and
pan arrays on every callback. Most projects do not automate or modulate most
common controls, so unchanged values pay the same array writes and lookups as a
sample-accurate target. Manual changes must remain click-free, but only the
callback containing the change needs a ramp.

Many independent buffer operations are scalar even though JUCE already selects
the appropriate SIMD implementation for the target CPU.

## Decision

The compiled parameter binding records whether common gain and pan have an
automation or modulation source. The audio thread represents each control for
the current block as:

| Mode | Data | Use |
|---|---|---|
| `Constant` | one value | unchanged manual target |
| `Ramp` | start and end | one callback after a manual target change |
| `Dynamic` | pointer to preallocated per-frame values | automation or modulation |

Mode selection is bounded, lock-free, and allocation-free. It is execution-plan
metadata, not native-code generation or JIT compilation.

The constant path may precompute channel coefficients once and skip neutral
operations. The ramp path reaches the target on the final frame and then becomes
constant. The dynamic path retains the established order:

```text
manual base/ramp -> automation -> modulation -> DSP/presentation monitor
```

Small platform helpers use ARM NEON on mobile, SSE on supported desktop builds,
and a scalar tail/fallback for independent, contiguous kernels:

- scalar and per-frame gain multiplication;
- stable dry/wet mixing;
- track/channel scalar gain;
- later, graph summing, clearing, width and meter reductions where benchmarks
  demonstrate a benefit.

No SIMD conversion is permitted for recursive or feedback DSP merely to satisfy
this ADR. Oscillators, IIR filters and feedback delays require algorithm-specific
analysis.

## Migration

1. Effects, routing/container output adapters and Track Gain use the descriptor.
2. Instruments continue receiving materialized arrays to preserve their current
   per-note and sample-accurate behavior.
3. Each instrument family migrates to scalar/ramp/dynamic inputs with an audio
   equivalence test before its legacy materialization is removed.
4. Remove the compatibility materialization only after every instrument is in
   the device matrix from ADR-0014.

## Correctness gates

- Constant, ramp and dynamic modes produce finite samples for arbitrary positive
  partial blocks.
- A manual change has no discontinuity at a callback boundary and reaches the
  exact target at the final frame.
- Automation and modulation keep sample-accurate arrays.
- Effective-value monitoring reports the same post-policy value used by DSP.
- Neutral gain/full-wet paths do not touch scratch buffers unnecessarily.

## Consequences

Static projects reduce per-device memory traffic, branches and pan coefficient
work. Live knob changes remain smoothed. The temporary compatibility path means
instrument-heavy projects receive only part of the benefit until phase 2, but it
substantially lowers regression risk.
