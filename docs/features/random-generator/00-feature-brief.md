# Feature Brief: Random Generator Modulator

## User-Visible Goal

Add a **Random Generator** modulator type (sample & hold style) to the DAW's modulation system. Users can add a Random Generator tile to the modulation grid, configure its rate and smoothing in the properties panel, and see/hear it modulate device parameters with stepped random values.

## Non-Goals

- No audio-rate random modulation (current rate range is modulation-rate, i.e., rhythmic subdivisions)
- No per-voice random seeds (single global random generator per modulator instance)
- No probability-based pattern generation
- No multi-segment or breakpoint-based random
- No visualization of the random sequence in a piano-roll-style editor
- No "smooth random" as a completely separate type (smoothing is a parameter of the random generator)

## Target User Workflow

1. User taps "+" in the modulation grid → bottom sheet shows "LFO", "Envelope", **"Random"**
2. User taps "Random" → a Random Generator modulator is created with default parameters
3. A tile appears in the modulation grid showing the stepped/smoothed waveform preview
4. User taps the tile → properties panel opens showing:
   - Waveform preview (static or live with playhead)
   - **Rate** knob (0–1)
   - **Smoothing** knob (0–1, 0=instant steps, 1=fully smoothed)
   - **Retrigger** segment bar (Free / Sync / On Note)
   - **Polarity** toggle (Bipolar / Unipolar)
5. User adjusts parameters → values are sent to the engine via bridge
6. Random values modulate assigned device parameters in realtime
7. Project save/load preserves the Random Generator modulator and its parameters