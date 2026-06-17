# US-02-03-ux-ui: Oscillator on device strip — UX & UI

## Type

UX / UI

## Parent feature

[US-02-03](US-02-03-oscillator-device-strip.md)

## Design intent

Device strip feels like a hardware module — frequency is the star control.

## Layout & hierarchy

Horizontal card on strip: device name, frequency slider, value label (Hz).

## Visual states

| State | Treatment |
|-------|-----------|
| Default | 440 Hz or last value |
| Dragging | Live value label |

## Copy & feedback

- Oscillator
- Frequency
- Hz unit

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Slider usable one-handed
- [x] Value readable

## Status

**Done**
