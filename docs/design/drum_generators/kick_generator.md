# Kick generator — design spec

**Type ID:** `kick_generator`  
**Status:** US-13-01 — engine + strip (in progress)  
**Accent:** `#E85D4B` (warm red)

## Sound model

Classic **808-style pitch-drop sine** with optional **click transient**:

1. **Body** — sine oscillator; start frequency 80–200 Hz, exponential glide to ~35–60 Hz
2. **Amp envelope** — exponential decay (~80 ms – 500 ms), no sustain
3. **Click** — short noise burst (~0–4 ms) for beater attack
4. **Tone** — soft saturation on body (tanh drive) for weight
5. **MIDI pitch** — transposes entire kick (default root MIDI 36)

Reference implementation: parametrized version of `SampleBank::makeBundledKick()`.

## Parameters

| ID | UI label | Range (norm) | Maps to | Default |
|----|----------|--------------|---------|---------|
| `kickPitch` | Pitch | 0–1 | Start Hz 80→200 | 0.55 |
| `kickPunch` | Punch | 0–1 | Pitch drop speed + depth | 0.60 |
| `kickDecay` | Decay | 0–1 | Amp decay 500→80 ms | 0.50 |
| `kickClick` | Click | 0–1 | Transient noise level | 0.35 |
| `kickTone` | Tone | 0–1 | Body drive / saturation | 0.50 |
| `kickVelocity` | Velocity | 0–1 | Velocity sensitivity | 1.00 |
| `gain` | Gain | strip level | Output gain | 1.00 |
| `pan` | Pan | strip level | Stereo pan | 0.50 |

All automatable and LFO-modulatable except `pan` follows strip rules.

## Strip tabs

### Body
- Preview: pitch-drop curve (orange) + amp outline (dim white)
- Knobs: **Pitch**, **Punch**, **Tone**

### Trans (Transient)
- Preview: zoomed click burst waveform
- Knobs: **Click**, **Snap** (future: high-pass on click — use Click for v1)

### Amp
- Knobs: **Decay**, **Velocity**, (inherits gain/pan from level panel)

## UX notes

- Subtitle in chain slot: `Mono · synth`
- Picker subtitle: `808-style · pitch-drop body`
- Picker icon: `Icons.album` or custom kick drum circle
- Hold-to-test: fullscreen editor (US-13-07, later); strip uses MPC pads on Play tab for now

## Acceptance (US-13-01)

- [ ] MIDI note triggers audible kick on timeline and live pads
- [ ] Pitch / punch / decay / click clearly change timbre
- [ ] Save/load round-trip
- [ ] C++ smoke test: non-silent buffer
- [ ] Flutter picker lists Kick Generator

## Demo script (~30 s)

1. Add track → insert Kick Generator → default hit on C1 pad.
2. Raise Punch → tighter thump; lower Pitch → deeper sub.
3. Add click → sharper attack; shorten Decay → tight house kick.
4. Save project → reload → sound unchanged.
