# US-08-04-ux-ui: Parameter automation — UX & UI

## Type

UX / UI

## Parent feature

[US-08-04](US-08-04-parameter-automation.md)

## Design intent

Automation clip in lower half of track lane; purple curve preview; floating **Link** chip above clip; device knobs pulse purple in Link Mode.

## Layout & hierarchy

- Automation clip: bottom half of track lane (same row as MIDI/sample)
- Link chip: centered above clip
- Curve editor: fullscreen overlay on double-tap

## Visual states

| State | Treatment |
|-------|-----------|
| Unlinked | "AUTO" placeholder + Link chip |
| Link Mode active | Purple chip glow; knobs pulse |
| Linked | Param label on clip header |
| Editing | Fullscreen curve editor |

## Copy & feedback

- Link / Filter / Gain labels on chip
- Snackbar on Automate this and Link assign

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Automation clips visible on timeline (not menu-only)
- [x] Link chip discoverable on clip

## Status

**Done**
