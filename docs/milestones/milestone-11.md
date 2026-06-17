# Milestone 11 — Subtractive synth instrument

**10 stories** — see [roadmap](roadmap.md) · [story_manifest.yaml](../../tickets/story_manifest.yaml) · [tickets/milestone-11](../../tickets/milestone-11/README.md)

| US | Title | Status |
|----|-------|--------|
| US-11-01 | Subtractive synth engine MVP (8-voice poly, LP12) | Todo |
| US-11-02 | Device picker, strip, save/load | Todo |
| US-11-03 | Dual oscillators + unison | Todo |
| US-11-04 | Noise + osc mix modes | Todo |
| US-11-05 | Osc tab + waveform previews | Todo |
| US-11-06 | Mix, Filter, Amp strip tabs | Todo |
| US-11-07 | Fullscreen editor + test note | Todo |
| US-11-08 | Factory presets + content library | Todo |
| US-11-09 | Glide + velocity (no LFO) | Todo |
| US-11-20 | M11 PO demo | Todo |

## Product locks

- **8-voice** polyphony (voice stealing)
- **LP12** filter only
- **`subtractive_synth`** alongside **`simple_oscillator`**
- **No LFO** in this milestone

## Implementation

Hand-written C++ in `engine_juce/` (see milestone-11 README for Faust comparison).
