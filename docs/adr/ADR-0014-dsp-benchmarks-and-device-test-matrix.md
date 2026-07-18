# ADR-0014: DSP Benchmarks and Device Test Matrix

## Status

Accepted. The informational benchmark harness is implemented; the registry-wide
correctness matrix remains the next phase.

## Context

The repository has many valuable device-specific tests and one callback deadline
and allocation audit. It does not provide comparable per-device performance
baselines or systematically run every device across sample rates, callback sizes,
partial blocks, parameter extremes and lifecycle transitions.

Without those measurements, SIMD, cache and parallel changes can regress sound,
tails or lower-end mobile performance while improving a synthetic desktop case.

## Decision

Create two separate suites.

### DSP benchmark suite

Benchmarks are informational artifacts, not fragile pass/fail unit tests. They
record median, p95 and maximum callback time plus realtime factor for:

- every device with representative presets;
- constant, ramp, automated and modulated control states;
- serial chains and independent graph branches;
- subscribed and unsubscribed meters/analyzers;
- 44.1/48/96 kHz and 512/1024/2048/4096 frame blocks;
- cold snapshot activation and warmed steady state.

Results include build type, CPU/ABI, compiler and commit. Mobile ARM results are
authoritative for product decisions. Desktop results remain useful for change
detection.

The `audioapp_dsp_benchmarks` target emits schema-versioned JSON on stdout. Its
default run covers the full sample-rate/block-size grid; `--quick` is the smoke
mode used while changing the harness. Filters such as `--scenario`,
`--sample-rate`, and `--block-size` support focused comparisons. Timings are
never unit-test pass/fail thresholds.

### Device correctness matrix

The registry enumerates every built-in device through a shared contract. Each
device is exercised for:

- silence and representative signal/note input;
- defaults, minimum, maximum and non-finite/invalid-input rejection;
- one-frame, odd, normal, maximum and chunked-oversize blocks;
- supported sample rates;
- bypass, reset, seek, loop, deletion and tail completion;
- constant manual values, live ramps, automation, modulation and combined
  automation/modulation;
- finite output, bounds safety, deterministic reset where applicable, and zero
  callback allocations.

Golden audio is reserved for stable high-value scenarios. Most tests assert
invariants, spectral/level ranges and chunk equivalence so intentional sonic
evolution does not create meaningless binary churn.

## Optimization sequence

The accepted order is:

1. common-control Constant/Ramp/Dynamic modes;
2. measured SIMD kernels;
3. callback allocation removal;
4. benchmark harness and baseline capture;
5. complete device correctness matrix;
6. correct arbitrary/oversize block chunking;
7. preallocated FFT pipeline;
8. cache/storage changes only after profiling.

Items 1 and 2 begin under ADR-0011. The benchmark and matrix expand before
items 6–8 so subsequent changes have regression evidence.

## Consequences

Performance work becomes comparable and device coverage becomes systematic.
The suite increases CI/runtime cost, so fast smoke subsets run per change while
full matrices and mobile benchmarks run on scheduled or release workflows.
