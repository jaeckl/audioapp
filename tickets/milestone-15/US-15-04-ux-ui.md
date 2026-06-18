# US-15-04-ux-ui: Dynamics input and output panels — UX & UI

## Type

UX / UI

## Parent feature

[US-15-04](US-15-04-dynamics-input-output-panels.md)

## Design intent

Dynamics FX read like a rack — input level before, gain reduction after.

## Layout & hierarchy

Input column ~56–72px left of card; output ~72px with Gain + GR meter/bar.

## Visual states

| State | Treatment |
|-------|-----------|
| Idle | GR at 0 dB or empty bar |
| Compressing | GR shows reduction during signal |
| Input | Peak/RMS bar or envelope-driven v1 |

## Copy & feedback

- GR
- Gain
- In
- dB

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] All four dynamics types show input + output columns
- [ ] GR readable at strip height
- [ ] Pan not shown on dynamics devices

## Status

**Todo**
