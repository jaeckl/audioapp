# Snare generator — design spec

**Type ID:** `snare_generator`  
**Status:** US-13-02 (planned)  
**Accent:** `#F0C14B` (gold)

## Sound model

Two-layer **tonal body + noise snares** (design intent):

1. **Body** — membrane pitch drop ~280→160 Hz, fast decay (~40–80 ms)
2. **Snares (wires)** — **band-pass filtered** noise, medium decay (~80–350 ms)
3. **Snap** — short HPF noise transient (stick impact)
4. **Tune** — body pitch + wire band center

> **Shipping note:** `SnareGenerator.cpp` currently implements wires as `sin(f·t) × noise` (ring modulation), which sounds metallic/cowbell-like. See [snare_generator_ux_addendum.md](snare_generator_ux_addendum.md) for DSP v2.

## Parameters (planned)

| ID | UI label | Tab |
|----|----------|-----|
| `snareBody` | Body | Body |
| `snareTune` | Tune | Body |
| `snareSnares` | Snares | Snares |
| `snareSnap` | Snap | Snares |
| `snareDecay` | Decay | Amp |
| `snareVelocity` | Velocity | Amp |

## Strip tabs

> **Superseded (proposed M16):** see [snare_generator_ux_addendum.md](snare_generator_ux_addendum.md) — single-page **Snare bench**, BPF wire layer, pitch-drop body. Current shipping DSP uses ring-mod noise (metallic); addendum describes fix.

**Body** · **Snares** · **Amp**

Preview: dual-layer waveform (tone spike + noisy tail).

## UX

Picker subtitle: `Body + noise · tunable`.  
Slot subtitle: `Mono · synth`.

Depends on US-13-01 (shared drum generator infrastructure).
