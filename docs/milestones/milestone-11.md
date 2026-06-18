# Milestone 11 — Subtractive synth instrument

**10 stories** — see [roadmap](roadmap.md) · [story_manifest.yaml](../../tickets/story_manifest.yaml) · [tickets/milestone-11](../../tickets/milestone-11/README.md)

| US | Title | Status |
|----|-------|--------|
| US-11-01 | Subtractive synth engine MVP (8-voice poly, multimode filter) | Done |
| US-11-02 | Device picker, strip, save/load | Done |
| US-11-03 | Dual oscillators + unison | Done |
| US-11-04 | Noise + osc mix modes | Done |
| US-11-05 | Osc tab + waveform previews | Done |
| US-11-06 | Mix, Filter, Amp strip tabs | Done |
| US-11-07 | Fullscreen editor + test note | Done |
| US-11-08 | Factory presets + content library | Done |
| US-11-09 | Glide + velocity (no LFO) | Done |
| US-11-20 | M11 PO demo — subtractive synth end-to-end | Todo |

## Product locks

- **8-voice** polyphony (voice stealing)
- **Multimode filter:** LP12, HP12, band-pass, notch, comb
- **Classical hard sync** (osc 2 resets on osc 1 wrap)
- **`subtractive_synth`** alongside **`simple_oscillator`**
- **No dedicated synth LFO** in this milestone (project LFO mod matrix may target synth params)

## Implementation

Hand-written C++ in `engine_juce/` (see milestone-11 README for Faust comparison).
