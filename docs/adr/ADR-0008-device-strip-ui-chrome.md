# ADR-0008: Device strip UI chrome — per-type input/output panels and single-page instrument layouts

## Status

Accepted (2026-06)

## Context

The expanded device strip uses a **fixed chrome layout** for every device type:

```text
[ Tool rail ] [ Mod? ] [ Lfo? ] [ Card body ] [ DeviceLevelPanel: Pan + Gain ]
```

This made sense for M02–M08 when devices were mostly stereo instruments. It does not match how users work with **mono drum generators** or **dynamics FX**:

| Device family | Pan useful? | Better side controls |
|---------------|-------------|----------------------|
| Mono drums (kick, snare, clap, cymbal) | No | **Gain + velocity sensitivity** (Biwig-style) |
| Stereo instruments (synth, sampler) | Yes | Gain + Pan |
| Dynamics FX (gate, compressor, …) | Rarely | **Input metering** (left) + **gain reduction / output** (right) |

Drum generators (M13) adopted a **3-tab card** pattern (Body / Trans / Amp) copied from early synth strips. In practice:

- **Trans** tab exposes only **Click** — same preview, one knob (poor tab economics).
- **Amp** tab puts **Velocity sens** next to **Decay** while **Gain** lives in the universal level panel — reads as duplicate loudness controls.
- Six timbre parameters are hidden behind tab switches on a device users tweak constantly.

Separately, product direction calls for **multiple kick engines** (808 digital, 909, analog, …) without multiplying picker entries. The engine already passes **`KickGeneratorParams`** into `kickGeneratorSample()` on every sample; branching on a `kickModel` parameter is sufficient — **no new `DeviceNodeKind` or device type** is required.

## Decision

### 1. Replace universal `DeviceLevelPanel` with per-type **output panels**

Introduce a Flutter registry (e.g. `DeviceOutputPanels`) keyed by `device.type`:

| Registry entry | Widget | Controls |
|----------------|--------|----------|
| Mono drums | `DrumMonoOutputPanel` | Gain, Velocity sens |
| Stereo instruments | `StereoGainPanPanel` | Pan, Gain (today’s default) |
| Dynamics FX | `DynamicsOutputPanel` | Gain, GR meter / reduction readout |
| Default fallback | `StereoGainPanPanel` | Pan, Gain |

**Engine unchanged for v1:** `DeviceSlot.gain` and `DeviceSlot.pan` remain on every slot. UI chooses what to surface. Mono devices keep `pan = 0.5` when pan is hidden.

### 2. Add optional per-type **input panels** (left of card body)

Introduce `DeviceInputPanels` for device types that process **incoming audio**:

| Registry entry | Widget | Placement |
|----------------|--------|-----------|
| Dynamics FX | `DynamicsInputPanel` | After tool rail + LFO columns, **before** card body |
| All others | `null` | No extra width |

Slot row order:

```text
[ Tool ] [ Mod? ] [ Lfo? ] [ Input? ] [ Card body ] [ Output? ]
```

`_slotWidth` sums column widths; only types that register panels pay horizontal cost.

### 3. Kick generator — single-page **Kick bench** (Layout A)

- **No header tabs** on the card for kick (v1 redesign).
- **Width:** ~440–480px (`kickDesignWidth` or reuse `designWidth`).
- **Left column (~45%):** envelope preview **2/3 height**; bottom **1/3** = segmented **model picker** (`kickModel`: 808 / 909 / Analog …).
- **Right column (~55%):** **2×3 knob grid**; labels and `parameterId`s from `KickModelUiRegistry[kickModel]`.
- **Velocity sens** moves to **DrumMonoOutputPanel** (not in card body).

### 4. Engine model switching — one device type, param branch in DSP

Add `kickModel` (normalized 0–1 or discrete steps) to `KickGeneratorInstance` / `KickGeneratorParams`.

In `kickGeneratorSample()` (and live path):

```cpp
switch (resolvedModel(params.kickModel)) {
    case KickModel::Digital808: return sampleKick808(...);
    case KickModel::Digital909:  return sampleKick909(...);  // when implemented
    case KickModel::Analog:      return sampleKickAnalog(...);
}
```

- **Not** a new `kick_analog` device type in the picker.
- Params baked into `DeviceNodePlayback` on rebuild (same as Pitch/Punch today).
- v1 may ship **808 only** with other segments disabled (“soon”).

### 5. DSP normalization (mono drums)

Target consistent peak level at default settings (e.g. −6 dBFS at vel=100, gain=0.8) so **Gain** on the output panel behaves as a predictable mix trim. Velocity sens remains a **performance** control, not a second fader.

### 6. Documentation and tickets

- UX addendum: [kick_generator_ux_addendum.md](../design/drum_generators/kick_generator_ux_addendum.md)
- Strip chrome design: [device_strip_chrome.md](../design/device_strip_chrome.md)
- Milestone **M15** stories US-15-01 … US-15-04 implement incrementally.
- M13 “3-tab drum pattern” is **superseded** for kick; snare/clap/cymbal may follow in later stories.

## Consequences

**Easier**

- Device-appropriate controls without one-size-fits-all Pan.
- Kick tweaking without tab friction; room for multiple engines via `kickModel`.
- Dynamics FX gain a hardware-like **input → processor → output** strip mental model.
- Flutter registries mirror existing `DeviceContainerTabs` pattern.

**Harder**

- `device_strip_slot.dart` row layout and width math grow more branches.
- Border radius / `attachToolRail` / `attachLevelPanel` flags generalize to input/output attachment.
- GR meter needs snapshot or bridge field from `DynamicsRuntime` (may be read-only v1).

**Deferred**

- `IDeviceType::stripUiCaps()` on engine (optional single source of truth).
- Sidechain key picker on `DynamicsInputPanel`.
- Full 909 / Analog DSP branches (UI segment can ship first).

## References

- [device_model.md](../architecture/device_model.md)
- [kick_generator.md](../design/drum_generators/kick_generator.md)
- [dynamics_fx/README.md](../design/dynamics_fx/README.md)
- M13 locked decisions (to be updated): [milestone-13/README.md](../../tickets/milestone-13/README.md)
- ADR-0007 `IDeviceType` (control-thread device types)
