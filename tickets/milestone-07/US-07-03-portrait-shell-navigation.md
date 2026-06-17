# US-07-03 — Portrait shell bottom navigation

## Summary

Replace the transport play button in the bottom bar with a four-tab shell: **Arrangement**, **Mixer**, **Library**, **Settings**. Play/Stop lives on the playhead in the arrangement view.

## Acceptance

- [ ] Bottom `NavigationBar` with Arrangement, Mixer, Library, Settings
- [ ] Arrangement tab shows the existing timeline + device strip + BPM/position bar (no play icon in transport)
- [ ] Play/Stop control attached to the bottom of the playhead line in arrangement
- [ ] Library tab embeds sample library (import + insert)
- [ ] Settings tab shows placeholder

## Touchpoints

- `app_flutter/lib/app/daw_shell.dart`
- `app_flutter/lib/features/arrangement/arrangement_view.dart`
- `app_flutter/lib/features/transport/transport_bar.dart`
- `app_flutter/lib/features/sample_library/sample_library_screen.dart`

[interaction](US-07-03-interaction.md) · [ux-ui](US-07-03-ux-ui.md)



## Companion stories

- [UX/UI](US-07-03-ux-ui.md)
- [Interaction](US-07-03-interaction.md)

## Status

**Done**
