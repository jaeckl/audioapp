# US-03-03-ux-ui: MIDI clip playback — UX & UI

## Type

UX / UI

## Parent feature

[US-03-03](US-03-03-midi-clip-playback.md)

## Design intent

Hearing the clip is the payoff — UI stays minimal during play.

## Layout & hierarchy

No modal during playback; playhead + clip highlight optional.

## Visual states

| State | Treatment |
|-------|-----------|
| Playing | Transport active |
| Silent | Stop state |

## Copy & feedback

None beyond transport

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Audible on device speaker
- [x] No silent success

## Status

**Done**
