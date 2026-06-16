# US-00-02-ux-ui: DAW shell placeholder — UX & UI

## Type

UX / UI

## Parent feature

[US-00-02](US-00-02-daw-shell-placeholder.md)

## Design intent

User immediately recognizes a DAW: timeline on top, transport at bottom, device strip when a track is selected.

## Layout & hierarchy

Three-band shell: arrangement (flex), device strip (fixed height bottom), transport (bottom inset). Dark flat theme.

## Visual states

| State | Treatment |
|-------|-----------|
| Default | Labeled regions even when empty; bridge status shows connection |
| Track selected | Device strip visible with placeholder device card |
| No selection | Strip hidden or shows hint |

## Copy & feedback

- Play
- Stop
- Add track
- Engine status line

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Regions identifiable without tutorial
- [x] Dark theme consistent
- [x] Widget tests cover layout

## Status

**Done**
