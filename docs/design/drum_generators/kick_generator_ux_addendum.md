# Kick generator — UX addendum (strip redesign)

**Supersedes:** § “Strip tabs” in [kick_generator.md](kick_generator.md) (Body / Trans / Amp three-tab layout).  
**ADR:** [ADR-0008](../../adr/ADR-0008-device-strip-ui-chrome.md)  
**Ticket:** US-15-02, US-15-03

## Problem statement

The shipped 3-tab strip (Body / Trans / Amp) has poor economics:

| Tab | Knobs | Issue |
|-----|-------|-------|
| Body | Pitch, Punch, Tone | Good |
| Trans | Click only | Wastes a tab; repeats preview |
| Amp | Decay, Velocity sens | Velocity competes with Gain on level panel; no preview |

Users tweak all timbre params frequently; hiding four of six behind tabs adds friction on mobile.

## Target layout — Kick bench (single page)

**Width:** ~440–480px. **Tabs:** none on card header.

```text
┌─────────────────────────────────────────────────────────────┐
│ Kick Generator · Mono · 808                                  │
├────────────────────────────┬────────────────────────────────┤
│  Envelope preview (2/3 h)  │   Pitch      Punch      Tone   │
│  pitch drop + amp outline  │    ○          ○          ○    │
├────────────────────────────┤   Click      Decay      —      │
│  [ 808 ] [ 909 ] [ Analog ]│    ○          ○               │
│  model segment (1/3 h)     │                                │
└────────────────────────────┴────────────────────────────────┘
```

### Left column

- **Preview (flex 2):** existing `KickEnvelopePreview`; updates from all active model params.
- **Model segment (flex 1):** `SegmentedButton` or chip row setting `kickModel`.
  - v1: **808** active; 909 / Analog disabled with “Soon” tooltip.
  - Does **not** change device type — same `kick_generator` in chain and JSON.

### Right column

- **2×3 knob grid** from `KickModelUiRegistry[kickModel]`.
- **808 mapping (v1):**

| Row | Col 1 | Col 2 | Col 3 |
|-----|-------|-------|-------|
| 1 | Pitch (`kickPitch`) | Punch (`kickPunch`) | Tone (`kickTone`) |
| 2 | Click (`kickClick`) | Decay (`kickDecay`) | *(empty / reserved)* |

Future models may remap labels (e.g. Analog: “Sweep”, “Sat”, no Click).

### Output chrome (not in card)

**`DrumMonoOutputPanel`** on the right of the card (replaces Pan + Gain):

| Control | Param | Role |
|---------|-------|------|
| Gain | `gain` | Mix trim / output level |
| Vel sens | `kickVelocity` | MIDI velocity sensitivity |

Pan is hidden; engine keeps `pan = 0.5`.

## Engine — `kickModel` (not a new device type)

Add to `KickGeneratorInstance` / `KickGeneratorParams`:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `kickModel` | float 0–1 | 0.0 | Maps to discrete models in DSP |

Branch in `kickGeneratorSample()`:

```cpp
// Pseudocode — same params struct, no new DeviceNodeKind
if (model == Digital808) return sampleKick808(voice, params, ...);
if (model == Analog)     return sampleKickAnalog(voice, params, ...);
```

Params reach the sample function via existing `DeviceNodePlayback` rebuild — **no architectural change**.

### Normalization

At default params + vel=100, peak should land near a consistent level so **Gain** on the output panel is predictable. Velocity sens scales note dynamics, not replace Gain.

## Parameter map (808, unchanged IDs)

| ID | UI label | In card grid |
|----|----------|--------------|
| `kickPitch` | Pitch | Yes |
| `kickPunch` | Punch | Yes |
| `kickTone` | Tone | Yes |
| `kickClick` | Click | Yes |
| `kickDecay` | Decay | Yes |
| `kickVelocity` | Vel sens | Output panel only |
| `kickModel` | *(segment)* | Model row |
| `gain` | Gain | Output panel |
| `pan` | — | Hidden (mono) |

## Acceptance (addendum)

- [ ] Kick card has **no tabs**; all 808 knobs visible without switching.
- [ ] Model segment visible; only 808 selectable in v1.
- [ ] `kickModel` in save/load JSON; branch in `kickGeneratorSample` (808 path).
- [ ] Gain + Vel sens on `DrumMonoOutputPanel`; no Pan on kick slot.
- [ ] Preview fills 2/3 left column; model row 1/3.

## Demo script (~30s)

1. Insert Kick Generator → all knobs visible on one page.
2. Toggle model segment (808 only active) → knobs unchanged in v1.
3. Adjust Punch + Decay → preview updates; play MIDI clip → audible change.
4. Vel sens on output rail: light pad vs hard pad changes level; Gain trims overall.
5. Save → reload → layout and sound unchanged.
