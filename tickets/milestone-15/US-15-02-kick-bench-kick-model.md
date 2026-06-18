# US-15-02: Kick bench layout + kickModel engine branch

## Type

Feature

## Milestone

Milestone 15 — Device strip UX chrome

## User story

As a **producer**, I can **shape a kick on one screen** (preview, model picker, all 808 knobs) without switching tabs, and the engine can **branch DSP by model** (`808` today; 909/Analog later) without adding new device types to the picker.

## Goal

Ship **Layout A (amended)** from [kick_generator_ux_addendum.md](../../docs/design/drum_generators/kick_generator_ux_addendum.md).

## UX flow

1. Insert Kick Generator → single-page **Kick bench** (~480px card).
2. Left: preview (2/3 height) + model segment row (1/3): 808 / 909 / Analog (only 808 active in v1).
3. Right: 2×3 knobs — Pitch, Punch, Tone / Click, Decay, spare.
4. Output rail (US-15-03): Gain + Vel sens — not on card.

## Platform UX

| Platform | Requirement |
|----------|-------------|
| **Android** | All knobs reachable without tab switch; preview updates while dragging |

## Scope

### Engine

- `kickModel` on `KickGeneratorInstance` / `KickGeneratorParams` / `DeviceState` / JSON / automation
- `KickGeneratorDeviceType::setParameter` for `kickModel`
- `kickGeneratorSample()`: branch on model; **808 path** = current DSP; other models stub or same as 808 until implemented
- C++ test: set `kickModel`, verify non-silent output (808 branch)

### Flutter

- Replace 3-tab `KickGeneratorDevicePanel` with kick bench layout
- Remove `KickDeviceTab` from container tabs for kick (empty tab list or header-only)
- `KickModelUiRegistry` — maps model index → knob specs (808 v1)
- `DeviceStripMetrics.kickDesignWidth` (~480)
- Update `dynamics_fx_screenshot_main` / kick screenshots if needed

### Docs

- Link [kick_generator.md](../../docs/design/drum_generators/kick_generator.md) → addendum
- Mark old § Strip tabs superseded

## Out of scope

- 909 / Analog DSP (segment may show disabled)
- Snare/clap/cymbal bench (future M15 or M13 follow-up)
- `DrumMonoOutputPanel` implementation (US-15-03) — may land same PR if 15-01 done

## Acceptance criteria

- [ ] Kick card has **no tabs**; six 808 params on one page
- [ ] Model segment visible; 808 selectable; others disabled in v1
- [ ] `kickModel` round-trip in project JSON
- [ ] `kickGeneratorSample` branches on model (test or comment + 808 default)
- [ ] Preview occupies ~2/3 left column height
- [ ] Widget test: kick panel finds Pitch + Decay without tab tap
- [ ] Manual: tweak punch/decay → hear change on timeline

## Demo script (on-device, ~30s)

1. Add Kick → all knobs visible.
2. Lower Pitch → deeper; raise Click → sharper attack.
3. Save → reload → same layout and sound.

## Depends on

US-15-01 (output panel slot — can use stub `DrumMonoOutputPanel` until US-15-03)


## Companion stories

- [UX/UI](US-15-02-ux-ui.md)
- [Interaction](US-15-02-interaction.md)

## Status

**todo**
