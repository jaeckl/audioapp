# Snare generator — design spec

**Type ID:** `snare_generator`  
**Status:** US-13-02 (planned)  
**Accent:** `#F0C14B` (gold)

## Sound model

Two-layer **tonal body + noise snares**:

1. **Body** — sine ~180 Hz, fast decay (~50 ms)
2. **Snares** — band-passed noise, medium decay (~150–350 ms)
3. **Snap** — optional short transient accent
4. **Tune** — body frequency + noise band center

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

**Body** · **Snares** · **Amp**

Preview: dual-layer waveform (tone spike + noisy tail).

## UX

Picker subtitle: `Body + noise · tunable`.  
Slot subtitle: `Mono · synth`.

Depends on US-13-01 (shared drum generator infrastructure).
