# US-16-04-ux-ui: Percussion generator modulation test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-04](US-16-04-modulation-test-coverage.md)

## Design intent

Engine test: LFO modulating parameters on Kick/Snare/Clap/Crash/Cymbal generators changes timbre.

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

- [x] LFO on Kick pitch produces RMS change vs unmodulated
- [x] LFO on Snare body produces RMS change
- [x] LFO on Clap tone produces RMS change
- [x] LFO on Crash spread produces RMS change
- [x] LFO on Cymbal width produces RMS change

## Status

**Done**
