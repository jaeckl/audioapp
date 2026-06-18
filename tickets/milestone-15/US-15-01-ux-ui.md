# US-15-01-ux-ui: Device strip chrome framework — UX & UI

## Type

UX / UI

## Parent feature

[US-15-01](US-15-01-device-strip-chrome-framework.md)

## Design intent

Strip chrome is composable — each device family gets the right input/output columns without one-size Pan+Gain.

## Layout & hierarchy

Row: Tool | Mod? | Lfo? | Input? | Card | Output?; radii attach input/output to card edges.

## Visual states

| State | Treatment |
|-------|-----------|
| Synth | Stereo Pan + Gain output only |
| Mono drum | DrumMonoOutputPanel — Gain + Vel sens, no Pan |
| Dynamics | Input meter left, Gain + GR right |

## Copy & feedback

- Gain
- Pan
- Vel sens
- GR

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Slot width includes per-type input/output columns
- [ ] Card border radius meets input/output panels
- [ ] No DeviceLevelPanel hard-coded in slot

## Status

**Todo**
