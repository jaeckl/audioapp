# US-15-01: Device strip chrome framework

## Type

Architecture / Feature

## Milestone

Milestone 15 — Device strip UX chrome

## User story

As a **developer**, I can **register per-device input and output strip columns** so each device family shows appropriate controls (mono drum output, dynamics input meter, stereo pan) without hard-coding every type in `device_strip_slot.dart`.

## Goal

Replace the universal **`DeviceLevelPanel`** (Pan + Gain for everyone) with extensible **`DeviceStripChrome`** registries and correct **slot width** math.

## UX flow

1. User expands any device in the chain — slot renders tool rail + optional mod + **type-specific chrome** + card + **type-specific output**.
2. Stereo synth: unchanged feel (Pan + Gain on right).
3. Mono drum / dynamics: different right (and dynamics: left) columns per ADR-0008.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | No layout overflow at default strip height; horizontal scroll in chain still works |

## Scope

- `DeviceStripChrome` (or `DeviceInputPanels` + `DeviceOutputPanels`) registry in `app_flutter/lib/features/device_strip/`
- Refactor `device_strip_slot.dart` row: `[Tool][Mod?][Lfo?][Input?][Card][Output?]`
- `DeviceStripMetrics`: `inputPanelWidthFor`, `outputPanelWidthFor`; update `_slotWidth`
- `StereoGainPanPanel` — extract from current `DeviceLevelPanel` (rename or wrap)
- Stub panels: `DrumMonoOutputPanel`, `DynamicsInputPanel`, `DynamicsOutputPanel` (minimal placeholder OK if US-15-03/04 flesh out)
- Border radius: generalize `attachLevelPanel` → `attachOutputPanel`; add `attachInputPanel` on `DeviceStripCard`
- Widget tests: registry returns non-null dynamics input; kick uses drum output; synth uses stereo output
- Docs: [device_strip_chrome.md](../../docs/design/device_strip_chrome.md), [ADR-0008](../../docs/adr/ADR-0008-device-strip-ui-chrome.md)

## Out of scope

- Full kick bench layout (US-15-02)
- GR meter data from engine (US-15-04)
- `IDeviceType::stripUiCaps()` in C++

## Acceptance criteria

- [ ] `DeviceLevelPanel` no longer referenced directly from `device_strip_slot`
- [ ] Slot width includes input/output widths per type
- [ ] Compressor type allocates input + output column widths (widgets may be placeholder)
- [ ] Subtractive synth still shows Pan + Gain on the right
- [ ] `flutter test` — new registry widget tests pass
- [ ] `flutter analyze` clean on touched files

## Demo script (dev, ~20s)

1. Open chain with synth + compressor — different right columns visible.
2. Toggle mod strip — input/output columns remain aligned with card borders.

## Technical notes

- Follow `DeviceContainerTabs.forDeviceType` pattern.
- Keep modulation/automation hooks passed through to output panels same as today’s `DeviceLevelPanel`.


## Companion stories

- [UX/UI](US-15-01-ux-ui.md)
- [Interaction](US-15-01-interaction.md)

## Status

**todo**
