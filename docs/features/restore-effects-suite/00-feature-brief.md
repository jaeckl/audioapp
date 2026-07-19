# Restore Effects Suite — Feature Brief

> **STATUS: IN PROGRESS**

## User-Visible Goal

Add five compact **Restore Effects** devices for audio cleanup on the track device chain:

1. **DC Offset** — remove DC / subsonic (Mean or HPF)
2. **De-Crackler** — click / crackle repair
3. **De-Esser** — sibilance control with Listen
4. **De-Hum** — 50/60 Hz + harmonics notches
5. **De-Noise** — light spectral noise gate

Each device is a stereo in-place audio FX with a compact single-page strip UI (vertical knobs + optional mode combo) and project JSON persistence. Output chrome: empty cap for DC/Crackler; bottom-aligned Gain+Pan for De-Esser/De-Hum/De-Noise.

## Non-Goals

- De-Clip, Breath Control, De-Reverb
- ML denoise (RNNoise / Speex)
- Live GR / spectrum metering bridge (v1 previews are param-driven)
- Sidechain from other tracks
- Multi-tab / fullscreen editors
- IAP unlock gating

## Device Category

**Restore Effects** — own section in the device picker.

## Existing Code to Reuse

- Mood FX pattern (`TremoloDeviceType` / `TremoloProcessor` / `mood_fx_panels.dart`)
- `CompactFxPage` / `compactFxKnobGridRow`
- Insert chrome: `StereoGainPanPanel` where makeup gain helps; else no output rail
- `juce::dsp` IIR / FFT
- Feature suite docs pattern from `fx-frequency-suite/`

## Type IDs

| typeId | Name | Accent |
|--------|------|--------|
| `dc_offset` | DC Offset | `#7DD3C0` |
| `de_crackler` | De-Crackler | `#F0B429` |
| `de_esser` | De-Esser | `#C084FC` |
| `de_hum` | De-Hum | `#60A5FA` |
| `de_noise` | De-Noise | `#94A3B8` |
