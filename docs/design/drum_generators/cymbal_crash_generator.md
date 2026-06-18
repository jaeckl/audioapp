# Cymbal / crash generator — design spec

**Type ID:** `cymbal_generator`  
**Status:** US-13-04 (planned)  
**Accent:** `#9AD4E8` (cyan)

## Sound model

**Metallic noise** via stacked inharmonic sines or filtered noise:

1. **Metal** — inharmonic partial cluster (6–12 partials) or HP/BP noise
2. **Crash** — fast attack, long exponential decay (0.4–3 s)
3. **Brightness** — high-frequency emphasis
4. **Choke** — optional early cutoff (future: note-off choking)

Variants in UI: **Hi-hat** (short) vs **Crash** (long) preset morph on same engine.

## Parameters (planned)

| ID | UI label | Tab |
|----|----------|-----|
| `cymbalMetal` | Metal | Metal |
| `cymbalBrightness` | Bright | Metal |
| `cymbalDecay` | Decay | Decay |
| `cymbalChoke` | Choke | Decay |
| `cymbalVelocity` | Velocity | Amp |

## Strip tabs

**Metal** · **Decay** · **Amp**

Preview: shimmering decay tail (spectrogram-style gradient).

## UX

Picker subtitle: `Metallic noise · hat or crash`.  
Long decay may use **per-voice choke** on note-off in v2.

## CPU note

Most expensive generator in family — cap partial count at 8 for mobile RT budget.
