# US-00-03: Edge-to-edge DAW shell layout

## Type

Bug / UX

## Milestone

Milestone 00 — Foundation

## User story

As a **user**, the DAW shell uses the full screen in portrait and landscape, including behind the system navigation bar and display cutout (inline camera), without empty margins around the UI.

## Goal

Fix letterboxing above the Android navigation bar and beside the punch-hole camera on physical devices.

## Background

- [mobile_ui_guidelines.md](../../docs/guidelines/mobile_ui_guidelines.md) — System insets
- Root cause: `SafeArea` wrapped the entire shell and Android did not opt into edge-to-edge / cutout layout.

## Scope

- Android edge-to-edge window (`WindowCompat.setDecorFitsSystemWindows(false)`)
- Transparent system bars and `shortEdges` cutout mode
- Flutter `SystemUiMode.edgeToEdge`
- Replace full-shell `SafeArea` with selective insets (top status, bottom transport only)
- Main timeline/device strip bleed horizontally under cutout

## Out of scope

- Per-screen inset tuning for future fullscreen editors (M04/M07)
- iOS notch handling (Android-first device target)

## Acceptance criteria

- [x] Portrait: dark shell background extends to bottom of display (behind gesture bar)
- [x] Landscape: shell extends to left/right edges and behind inline camera cutout
- [x] Transport controls remain tappable above gesture navigation (bottom inset on transport only)
- [x] Documented in mobile UI guidelines
- [x] Widget tests still pass

## Tests required

- [x] Widget tests
- [ ] Manual smoke on Moto g86 (portrait + landscape)

## User-visible result

No unused black/empty bands above the nav bar or beside the front camera; DAW regions fill the phone display.

## Demo script (on-device, ~30s)

1. Portrait: no letterbox above nav bar; transport tappable.
2. Landscape: content extends behind cutout; timeline usable.

## Depends on

US-00-02

## Status

**Done**
