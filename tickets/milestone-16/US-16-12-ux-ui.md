# US-16-12-ux-ui: Flutter LFO snapshot JSON parsing test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-12](US-16-12-modulation-test-coverage.md)

## Design intent

Flutter test: LfoSnapshot/ModulationEdgeSnapshot/ProjectSnapshot JSON parsing with edge cases.

## Layout & hierarchy

N/A — Flutter unit test

## Visual states

| State | Treatment |
|-------|-----------|

## Copy & feedback



## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] LfoSnapshot.fromMap parses all 13 fields
- [x] LfoSnapshot.fromMap handles missing fields with defaults
- [x] ModulationEdgeSnapshot.fromMap parses all 4 fields
- [x] ModulationEdgeSnapshot.fromMap handles missing fields
- [x] ProjectSnapshot.fromMap parses lfos and modEdges arrays
- [x] Edge cases: null values, negative amounts, zero IDs

## Status

**Done**
