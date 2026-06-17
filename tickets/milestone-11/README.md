# Milestone 11 — Subtractive synth instrument

**Theme:** First full subtractive instrument — 2 osc + noise, LP12 filter, amp/filter envelopes, 8-voice polyphony.

## Locked product decisions

| Decision | Choice |
|----------|--------|
| Polyphony | **8 voices** (fixed pool, voice stealing) |
| Filter | **LP12 only** (no HP/BP/notch in M11) |
| Coexistence | **`subtractive_synth` alongside `simple_oscillator`** — do not remove or replace |
| LFO | **Out of scope for M11** — defer to a later milestone |

## Implementation approach: C++ in-engine (not Faust host)

**Recommendation: hand-written C++ inside `engine_juce/`, matching existing `SamplerFilter` / ADSR / `DeviceChain` patterns.**

| Factor | C++ in-engine | Faust → compiled C++ |
|--------|---------------|----------------------|
| Voice allocation, clip MIDI, live `noteOn` | Native to `ProjectEngine` | Still requires custom glue for 8-voice pool |
| `project.json` / `ProjectJson.cpp` | Same path as sampler & oscillator | Second parameter namespace + UI mapping layer |
| RT safety (no alloc on audio thread) | Enforced by existing conventions | Faust codegen is RT-safe; **host integration is not free** |
| Build / CI | No new toolchain | Faust compiler + codegen diff review in PRs |
| DSP iteration speed | Slower to prototype filters | Faster for experimental DSP kernels |

**Faust may help later** for isolated DSP kernels (e.g. a future multimode filter bank) embedded as static compiled units — not for the full device vertical slice, where most work is host integration anyway.

## Tab layout (strip + fullscreen)

| Tab | Contents |
|-----|----------|
| **Osc** | Waveform, octave/semi/detune, unison, waveform previews |
| **Mix** | Osc1/osc2/noise levels, mix mode (mix / neg / am / sign / max) |
| **Filter** | LP12 cutoff + resonance, filter envelope ADSR |
| **Amp** | Amp envelope ADSR (gain/pan on shared level panel) |

## Story order

1. US-11-01 — Engine MVP (voice pool, saw, amp ADSR, LP12 + filter env)
2. US-11-02 — Device registration, picker, minimal UI, save/load, audible on device
3. US-11-03 — Dual osc + unison
4. US-11-04 — Noise + osc mix modes
5. US-11-05 — Osc tab + waveform previews
6. US-11-06 — Mix + Filter + Amp strip tabs
7. US-11-07 — Fullscreen editor + test note
8. US-11-08 — Factory presets + content library
9. US-11-09 — Glide + velocity (no LFO)
10. US-11-20 — PO demo
