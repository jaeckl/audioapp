# US-16-08-ux-ui: Combined gain/pan modulation and automation test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-08](US-16-08-modulation-test-coverage.md)

## Design intent

Engine test: combined modulation and automation on gain/pan combine additively without conflict.

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

- [x] Auto-only gain ramp produces monotonically increasing RMS
- [x] Mod-only gain produces periodic RMS variation
- [x] Combined mod+auto shows both ramp trend and ripple
- [x] Combined mod+auto on pan does not crash or clip

## Status

**Done**
