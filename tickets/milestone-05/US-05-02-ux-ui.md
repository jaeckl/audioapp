# US-05-02-ux-ui: Load project — UX & UI

## Type

UX / UI

## Parent feature

[US-05-02](US-05-02-load-project.md)

## Design intent

Load restores trust — user sees their tracks return.

## Layout & hierarchy

Load icon adjacent Save; same status/error area.

## Visual states

| State | Treatment |
|-------|-----------|
| Success | Loaded project |
| Error | load_failed message |
| Loaded content | Tracks/clips visible — not empty |

## Copy & feedback

- Load project
- Loaded project
- load_failed: …

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Never show success with empty arrangement when file had tracks

## Status

**Done**
