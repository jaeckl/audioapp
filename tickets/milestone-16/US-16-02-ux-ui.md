# US-16-02-ux-ui: Effect device modulation test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-02](US-16-02-modulation-test-coverage.md)

## Design intent

Engine test: LFO modulating parameters on Compressor/Gate/Expander/Limiter produce audible dynamics changes.

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

- [x] LFO on Compressor threshold produces RMS variation across windows
- [x] LFO on Gate threshold produces amplitude modulation
- [x] LFO on Gate range produces partial gating variation
- [x] LFO on Expander threshold produces amplitude variation
- [x] LFO on Limiter ceiling produces peak variation

## Status

**Done**
