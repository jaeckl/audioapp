# US-04-11-ux-ui: Piano roll clip bounds & end marker — UX & UI

## Type

UX / UI

## Parent feature

[US-04-11](US-04-11-piano-roll-horizontal-scroll-and-clip-bounds.md)

## Design intent

Clip end is obvious — red line + pill handle on ruler; editing canvas extends past it.

## Layout & hierarchy

Vertical red boundary at lengthBeats; 16×20 pill on ruler row; dimmed grid past boundary optional.

## Visual states

| State | Treatment |
|-------|-----------|
| Default | Boundary at clip length |
| Dragging end | Line follows finger; scroll locked |
| Notes past end | Full-opacity notes; silent on play |

## Copy & feedback

SnackBar on setClipLength failure

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Handle visible without zoom
- [x] Boundary aligns with grid beats

## Status

**Done**
