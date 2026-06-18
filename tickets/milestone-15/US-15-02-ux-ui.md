# US-15-02-ux-ui: Kick bench layout + kickModel engine branch — UX & UI

## Type

UX / UI

## Parent feature

[US-15-02](US-15-02-kick-bench-kick-model.md)

## Design intent

One-screen kick shaping — preview, model picker, all knobs — no tab hunting.

## Layout & hierarchy

~480px card: left 2/3 preview + 1/3 model segment (808/909/Analog); right 2×3 knob grid.

## Visual states

| State | Treatment |
|-------|-----------|
| 808 active | All knobs live; preview animates on drag |
| 909/Analog | Segment visible; disabled in v1 |
| Output rail | Gain + Vel sens off-card (US-15-03) |

## Copy & feedback

- 808
- 909
- Analog
- Pitch
- Punch
- Tone
- Click
- Decay

## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [ ] No tabs on kick card
- [ ] Preview ~2/3 left column height
- [ ] Six 808 params visible without tab tap

## Status

**Todo**
