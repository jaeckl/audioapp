# OOP Device Processors — Data Contracts

This document pins the data contracts, memory layouts, state types, and parameter conversion mappings between the central orchestrator and the individual modular device processors.

## State and Preallocated Memory Ownership

To ensure **zero-allocations** on the audio thread:
- The modular processors **never** own the state variables or buffers.
- All state arrays are preallocated, owned by the track or engine host, and passed down to `processDeviceNode` as raw arrays or pointers.
- Processors must obtain their specific slice using `deviceIndex` (e.g. `dynamicsRuntimes[deviceIndex]`).
- If a pointer is `nullptr` (which happens in unit tests or when certain tracks don't allocate certain effect slots), the processor must fall back to a thread-local or stack-allocated temporary state struct (this matches the behavior in the original switch-case).

## Scratchpad Memory Mapping

The thread-local `DeviceChainScratch&` is passed to every processor to allow:
- Large temporary float arrays (e.g., `scratch.scratch` or `scratch.tempStereoL`/`tempStereoR`) for sub-blocking, synthesizer region computations, and intermediate panning.
- Preallocated region arrays to track active polyphonic MIDI notes (e.g., `scratch.kickRegions`, `scratch.clapRegions`, etc.) up to `kMaxInstrumentRegions = 32`.

## Parameters & Variant Mapping

Each device processor handles its own parameters by unpacking them from the `DeviceVariantParams modulatedParams` using `std::get<T>`.

### Mapping Table: Device to Parameters Struct

| Processor | Expected Variant Type `T` | Local Helper Logic |
| :--- | :--- | :--- |
| `OscillatorProcessor` | `OscillatorParams` | Uses `addSineBlock` with sub-blocking or full-block rendering |
| `SamplerProcessor` | `SamplerParams` | Compiles active MIDI notes into regions and runs `mixSamplerMidiNotesBlock` |
| `SubtractiveSynthProcessor` | `SubtractiveSynthParams` | Evaluates dynamic automation/modulation via `mixSubtractiveMidiNotesBlock` |
| `BassSynthProcessor` | `SubtractiveSynthParams` | Uses subtractive synth parameters and runtimes |
| `PhaseModSynthProcessor` | `PhaseModSynthParams` | Evaluates FM automation/modulation via `mixPhaseModMidiNotesBlock` |
| `KickProcessor` | `KickGeneratorParams` | Fills `kickRegions` and calls `mixKickMidiNotesBlock` |
| `SnareProcessor` | `SnareGeneratorParams` | Fills `snareRegions` and calls `mixSnareMidiNotesBlock` |
| `ClapProcessor` | `ClapGeneratorParams` | Fills `clapRegions` and calls `mixClapMidiNotesBlock` |
| `CymbalProcessor` | `CymbalGeneratorParams` | Fills `cymbalRegions` and calls `mixCymbalMidiNotesBlockStereo` |
| `CrashProcessor` | `CrashGeneratorParams` | Fills `crashRegions` and calls `mixCrashMidiNotesBlockStereo` |
| `GateProcessor` | `GateParams` | Applies input gain, runs `processGateStereoBlock`, publishes meters |
| `CompressorProcessor` | `CompressorParams` | Applies input gain, runs `processCompressorStereoBlock`, publishes meters |
| `ExpanderProcessor` | `ExpanderParams` | Applies input gain, runs `processExpanderStereoBlock`, publishes meters |
| `LimiterProcessor` | `LimiterParams` | Applies input gain, runs `processLimiterStereoBlock`, publishes meters |
| `DelayProcessor` | `DelayParamsPlayback` | Runs delay feedback/mix line, increments `writeIndex`, publishes meters |
| `ReverbProcessor` | `ReverbParamsPlayback` | Multi-tap allpass network, diffusion, updates phaser states, publishes meters |
| `ChorusProcessor` | `ChorusParamsPlayback` | Computes LFO phase L/R, interpolates delay line read index |
| `PhaserProcessor` | `PhaserParamsPlayback` | Updates phaser phase, runs 4-stage allpass feedback loop |
| `FilterProcessor` | `FilterParams` | Runs `processFilterStereoBlock` |
| `FourBandEqProcessor` | `FourBandEqParams` | Runs `processFourBandEqStereoBlock` |
| `FrequencyShifterProcessor`| `FrequencyShifterParams` | Runs `processFrequencyShifterStereoBlock` |
| `TrackGainProcessor` | None | Applies stereo gain via `scratch.perFrameGain` array multiplication |

## Data Flow Pipeline

1. **Orchestrator** evaluates common automation and LFO envelopes for gain and pan, storing them in `scratch.perFrameGain` and `scratch.perFramePan`.
2. **Orchestrator** evaluates device-specific non-subblocked parameters (or flags sub-blocking).
3. **Orchestrator** calls `processDeviceNode`.
4. **`processDeviceNode`** inspects `node.kind` and calls the appropriate static `process` function on the designated modular class.
5. **Modular Processor** unpacks its parameters, applies optional sub-blocking, coordinates with the lower-level DSP functions (e.g. `processCompressorStereoBlock` or `mixSamplerMidiNotesBlock`), applies common pan/gain, and publishes feedback to UI meters.
