# US-16-06-ux-ui: LFO polarity test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-06](US-16-06-modulation-test-coverage.md)

## Design intent

Engine test: bipolar/positive/negative LFO polarity produces measurably different spectral content.

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

- [x] Bipolar LFO produces full HF sweep (ratio > 1.5x)
- [x] Positive-only LFO produces different HF pattern than bipolar
- [x] Negative-only LFO produces different HF pattern than positive
- [x] Polarity field persists in JSON round-trip

## Status

**Done**
