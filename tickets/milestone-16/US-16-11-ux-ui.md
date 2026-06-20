# US-16-11-ux-ui: Flutter modulation widget test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-11](US-16-11-modulation-test-coverage.md)

## Design intent

Flutter test: ModulationGrid, ModulationStrip, LfoPropertiesPanel, ModulatableSpinnerShell render correctly.

## Layout & hierarchy

N/A — Flutter widget test

## Visual states

| State | Treatment |
|-------|-----------|

## Copy & feedback



## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] ModulationGrid renders correct number of LFO tiles
- [x] ModulationGrid add tile present when slots available
- [x] ModulationStrip displays LFO cards with controls
- [x] ModulationStrip shows Add Modulator button
- [x] LfoPropertiesPanel shows waveform dropdown and rate slider
- [x] LfoPropertiesPanel shows target edges
- [x] ModulatableSpinnerShell shows modulation bar when active
- [x] ModulatableSpinnerShell shows connect-mode pulse

## Status

**Done**
