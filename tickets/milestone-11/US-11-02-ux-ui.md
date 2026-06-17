# US-11-02-ux-ui: Subtractive synth picker & strip — UX & UI

## Type

UX / UI

## Parent feature

[US-11-02](US-11-02-subtractive-synth-device-picker-strip.md)

## Design intent

Subtractive Synth reads as a **first-class instrument** next to Oscillator and Sampler — distinct accent color (e.g. teal/violet), display name “Subtractive Synth”.

## Layout & hierarchy

- Picker: instrument section, icon + subtitle “2 osc · LP12”
- Minimal strip: one row — filter cutoff large knob, amp attack/release small knobs
- Shared level panel (gain/pan) and tool rail unchanged

## Visual states

| State | Treatment |
|-------|-----------|
| Default patch | Open filter, saw implied |
| No device | Picker only |

## Copy & feedback

- Subtractive Synth
- Cutoff, Attack, Release

## Accessibility & mobile

- 44×44dp knobs; value labels on drag
- Dark DAW theme per mobile_ui_guidelines.md

## Acceptance criteria (visual)

- [ ] Device color distinct from sampler and oscillator
- [ ] Strip height matches device strip metrics

## Status

**Todo**
