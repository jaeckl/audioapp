# US-04-03-ux-ui: Move and resize notes — UX & UI

## Type

UX / UI

## Parent feature

[US-04-03](US-04-03-move-resize-notes-grid-snap.md)

## Design intent

Drag affordances — note lifts slightly when dragging.

## Layout & hierarchy

Resize handle at note end (right edge); drag body moves.

## Visual states

| State | Treatment |
|-------|-----------|
| Dragging | Elevated note / ghost |
| Snapped | Aligns to grid |

## Copy & feedback

None

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Drag does not break scroll
- [x] Snap visually clear

## Status

**Done**
