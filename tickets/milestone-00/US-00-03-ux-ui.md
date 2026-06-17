# US-00-03-ux-ui: Edge-to-edge shell layout — UX & UI

## Type

UX / UI

## Parent feature

[US-00-03](US-00-03-edge-to-edge-shell-layout.md)

## Design intent

Use full display — professional immersive DAW, not a letterboxed demo.

## Layout & hierarchy

Content bleeds to edges; only transport gets bottom gesture inset; header gets status bar inset.

## Visual states

| State | Treatment |
|-------|-----------|
| Portrait | No band above nav bar |
| Landscape | Timeline under cutout OK; controls remain tappable |

## Copy & feedback

No change to labels — spatial use of screen is the UX win

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] No letterboxing on Moto-class device
- [x] Transport tappable above gesture bar

## Status

**Done**
