# US-15-04: Dynamics input and output panels

## Type

Feature

## Milestone

Milestone 15 — Device strip UX chrome

## User story

As a **producer**, I see **input level** before a dynamics FX and **gain reduction / output level** after it — like hardware compressor racks — instead of only a generic Pan + Gain column.

## Goal

Implement **`DynamicsInputPanel`** (left of card) and **`DynamicsOutputPanel`** (right of card) for gate, compressor, expander, limiter.

## UX flow

1. Insert Compressor in chain.
2. Left of card (after tool/LFO): **input meter** column (~56–72px).
3. Card body: existing dynamics tabs/knobs unchanged.
4. Right of card: **Gain** + **GR meter** (reduction dB or bar).

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | Meter readable at strip height; no audio thread work in Flutter |

## Scope

### Flutter

- `DynamicsInputPanel`: input peak/RMS visualization (v1 may be **envelope preview driven** or static placeholder bar until metering bridge exists)
- `DynamicsOutputPanel`: Gain knob + GR display
- Register all four dynamics type IDs in `DeviceInputPanels` and `DeviceOutputPanels`
- Wider output width (~72px) for GR label
- Update [device_strip_chrome.md](../../docs/design/device_strip_chrome.md) screenshots list when capturing

### Engine / bridge (minimal v1)

- Option A: Expose `gainReductionDb` from `DynamicsRuntime` in project snapshot per device (read-only UI)
- Option B: v1 placeholder GR UI wired to 0 dB until snapshot field lands — document in ticket if deferred

Prefer **Option A** if small diff: extend `DeviceSnapshot` / JSON for dynamics reduction readout (control thread only).

## Out of scope

- Sidechain key picker
- Input gain trim param (future `inputGain`)
- Changing dynamics card tab layout

## Acceptance criteria

- [ ] Gate/compressor/expander/limiter slots show input column left of card
- [ ] Dynamics output column shows Gain + GR (real or placeholder documented)
- [ ] Stereo Pan **not** shown on dynamics devices (or gain-only if product prefers)
- [ ] Slot width accounts for input + output
- [ ] Widget test: compressor finds input panel semantics label
- [ ] Manual: heavy compression → GR indicator moves (if Option A shipped)

## Demo script (on-device, ~30s)

1. Kick → compressor on track; play loop.
2. Lower threshold → GR meter shows reduction during hits.
3. Output Gain trims level post-compressor.

## Depends on

US-15-01


## Companion stories

- [UX/UI](US-15-04-ux-ui.md)
- [Interaction](US-15-04-interaction.md)

## Status

**todo**
