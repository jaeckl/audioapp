# US-07-04 — Mixer view with track_gain device

## Summary

Mixer tab shows one column per track plus master, each with a volume slider. Per-track volume is a `track_gain` device (always last on the track chain), hidden from the arrangement FX/device strip.

## Acceptance

- [ ] `track_gain` device added automatically on each track
- [ ] `gain` parameter 0–1 applied in `readMasterMix`
- [ ] Master gain on `MasterTrackState` / `setMasterGain`
- [ ] Device strip filters out `track_gain`
- [ ] Mixer UI: horizontal scroll of vertical sliders

## Touchpoints

- `engine_juce/src/ProjectEngine.cpp`
- `app_flutter/lib/features/mixer/mixer_view.dart`
- `app_flutter/lib/bridge/project_snapshot.dart`

[interaction](US-07-04-interaction.md) · [ux-ui](US-07-04-ux-ui.md)



## Companion stories

- [UX/UI](US-07-04-ux-ui.md)
- [Interaction](US-07-04-interaction.md)

## Status

**Done**
