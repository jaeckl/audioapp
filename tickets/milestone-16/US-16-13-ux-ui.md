# US-16-13-ux-ui: Flutter modulation persistence test — UX & UI

## Type

UX / UI

## Parent feature

[US-16-13](US-16-13-modulation-test-coverage.md)

## Design intent

Flutter test: save/load project with LFOs and modulation edges preserves data through bridge.

## Layout & hierarchy

N/A — Flutter unit test

## Visual states

| State | Treatment |
|-------|-----------|

## Copy & feedback



## Accessibility & mobile

- Minimum 44×44dp touch targets for primary actions
- Dark DAW theme per [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- Edge-to-edge rules per US-00-03 where applicable

## Acceptance criteria (visual)

- [x] LFO + modEdge persist through save/load
- [x] Multiple LFOs + edges survive save/load
- [x] Removing LFO before save means absent after load
- [x] Removing edge before save means absent after load

## Status

**Done**
