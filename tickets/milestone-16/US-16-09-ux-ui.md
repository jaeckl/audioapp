# US-16-09-ux-ui: Effect device automation test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-09](US-16-09-modulation-test-coverage.md)

## Design intent

Engine test: automation clips on Compressor/Gate/Expander/Limiter produce dynamic processing changes.

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

- [x] Compressor threshold automation produces louder output late in ramp
- [x] Gate threshold automation opens gate over time
- [x] Expander threshold automation activates expansion
- [x] Limiter ceiling automation allows increasing peaks

## Status

**Done**
