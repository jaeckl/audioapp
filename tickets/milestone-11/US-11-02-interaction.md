# US-11-02-interaction: Subtractive synth picker & strip — Interaction

## Type

Interaction

## Parent feature

[US-11-02](US-11-02-subtractive-synth-device-picker-strip.md)

## Entry points

- Device strip → Add instrument
- Play tab (live notes)
- Transport play (MIDI clip)

## Interaction map

| User action | Control | Feedback | Result |
|-------------|---------|----------|--------|
| Add Subtractive Synth | Picker row | Strip appears | `addDevice` subtractive_synth |
| Adjust cutoff | Knob | Label + audio | setDeviceParameter |
| Play pads | Play surface | Audio | noteOn → 8-voice poly |
| Save project | Settings/shell | Success toast | JSON round-trip |

## Cancel & back

- Picker dismiss → no device added

## Error paths

| Condition | UX | Recovery |
|-----------|-----|----------|
| Engine not ready | Shell error line | Retry after bridge connect |

## Demo script (interaction-only)

- Add synth → pad chord → tweak cutoff → save → reload

## Acceptance criteria

- [ ] ≤ 3 taps from strip to hearing sound
- [ ] Oscillator still addable on another track

## Status

**Todo**
