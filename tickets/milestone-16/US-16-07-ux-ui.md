# US-16-07-ux-ui: LFO sync-to-BPM test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-07](US-16-07-modulation-test-coverage.md)

## Design intent

Engine test: LFO syncDivision synchronizes to project BPM, producing correct cycle counts.

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

- [x] Sync 1/4 LFO at 120 BPM produces ~4 modulation cycles in 4 beats
- [x] Sync 1/2 LFO produces ~2 cycles in 4 beats
- [x] Sync and free LFO produce different cycle counts
- [x] BPM change affects sync LFO rate but not free LFO rate

## Status

**Done**
