# US-02-02-ux-ui: Select track — UX & UI

## Type

UX / UI

## Parent feature

[US-02-02](US-02-02-select-track.md)

## Design intent

Selection is obvious — drives device strip context.

## Layout & hierarchy

Selected row: accent border/background; strip appears below timeline.

## Visual states

| State | Treatment |
|-------|-----------|
| Unselected | Neutral row |
| Selected | Accent + strip visible |

## Copy & feedback

Track name as primary label

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Only one selected track
- [x] Strip tied to selection

## Status

**Done**
