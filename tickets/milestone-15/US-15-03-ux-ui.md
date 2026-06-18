# US-15-03-ux-ui: Mono drum output panels — UX & UI

## Type

UX / UI

## Parent feature

[US-15-03](US-15-03-mono-drum-output-panels.md)

## Design intent

Mono drums use Gain + Velocity sensitivity — not Pan — matching hardware drum strips.

## Layout & hierarchy

Compact right column ~56px: Vel sens + Gain knobs; no Pan.

## Visual states

| State | Treatment |
|-------|-----------|
| Kick | kickVelocity + gain |
| Snare/clap/cymbal | Type-specific *Velocity param + gain |

## Copy & feedback

- Gain
- Vel sens
- Velocity

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Pan not shown for any of four drum types
- [ ] Knobs meet 44dp touch target
- [ ] Automation/mod hooks on output knobs

## Status

**Todo**
