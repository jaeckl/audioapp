# Device strip chrome — input/output panels and slot layout

**ADR:** [ADR-0008](../adr/ADR-0008-device-strip-ui-chrome.md)  
**Milestone:** M15

## Overview

Expanded device slots are not only a **card body** (knobs, previews, tabs). They include **chrome columns** that depend on device category:

```text
┌──────┬─────────┬──────────┬────────────┬─────────────────────┬─────────┐
│ Tool │ Mod?    │ Lfo?     │ INPUT?     │ Card body           │ OUTPUT? │
│ rail │ grid    │ props    │ (type)     │ (device panel)      │ (type)  │
└──────┴─────────┴──────────┴────────────┴─────────────────────┴─────────┘
```

| Column | Always? | Defined by |
|--------|---------|------------|
| Tool rail | Yes | Universal (`DeviceToolRail`) |
| Mod grid / LFO props | User toggle | Universal |
| **Input panel** | Type-specific | `DeviceInputPanels` |
| Card body | Yes | Per-device `*DevicePanel` |
| **Output panel** | Type-specific | `DeviceOutputPanels` |

Legacy name `DeviceLevelPanel` (Pan + Gain for all) is **retired** in favor of output panels.

## Output panels (right of card)

| `device.type` | Panel | Controls | Width |
|---------------|-------|----------|-------|
| `kick_generator`, `snare_generator`, `clap_generator`, `cymbal_generator` | `DrumMonoOutputPanel` | Gain, Velocity sens | 64px |
| `simple_oscillator`, `simple_sampler`, `subtractive_synth` | `StereoGainPanPanel` | Pan, Gain | 64px |
| `gate`, `compressor`, `expander`, `limiter` | `DynamicsOutputPanel` | Gain, GR meter | 72px |
| default | `StereoGainPanPanel` | Pan, Gain | 64px |

**Engine:** `DeviceSlot.gain` / `pan` always exist. Mono drums hide Pan in UI; `pan` stays 0.5.

**Velocity sens** (`kickVelocity`, etc.) is an **instance parameter**, not a slot field — bound in `DrumMonoOutputPanel`.

## Input panels (left of card, after mod/LFO)

| `device.type` | Panel | Contents | Width |
|---------------|-------|----------|-------|
| `gate`, `compressor`, `expander`, `limiter` | `DynamicsInputPanel` | Input peak/RMS meter; optional input trim (future param); sidechain key (future) | 56–72px |
| all others | — | none | 0 |

Dynamics FX mental model: **signal arrives → [input chrome] → processor card → [output chrome]**.

## Flutter registry pattern

Mirror `DeviceContainerTabs`:

```dart
abstract final class DeviceStripChrome {
  static Widget? inputPanel({required String deviceType, ...});
  static double inputWidth(String deviceType);

  static Widget outputPanel({required String deviceType, ...});
  static double outputWidth(String deviceType);
}
```

`DeviceStripSlot` computes:

```dart
_slotWidth = toolRail + modWidths + inputWidth(type) + cardWidth + outputWidth(type);
```

Border attachment flags: `attachInputPanel`, `attachOutputPanel` (generalize today’s `attachToolRail` / `attachLevelPanel`).

## Card body widths

| Device | Width constant | Notes |
|--------|----------------|-------|
| Sampler | `designWidth` (520) | unchanged |
| Kick bench | `kickDesignWidth` (~480) | single page, no tabs |
| Other drums (interim) | `oscillatorDesignWidth` (360) | until bench rollout |
| Dynamics FX | `oscillatorDesignWidth` (360) | tabs retained on card |
| Subtractive synth | `oscillatorDesignWidth` (360) | unchanged |

## Kick bench (card body summary)

See [kick_generator_ux_addendum.md](drum_generators/kick_generator_ux_addendum.md).

## Snapshot / bridge (future)

Optional engine metadata:

```cpp
struct DeviceStripUiCaps {
    bool hasInputPanel;
    bool hasOutputPanel;
    bool showPan;
};
```

v1: Flutter registry only; engine docs align by convention.

## Testing

- Widget: `DeviceStripChrome` returns correct panel type per `device.type`.
- Widget: kick bench renders 6 knobs without tabs.
- Widget: compressor slot includes input + output columns.
- Manual: mono drum — no Pan visible; Gain + Vel sens work; save/load round-trip.
