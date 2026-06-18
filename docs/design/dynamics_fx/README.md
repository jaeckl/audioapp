# Dynamics FX — design overview

**Milestone:** M14  
**Category:** Audio effects (in-chain, post-instrument, pre–track gain)

## Architecture

Dynamics devices **transform the track stereo buffer in place** (same pattern as `track_gain`, unlike instruments that render from MIDI).

```
[Instrument(s)] → [Gate] → [Compressor] → … → [track_gain] → master
```

Shared DSP lives in `engine_juce/src/DynamicsProcessor.cpp`:

- Stereo-linked peak detector
- Attack / release envelope follower
- Per-mode gain computer (gate, expander, compressor, limiter)
- RT-safe: no heap, no locks; state in `DynamicsRuntime` per device index

## Devices

| Type ID | UI name | Accent | Tabs |
|---------|---------|--------|------|
| `gate` | Gate | `#6EC9A8` | Detect · Time · Range |
| `compressor` | Compressor | `#E8A54B` | Comp · Time · Gain |
| `expander` | Expander | `#9AD4E8` | Expand · Time · Range |
| `limiter` | Limiter | `#E85D4B` | Ceiling · Time · Gain |

## Screenshots

UI captures live in [`screenshots/`](screenshots/). Regenerate:

```bash
cd app_flutter && flutter build web -t lib/dynamics_fx_screenshot_main.dart -o build/web_screenshot
python tools/capture_dynamics_screenshots.py
```

## Strip chrome (M15)

Dynamics devices will gain **DynamicsInputPanel** (left of card) and **DynamicsOutputPanel** (right). See [device_strip_chrome.md](../device_strip_chrome.md) and US-15-04.

## Parameter conventions

All knobs normalized **0…1** (mapped to useful ranges in C++), automatable, serialized in `project.json`.

## Implementation order

1. **US-14-01** Gate — validates in-place FX path + envelope
2. **US-14-02** Compressor — ratio + knee + makeup
3. **US-14-03** Expander — downward expand below threshold
4. **US-14-04** Limiter — brick-wall ceiling on track bus

Master bus limiter (US-08-14) remains separate — post-sum, not a chain device.
