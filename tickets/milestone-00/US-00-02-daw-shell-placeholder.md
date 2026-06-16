# US-00-02: DAW shell placeholder

## Type

Feature

## Milestone

Milestone 00 — Foundation

## User story

As a **user**, I open the app and see a clear DAW layout so I know where the timeline, transport, and device strip will live.

## Goal

Placeholder DAW shell — visible regions, no fake audio.

## Background

- [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md)
- [flutter_native_bridge.md](../../docs/bridge/flutter_native_bridge.md)

## Scope

- Arrangement/timeline area with placeholder tracks
- Transport bar (Play/Stop UI)
- Device strip (visible when track selected)
- Dark flat theme
- Bridge `ping` → `pong` from native

## Out of scope

- Audible Play/Stop (M01)
- Real project/track data (M02)

## Acceptance criteria

- [x] App opens to labeled arrangement region
- [x] Transport shows Play/Stop controls
- [x] Selecting a track shows device strip with placeholder device card
- [x] Engine bridge status shows connected (`pong`) on device
- [x] Widget tests cover shell layout

## Tests required

- [x] Widget tests (`app_flutter/test/widget_test.dart`)
- [x] Manual smoke on physical device

## User-visible result

Recognizable minimal DAW shell on phone or emulator.

## Documentation updates

- [x] flutter_guidelines.md structure

## Status

**Done**
