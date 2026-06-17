# US-03-02-ux-ui: Transport playhead — UX & UI

## Type

UX / UI

## Parent feature

[US-03-02](US-03-02-transport-playhead.md)

## Design intent

Playhead shows musical time — sync with transport.

## Layout & hierarchy

Vertical line or marker over timeline; BPM in transport.

## Visual states

| State | Treatment |
|-------|-----------|
| Stopped | Playhead at start or held |
| Playing | Moving playhead |

## Copy & feedback

- BPM display e.g. 120

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Playhead visible on phone
- [x] No full-tree flash each frame

## Status

**Done**
