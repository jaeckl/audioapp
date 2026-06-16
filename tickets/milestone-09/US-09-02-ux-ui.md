# US-09-02-ux-ui: Export WAV — UX & UI

## Type

UX / UI

## Parent feature

[US-09-02](US-09-02-export-wav-system-dialog.md)

## Design intent

Export is a deliverable — progress then success like Save.

## Layout & hierarchy

Export in app bar; modal or inline progress; success message with filename.

## Visual states

| State | Treatment |
|-------|-----------|
| Rendering | Progress bar or spinner + % |
| Success | Export complete |
| Error | Red message |

## Copy & feedback

- Export
- Rendering…
- Export complete
- Export failed

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Progress during long render
- [ ] Cancel render optional

## Status

**Todo**
