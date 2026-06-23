# Device Model

## Overview

Devices are **internal built-in modules**, not external VST/AU/CLAP plugins.

## Device categories

- **Instrument** — produces audio from MIDI (oscillator, sampler)
- **Audio effect** — transforms audio (gain, pan, filter)
- **MIDI effect** — transforms MIDI (future)
- **Utility** — routing, metering (future)
- **Send/receive** — internal bus routing (minimal, later)

## Device interface (conceptual)

Each device provides:

- Stable `device_type` and instance `device_id`
- Versioned state blob for serialization
- Parameter descriptors (id, name, min, max, default, unit)
- Realtime-safe `processBlock` (or MIDI + audio variants)
- UI metadata (display name, editor layout hints)

## MVP devices

| Device | Role | Milestone |
|--------|------|-----------|
| Simple Oscillator | Instrument | 01–02 |
| Gain | Effect | 08 |
| Pan | Effect | 08 |
| Simple Filter | Effect | 08 |
| Simple Sampler | Instrument | 06 |
| Subtractive Synth | Instrument | 11 |
| Kick Generator | Instrument | 13 |

## Parameters

- Identified by stable `parameter_id` within the device instance
- Values set via bridge commands; read from snapshot for UI
- Automation targets reference `parameter_id` (architecture from start)

## Strip chrome (M15)

Per-device **input** and **output** columns replace the universal Pan+Gain rail for some families. See:

- [ADR-0008](../adr/ADR-0008-device-strip-ui-chrome.md)
- [device_strip_chrome.md](../design/device_strip_chrome.md)

Slot order: `[Tool][Mod?][Lfo?][Input?][Card][Output?]`. Engine `DeviceSlot.gain` / `pan` remain universal; UI chooses visibility.

**Model variants** (e.g. kick 808 vs analog) use a **parameter branch in DSP** (`kickModel`), not a new device type in the picker.

## Serialization

Device state is stored in `project.json` under the track's device chain entry:

```json
{
  "id": "dev-001",
  "type": "simple_oscillator",
  "version": 1,
  "parameters": {
    "frequency": 440.0,
    "waveform": "sine"
  }
}
```

## Realtime rules

Device DSP must follow [realtime_audio_rules.md](realtime_audio_rules.md). No allocations in `processBlock`.

## M12 implementation (planned)

Control-thread device classes (`OscillatorDeviceType`, `SamplerDeviceType`, `TrackGainDeviceType`, `SubtractiveSynthDeviceType`) implement `IDeviceType` in `engine_juce/include/audioapp/devices/` — see [project_engine_refactor.md](project_engine_refactor.md) and [ADR-0007](../adr/ADR-0007-project-engine-decomposition.md). Playback remains variant-based (`DeviceNodePlayback`, US-10-01).

> **Suffix reference:** See [Engine naming conventions](engine-naming-conventions.md) for a
> complete map of `*Model`, `*Params`, `*Runtime`, `*Processor`, `*Algorithm`, and
> `*DeviceType` roles.
