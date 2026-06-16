# US-06-03-ux-ui: Insert sample clip on track — UX & UI

## Type

UX / UI

## Parent feature

[US-06-03](US-06-03-insert-sample-clip-on-track.md)

## Design intent

Inserting audio feels like placing a region — clear clip block on timeline.

## Layout & hierarchy

Library row action Insert on track; timeline shows sample clip distinct from MIDI (color/icon).

## Visual states

| State | Treatment |
|-------|-----------|
| No clip | Timeline empty or MIDI only |
| Sample clip | Block with name label |

## Copy & feedback

- Insert on track
- Sample clip

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Clip visually distinct from MIDI
- [ ] Sample name visible

## Status

**Todo**
