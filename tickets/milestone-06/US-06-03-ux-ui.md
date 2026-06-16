# US-06-03-ux-ui: Sampler on device strip — UX & UI

## Type

UX / UI

## Parent feature

[US-06-03](US-06-03-sampler-device-on-strip.md)

## Design intent

Sampler card shows loaded sound by name — confidence in assignment.

## Layout & hierarchy

Strip card: Sampler title, sample name, Choose sample button.

## Visual states

| State | Treatment |
|-------|-----------|
| Unassigned | No sample / placeholder |
| Assigned | Sample name prominent |

## Copy & feedback

- Sampler
- Choose sample
- No sample selected

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Name truncates gracefully
- [ ] Choose obvious

## Status

**Todo**
