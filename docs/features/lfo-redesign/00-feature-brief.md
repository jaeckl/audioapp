# Feature Brief: LFO Modulator Redesign

## User-visible goal

Replace the current scrollable LFO properties panel (chips + knobs in a `SingleChildScrollView`) with a polished pin-to-bottom layout matching the envelope panel pattern: header -> Expanded waveform preview -> retrigger mode bar -> polarity chips -> knob row (Rate, Phase, Warp, Spread).

## Non-goals

- Do NOT change the C++ engine's `LfoParams` struct in a breaking way
- Do NOT remove `polarity: 2` from engine serialization
- Do NOT modify `LfoModulator::evaluateWaveform()` or the audio-thread evaluation path
- Do NOT add an animated playhead dot to the LFO preview (the grid tile already shows it)
- Do NOT touch envelope-related fields (`attack`, `decay`, `sustain`, `release`) in `LfoParams`
- Do NOT change the modulation grid tile (`ModulatorPreview`, `_ModulatorTile`)

## Core concepts added

| Concept | Description |
|---------|-------------|
| **Morph (Warp)** | Continuous 0..1 blend between the 5 classic waveforms (sine, tri, saw, square, ramp) |
| **Spread** | Pulse-width / skew control: 0.5 = symmetric, <0.5 skews down, >0.5 skews up |
| **Analog mode** | Fixed digital-vs-analog toggle: DG=full morph/spread handles, AN=fixed values (morph=0, spread=0.5) |
| **Polarity (reduced)** | 2 values instead of 3: 0=bipolar(±), 1=unipolar-pos(+) |