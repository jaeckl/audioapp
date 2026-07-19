# Architecture: Restore Effects Suite

## Layers

```
Flutter Restore FX panels
  → MethodChannel setDeviceParameter / addDeviceToTrack
Native bridge (control)
  → DeviceRegistry → *DeviceType (Params / JSON / playback node)
Audio thread
  → *Processor::process() on stereo block
```

## Engine layout

- Params: `engine_juce/include/audioapp/effects/*Params.hpp` (restore devices)
- DeviceType: `engine_juce/include|src/effects/*DeviceType.*`
- Processor: `engine_juce/include|src/devices/processors/*Processor.*`
- Registration: `registerRestoreEffects()` from `DeviceRegistry::createBuiltIn()`

## DSP notes

| Device | Algorithm |
|--------|-----------|
| DC Offset | Running mean subtract (Mean) or 1-pole HPF (HPF); Amount = wet blend |
| De-Crackler | High-pass derivative peak detect → short linear interpolate |
| De-Esser | Band-pass envelope → downward gain on band / Listen = band solo |
| De-Hum | Cascaded notches at f0·n (f0 = 50/60) |
| De-Noise | Short FFT magnitude gate + OLA (light spectral gate) |

All RT-safe: no heap in `process()`, fixed buffers on processor.
