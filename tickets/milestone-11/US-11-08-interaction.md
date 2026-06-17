# US-11-08-interaction: Factory presets + library — Interaction

## Type

Interaction

## Parent feature

[US-11-08](US-11-08-factory-presets-content-library.md)

## Entry points

- Device tool rail → Library
- Shell library tab (if synth selected)

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Open library | Rail icon | Fly-in | categories |
| Tap preset | List row | Audio + param sync | batch setDeviceParameter |
| Wrong device selected | Tap preset | Snackbar | no-op |

## Error paths

| Condition | UX |
|-----------|-----|
| No subtractive synth on track | “Select a subtractive synth first” |

## Demo script (interaction-only)

- Library → Warm Pad → verify strip knobs move

## Acceptance criteria

- [ ] Preset apply < 500ms perceived

## Status

**Todo**
