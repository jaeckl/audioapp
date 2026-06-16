# US-06-05-ux-ui: Playhead sample audition — UX & UI

## Type

UX / UI

## Parent feature

[US-06-05](US-06-05-playhead-sample-audition.md)

## Design intent

Playhead crossing a clip should feel causal — sound follows the cursor.

## Layout & hierarchy

Selected track highlighted; optional clip highlight when playhead inside.

## Visual states

| State | Treatment |
|-------|-----------|
| Playing inside clip | Clip optional accent |
| Playing outside | Silent for samples |

## Copy & feedback

None

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] Selected track obvious during play

## Status

**Todo**
