# US-16-01-ux-ui: Stacked LFO modulation test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-01](US-16-01-modulation-test-coverage.md)

## Design intent

Engine test: two LFOs modulating the same SubtractiveSynth produce complex spectral variation beyond single-LFO.

## Layout & hierarchy

N/A — engine test only

## Visual states

| State | Treatment |
|-------|-----------|

## Copy & feedback



## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Two LFOs on different params produce HF energy variation > 2x across windows
- [x] Two LFOs on same param produce additive spectral variation
- [x] Removing one LFO decreases spectral variation

## Status

**Done**
