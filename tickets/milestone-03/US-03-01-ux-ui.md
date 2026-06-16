# US-03-01-ux-ui: Create MIDI clip — UX & UI

## Type

UX / UI

## Parent feature

[US-03-01](US-03-01-create-midi-clip-on-timeline.md)

## Design intent

Clips read as musical regions on the grid.

## Layout & hierarchy

Clip block: rounded rect on timeline, width = length, label optional.

## Visual states

| State | Treatment |
|-------|-----------|
| No clips | Empty timeline hint |
| Has clip | Colored block |

## Copy & feedback

- Add clip
- Add clip control on timeline

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Clip visible at correct beat width
- [x] Tappable affordance

## Status

**Done**
