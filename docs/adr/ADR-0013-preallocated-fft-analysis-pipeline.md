# ADR-0013: Preallocated FFT and Analysis Pipeline

## Status

Accepted and implemented for Spectrum Analyzer. A fixed 2,048-point Hann-window
FFT with a 512-sample hop owns its input ring, window, and complex workspace in
the processor. Callback boundaries no longer define analysis windows, and no
FFT work occurs while the analyzer meter is unsubscribed.

## Context

The Spectrum Analyzer currently evaluates 24 bins with a direct nested DFT and
per-sample trigonometric calls. Its frequency resolution changes with callback
size. Future convolution, spectral and frequency-split devices need a reusable
frequency-domain foundation with predictable realtime cost.

## Decision

Introduce a preallocated FFT runtime owned by each FFT-based processor:

```text
arbitrary callback chunks
  -> fixed input ring
  -> overlapping window
  -> preallocated FFT workspace
  -> bin/band reduction
  -> atomic or bounded-ring presentation output
```

- FFT size, hop size, window and latency are declared device configuration.
- Plans, windows, rings and workspaces are created off the audio thread.
- Callback boundaries do not define FFT windows.
- Analysis refresh is decimated independently from audio processing.
- The first migration replaces Spectrum Analyzer's direct DFT.
- Musical FFT devices declare and test latency through the processor graph.
- No FFT device allocates, locks, formats JSON or publishes Flutter objects from
  the callback.

A fixed radix-2 implementation is used initially so the Android engine does not
pull the full JUCE DSP module into every ABI. It is isolated behind the analysis
processor contract and can be replaced only after representative ARM benchmarks.

## Verification

- Known sine sweeps place energy in expected log-frequency bands at 44.1, 48 and
  96 kHz.
- Results are invariant to callback chunking within numeric tolerance.
- Window leakage, DC, Nyquist, silence and impulse behavior have tests.
- CPU and allocation baselines compare the old direct DFT with the FFT pipeline.
- Analyzer subscription off means no FFT work.

## Consequences

Analysis becomes cheaper and stable across device buffer settings. The engine
also gains infrastructure for later spectral devices, at the cost of explicit
window latency and more persistent per-device memory.
