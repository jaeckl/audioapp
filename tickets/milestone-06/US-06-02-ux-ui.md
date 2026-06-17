# US-06-02-ux-ui: Import sample — UX & UI

## Type

UX / UI

## Parent feature

[US-06-02](US-06-02-import-sample-system-picker.md)

## Design intent

Import is first-class — same weight as Save/Load.

## Layout & hierarchy

FAB or app bar Import in library; imported rows in separate section.

## Visual states

| State | Treatment |
|-------|-----------|
| Importing | Brief progress or spinner |
| Imported | Row with filename |
| Error | Red banner in library |

## Copy & feedback

- Import
- Imported
- Could not import file

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Imported visually distinct from bundled

## Status

**Todo**
