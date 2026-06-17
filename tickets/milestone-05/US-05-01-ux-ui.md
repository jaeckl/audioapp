# US-05-01-ux-ui: Save project — UX & UI

## Type

UX / UI

## Parent feature

[US-05-01](US-05-01-save-project.md)

## Design intent

Save feels like any serious app — system dialog, clear success.

## Layout & hierarchy

Save icon in arrangement app bar; status line below or snackbar for result.

## Visual states

| State | Treatment |
|-------|-----------|
| Idle | Save icon enabled |
| Success | Saved project (green/neutral) |
| Error | Red error line |

## Copy & feedback

- Save project
- Saved project
- save_failed: …

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Error red visible
- [x] Success not confused with error

## Status

**Done**
