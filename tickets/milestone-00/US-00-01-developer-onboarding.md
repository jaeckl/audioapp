# US-00-01: Developer onboarding

## Type

Feature / Documentation

## Milestone

Milestone 00 — Foundation

## User story

As a **developer**, I can set up the repo on Windows/Android and build the app and engine skeleton so the team has a reproducible starting point.

## Goal

Monorepo, docs, local toolchain, build scripts, and verification paths without claiming fake audio.

## Background

- [AGENT.md](../../AGENT.md) §15 Milestone 00, §19 First Task
- [windows_android_setup.md](../../docs/guidelines/windows_android_setup.md)
- [roadmap.md](../../docs/milestones/roadmap.md)

## Scope

- Repo structure, `AGENT.md`, `README.md`, `.gitignore`
- Architecture docs, ADRs, guidelines
- `engine_juce/` CMake skeleton, `native_bridge/` skeleton
- `tools/doctor.sh`, `adb_phone_check.ps1`, Windows setup guide
- Optional `.devcontainer/` (not primary on Windows)
- Flutter builds on Android; engine configures with CMake

## Out of scope

- Real audio output (M01)
- CI cloud runners

## Acceptance criteria

- [x] Repo structure matches AGENT.md layout
- [x] Architecture docs and five ADRs exist
- [x] `flutter build apk --debug` succeeds on Windows
- [x] `engine_juce` CMake configure/build documented or verified in dev container
- [x] `flutter doctor` Android toolchain green on host
- [x] Physical device deploy verified (`flutter run -d <device>`)

## Tests required

- [x] Manual: `flutter build apk --debug`
- [x] Manual: `flutter run` on device
- [ ] Engine smoke test in CI/local script (when C++ toolchain on host)

## User-visible result

N/A (developer-facing). User can install debug APK.

## Realtime/performance notes

None for skeleton.

## Demo script (developer, ~15 min)

1. Clone repo → follow `windows_android_setup.md`.
2. `flutter build apk --debug` succeeds.
3. `flutter run` on physical device installs and opens shell.

## Documentation updates

- [x] README.md
- [x] docs/guidelines/windows_android_setup.md

## Status

**Done**
