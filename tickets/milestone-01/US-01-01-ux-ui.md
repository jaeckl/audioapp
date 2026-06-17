# US-01-01-ux-ui: Play hears engine audio — UX & UI

## Type

UX / UI

## Parent feature

[US-01-01](US-01-01-play-hears-juce-audio.md)

## Design intent

Transport is the hero control — obvious play state.

## Layout & hierarchy

Play/Stop in transport bar; icon toggles (play triangle / stop square).

## Visual states

| State | Treatment |
|-------|-----------|
| Stopped | Play icon |
| Playing | Stop icon or active state |

## Copy & feedback

- Play
- Stop tooltips

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] Playing state visible without audio
- [x] Control in thumb zone

## Status

**Done**
