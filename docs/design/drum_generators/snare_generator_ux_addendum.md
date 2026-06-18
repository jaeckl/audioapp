# Snare generator — UX addendum (bench redesign + DSP v2)

**Supersedes:** § “Strip tabs” in [snare_generator.md](snare_generator.md) (Body / Snares / Amp three-tab layout).  
**Follows:** [kick_generator_ux_addendum.md](kick_generator_ux_addendum.md) (Kick bench pattern)  
**ADR:** [ADR-0008](../../adr/ADR-0008-device-strip-ui-chrome.md)

## Problem statement

### UX — same tab economics as pre-M15 kick

| Tab | Knobs | Issue |
|-----|-------|-------|
| Body | Body, Tune | OK |
| Snares | Snares, Snap | Hides decay; repeats preview |
| Amp | Decay only | Velocity moved to output rail (M15) |

Five timbre params split across three tabs; users tweak body + wires + decay together when programming grooves.

### DSP — “cowbell” timbre (shipping bug)

The design spec calls for **band-passed noise** for the snare wires. The shipped code uses **ring modulation**:

```cpp
// SnareGenerator.cpp (current — not band-pass)
const float ringMod = sin(2π * bpCenter * t) * rawNoise * noiseEnv;
```

Multiplying noise by a high-frequency sine (600–3000 Hz) is ring AM/RM: it adds **metallic sidebands** and a pitched “clang” — reads as cowbell or toy metal, not wire buzz.

The **body** is a static sine with fast decay — no pitch drop, no drum-head “thump” motion. **Snap** is the only plausible snare-like layer.

---

## Target layout — Snare bench (single page)

Mirror kick bench: **~480px**, **no tabs**, **DrumMonoOutputPanel** on the right.

```text
┌─────────────────────────────────────────────────────────────┐
│ Snare Generator · Mono · Acoustic                            │
├────────────────────────────┬────────────────────────────────┤
│  Dual-layer preview (2/3)  │   Body       Tune      Snap   │
│  body thump + wire tail     │    ○          ○          ○    │
├────────────────────────────┤   Wires      Decay      —      │
│ [ Acoustic ][ Tight ][ 909 ]│    ○          ○               │
│  flat model tab bar (1/3)   │                                │
└────────────────────────────┴────────────────────────────────┘
```

### Left column

- **Preview (flex 2):** body envelope (short pitch drop) + wire noise tail (band energy), not ring-mod shape.
- **Model segment (flex 1):** `DrumModelTabBar` — flat bottom tabs, ~22px tall (same as kick).  
  v1: **Acoustic** only; **Tight** / **909** disabled until `snareModel` DSP branches land.

### Right column — 2×3 knob grid

| Row | Col 1 | Col 2 | Col 3 |
|-----|-------|-------|-------|
| 1 | **Body** (`snareBody`) | **Tune** (`snareTune`) | **Snap** (`snareSnap`) |
| 2 | **Wires** (`snareSnares`) | **Decay** (`snareDecay`) | *(reserved)* |

**UI rename:** label **Snares → Wires** (param id `snareSnares` unchanged for JSON compatibility).

### Output rail (M15 — already shipped)

Gain + Vel sens on `DrumMonoOutputPanel`; no Pan.

---

## DSP v2 proposal — acoustic snare (replace ring mod)

Design goal: **moving body** (membrane pitch drop) + **impacting top** (short noise transient) + **sustained wire buzz** (filtered noise, not metallic RM).

### Layer 1 — Body (membrane)

- Start ~280–320 Hz, exponential pitch drop to ~160 Hz over **15–25 ms** (map from `snareBody` + `snareTune`).
- Waveform: sine + light 2nd harmonic (optional `tanh` drive) for “wood/shell” weight.
- Amp envelope: ~40–80 ms (faster than kick; `snareBody` controls decay time).
- **Not** a fixed-frequency sine for the full hit — that reads as beep/bell.

### Layer 2 — Wires (snares)

- **White/pink noise** through a **2-pole band-pass biquad** (reuse `BiquadState` pattern from sampler).
- Center frequency: **2 kHz – 7 kHz** from `snareTune` (wires brighter when tune higher).
- Bandwidth / Q: from `snareSnares` (more wires = wider band + more energy, not higher RM depth).
- Decay: **80–350 ms** independent of body (longer tail than body by default).
- **Delete ring modulation path entirely.**

### Layer 3 — Snap (top / stick impact)

- Very short **high-pass noise** burst, 0–4 ms (`snareSnap`).
- Optional: separate HPF at ~4 kHz so snap sits above body thump.
- This is the “crack” on top — should be obvious when `Snap` is raised.

### Mix & normalization

```text
out = (body + wires + snap) * ampEnv * velocityGain * gain * kInstrumentOutputGain
```

Target: at default params + vel 100, peak comparable to kick so output **Gain** is predictable.

### Model variants (future `snareModel`)

| Model | Body | Wires | Notes |
|-------|------|-------|-------|
| Acoustic (v1) | Pitch-drop sine | BPF noise | Above algorithm |
| Tight | Shorter body, less pitch drop | HPF noise, shorter tail | Hip-hop / tight room |
| 909 | Click + tuned noise blend | TR-909 style short noise | Classic drum machine |

Branch in `snareGeneratorSample()` via `snareModel` param — **same device type**, same pattern as kick `kickModel`.

---

## Runtime state (engine)

Add to `SnareVoiceRuntime`:

- Biquad state for wire filter (2 floats minimum per voice).
- Body pitch envelope phase (or store start frequency + decay constants on trigger).

All RT-safe; no heap; filter coeffs computed on **note trigger** from params snapshot.

---

## Parameter map (unchanged IDs)

| ID | UI label (bench) | Layer |
|----|------------------|-------|
| `snareBody` | Body | Membrane level + decay time |
| `snareTune` | Tune | Body pitch + wire center |
| `snareSnares` | Wires | Wire level + bandwidth |
| `snareSnap` | Snap | Top transient |
| `snareDecay` | Decay | Master amp envelope |
| `snareVelocity` | Vel sens | Output panel |
| `snareModel` | *(tab)* | Future DSP branch |
| `gain` | Gain | Output panel |

---

## Ticket sketch (post-M15)

| ID | Title |
|----|-------|
| US-16-01 | Snare DSP v2 — BPF wires, pitch-drop body, remove ring mod |
| US-16-02 | Snare bench UI (mirror kick) + `snareModel` stub |
| US-16-03 | Snare bench widget tests + C++ timbre smoke test |

---

## Acceptance (when implemented)

- [ ] No ring modulation in snare path; wires use band-pass noise.
- [ ] Body audible as pitch-dropping thump, not fixed beep.
- [ ] Snap adds clear stick crack without dominating as metal ping.
- [ ] Single-page snare bench; all five timbre knobs visible.
- [ ] A/B: old vs new — user can’t describe hit as “cowbell” at default settings.

## Demo script (~30s)

1. Insert Snare → all knobs on one page.
2. Body + Tune → deeper thump vs brighter wires.
3. Wires up → longer noise tail; Snap up → sharper attack.
4. Compare to kick on same track — snare should feel like drum kit, not percussion bell.
