# US-06-04-ux-ui: Waveform in arrangement — UX & UI

## Type

UX / UI

## Parent feature

[US-06-04](US-06-04-waveform-in-arrangement.md)

## Design intent

Waveform makes clips recognizable at a glance.

## Layout & hierarchy

Mini waveform drawn inside clip rect; peaks centered vertically.

## Visual states

| State | Treatment |
|-------|-----------|
| Sample clip | Waveform visible |
| MIDI clip | No waveform |
| Loading peaks | Placeholder shimmer optional |

## Copy & feedback

None on clip

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Kick vs snare visually different
- [ ] Readable on 1-bar clip width

## Status

**Todo**
