# US-16-03-ux-ui: Common parameter gain/pan modulation test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-03](US-16-03-modulation-test-coverage.md)

## Design intent

Engine test: LFO modulating gain and pan common parameters produces audible amplitude/stereo variation.

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

- [x] LFO on gain produces RMS variation across windows
- [x] LFO on pan produces RMS deviation from unmodulated baseline
- [x] Two LFOs on gain + pan simultaneously produce complex variation

## Status

**Done**
