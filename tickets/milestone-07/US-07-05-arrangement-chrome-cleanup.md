# US-07-05 — Arrangement chrome cleanup

## Summary

Remove debug/engine header and arrangement toolbar. Move transport info to top, project I/O to Settings, add virtual “Add track” row, and track long-press clip menu.

## Acceptance

- [ ] No `Engine: pong` header
- [ ] Top bar shows BPM + app version (replaces engine header)
- [ ] Save / Open project in Settings tab
- [ ] Arrangement toolbar removed (no title row, no inline Add MIDI / Track)
- [ ] Virtual last track row adds a new track (above master)
- [ ] Long-press track → Add MIDI Clip / Add Audio Clip

## Touchpoints

- `app_flutter/lib/app/daw_shell.dart`
- `app_flutter/lib/features/arrangement/arrangement_view.dart`
- `app_flutter/lib/features/settings/settings_screen.dart`
- `app_flutter/lib/features/transport/transport_bar.dart`

[interaction](US-07-05-interaction.md) · [ux-ui](US-07-05-ux-ui.md)
