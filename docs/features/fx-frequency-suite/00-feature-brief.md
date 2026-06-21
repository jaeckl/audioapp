# Frequency FX Suite — Feature Brief

## User-Visible Goal

Add three new "Frequency Effects" devices to the DAW's device chain:

1. **Filter Device** — multimode resonant filter (LP/HP/BP/Notch) with cutoff and resonance knobs, filter-curve preview graph, dynamics-style input/output panels
2. **4-Band EQ Device** — visual parametric EQ with 4 adjustable bands (low shelf, low-mid peak, high-mid peak, high shelf), graphical EQ-curve display
3. **Frequency Shifter Device** — shifts the entire frequency spectrum up or down, dynamics-style input/output panels

All three are stereo effects that process audio in-place on the audio thread, following the dynamics-FX pattern (knob grid + preview graph in the card body, DynamicsInputPanel/DynamicsOutputPanel in the chrome).

## Non-Goals

- No MIDI input or note-triggered behavior (these are always-on FX)
- No side-chain support (for now)
- No automation of filter cutoff sweep (follows existing automation pattern, no custom handling)
- No preset management (follows existing JSON serialization pattern)
- No live-instrument mode (return false from buildLiveInstrument)

## Device Category

Introduce a new device category **Frequency FX** — distinct from "Instruments", "Effects" (dynamics), and "Time-Based Effects". Displayed as its own section in the device picker sheet.

## Existing Code to Reuse

- `SamplerFilter.hpp` — `cookSamplerBiquad()` and `processBiquadSample()` for biquad LP/HP/BP/Notch modes (modes 0-3)
- `DynamicsProcessor.hpp` — pattern for runtime structs and stereo-block processing functions
- Dynamics FX panel pattern in `dynamics_fx_panels.dart` — `_dynamicsSinglePage()`, `_knobGridRow()`, `_DynamicsKnob`
- `DeviceStripChrome` routing — `_dynamicsTypes` set determines input/output panel routing
- JUCE `juce::dsp` module — for EQ shelf filters and frequency shifter