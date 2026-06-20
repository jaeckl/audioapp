# US-16-05-ux-ui: ADSR envelope modulator test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-05](US-16-05-modulation-test-coverage.md)

## Design intent

Engine test: ADSR/ADR envelope modulators produce characteristic attack-sustain-decay shapes on filter cutoff.

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

- [x] ADSR envelope shows HF energy peak during attack, lower in sustain
- [x] ADR (no sustain) decays faster than ADSR
- [x] Zero-attack ADSR produces immediate HF peak

## Status

**Done**
