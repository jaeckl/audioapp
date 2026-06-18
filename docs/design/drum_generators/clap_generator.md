# Clap generator — design spec

**Type ID:** `clap_generator`  
**Status:** US-13-03 (planned)  
**Accent:** `#E8A0C8` (pink)

## Sound model

**Multi-burst noise** simulating room reflections:

1. **Bursts** — 2–5 staggered noise hits (~8–18 ms apart)
2. **Spread** — random micro-delays per burst
3. **Tone** — band-pass / brightness on noise
4. **Room** — overall decay length

Reference: `SampleBank::makeBundledClap()` (3 bursts).

## Parameters (planned)

| ID | UI label | Tab |
|----|----------|-----|
| `clapBursts` | Bursts | Burst |
| `clapSpread` | Spread | Burst |
| `clapTone` | Tone | Tone |
| `clapRoom` | Room | Tone |
| `clapDecay` | Decay | Amp |

## Strip tabs

**Burst** · **Tone** · **Amp**

Preview: staggered vertical bars (burst timeline).

## UX

Picker subtitle: `Multi-hit noise · room clap`.
