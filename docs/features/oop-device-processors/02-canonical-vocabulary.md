# OOP Device Processors — Canonical Vocabulary

This document maps all 22 device processors to their canonical names, namespaces, file paths, and kinds. Developers and subagents must strictly adhere to these names and paths.

## Canonical Names & Mapping Table

The names and paths listed here are binding. Synonyms or custom folder paths must not be used.

| Device Node Kind | Class/Processor Name | Namespace | Header File Path (`engine_juce/include/...`) | Source File Path (`engine_juce/src/...`) | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `TrackGain` | `TrackGainProcessor` | `audioapp` | `audioapp/devices/processors/TrackGainProcessor.hpp` | `devices/processors/TrackGainProcessor.cpp` | Simple gain processor |
| `Oscillator` | `OscillatorProcessor` | `audioapp` | `audioapp/devices/processors/OscillatorProcessor.hpp` | `devices/processors/OscillatorProcessor.cpp` | Monophonic sine wave gen |
| `Sampler` | `SamplerProcessor` | `audioapp` | `audioapp/devices/processors/SamplerProcessor.hpp` | `devices/processors/SamplerProcessor.cpp` | Multi-region audio sampler |
| `SubtractiveSynth` | `SubtractiveSynthProcessor`| `audioapp` | `audioapp/devices/processors/SubtractiveSynthProcessor.hpp`| `devices/processors/SubtractiveSynthProcessor.cpp`| Polyphonic synth |
| `BassSynth` | `BassSynthProcessor` | `audioapp` | `audioapp/devices/processors/BassSynthProcessor.hpp` | `devices/processors/BassSynthProcessor.cpp` | Reuses SubtractiveSynth logic |
| `PhaseModSynth` | `PhaseModSynthProcessor` | `audioapp` | `audioapp/devices/processors/PhaseModSynthProcessor.hpp` | `devices/processors/PhaseModSynthProcessor.cpp` | FM style synthesizer |
| `KickGenerator` | `KickProcessor` | `audioapp` | `audioapp/devices/processors/KickProcessor.hpp` | `devices/processors/KickProcessor.cpp` | Kick drum synth |
| `SnareGenerator` | `SnareProcessor` | `audioapp` | `audioapp/devices/processors/SnareProcessor.hpp` | `devices/processors/SnareProcessor.cpp` | Snare drum synth |
| `ClapGenerator` | `ClapProcessor` | `audioapp` | `audioapp/devices/processors/ClapProcessor.hpp` | `devices/processors/ClapProcessor.cpp` | Clap generator synth |
| `CymbalGenerator` | `CymbalProcessor` | `audioapp` | `audioapp/devices/processors/CymbalProcessor.hpp` | `devices/processors/CymbalProcessor.cpp` | Hi-hat / Cymbal gen |
| `CrashGenerator` | `CrashProcessor` | `audioapp` | `audioapp/devices/processors/CrashProcessor.hpp` | `devices/processors/CrashProcessor.cpp` | Crash cymbal generator |
| `Gate` | `GateProcessor` | `audioapp` | `audioapp/devices/processors/GateProcessor.hpp` | `devices/processors/GateProcessor.cpp` | Dynamics noise gate |
| `Compressor` | `CompressorProcessor` | `audioapp` | `audioapp/devices/processors/CompressorProcessor.hpp` | `devices/processors/CompressorProcessor.cpp` | Dynamics compressor |
| `Expander` | `ExpanderProcessor` | `audioapp` | `audioapp/devices/processors/ExpanderProcessor.hpp` | `devices/processors/ExpanderProcessor.cpp` | Dynamics expander |
| `Limiter` | `LimiterProcessor` | `audioapp` | `audioapp/devices/processors/LimiterProcessor.hpp` | `devices/processors/LimiterProcessor.cpp` | Dynamics peak limiter |
| `Delay` | `DelayProcessor` | `audioapp` | `audioapp/devices/processors/DelayProcessor.hpp` | `devices/processors/DelayProcessor.cpp` | Time-based delay line |
| `Reverb` | `ReverbProcessor` | `audioapp` | `audioapp/devices/processors/ReverbProcessor.hpp` | `devices/processors/ReverbProcessor.cpp` | Multi-tap reverb network |
| `Chorus` | `ChorusProcessor` | `audioapp` | `audioapp/devices/processors/ChorusProcessor.hpp` | `devices/processors/ChorusProcessor.cpp` | Time-based chorus FX |
| `Phaser` | `PhaserProcessor` | `audioapp` | `audioapp/devices/processors/PhaserProcessor.hpp` | `devices/processors/PhaserProcessor.cpp` | Time-based phase modulator |
| `Filter` | `FilterProcessor` | `audioapp` | `audioapp/devices/processors/FilterProcessor.hpp` | `devices/processors/FilterProcessor.cpp` | Lowpass/highpass filter |
| `FourBandEq` | `FourBandEqProcessor` | `audioapp` | `audioapp/devices/processors/FourBandEqProcessor.hpp` | `devices/processors/FourBandEqProcessor.cpp` | Four-band parametric EQ |
| `FrequencyShifter` | `FrequencyShifterProcessor` | `audioapp` | `audioapp/devices/processors/FrequencyShifterProcessor.hpp`| `devices/processors/FrequencyShifterProcessor.cpp`| SSB frequency shifter |

## Key Concepts

- **Real-time Safe**: Execution path has deterministic time-bounds. Zero lock contention, zero system calls, zero dynamic memory.
- **Stateless DSP**: All mutable state resides in separate runtime/state buffers managed at the device-chain or track level.
- **Automation / Modulation Sub-Blocking**: Slicing the frames to process into smaller sub-blocks (default 64 frames) to apply fast-changing parameter updates without audible stepping.
