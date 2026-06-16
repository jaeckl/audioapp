# Mobile Clip-Launcher DAW

A native mobile DAW with a **Flutter UI** and a **JUCE/C++ realtime audio engine**. Android-first MVP.

## Architecture

- **Flutter** — UI, gestures, timeline, device strip, project interaction
- **JUCE/C++** — authoritative project model, audio graph, transport, DSP
- **Native bridge** — Flutter MethodChannel commands + event stream to Dart

See [AGENT.md](AGENT.md) for full product and development rules.

## Repository layout

```text
app_flutter/      Flutter Android app
engine_juce/      JUCE/C++ audio engine
native_bridge/    Flutter ↔ native bridge (Android)
docs/             Architecture, ADRs, guidelines
tickets/          Milestone work tickets
tools/            Build and verification scripts
fixtures/         Test projects and samples
```

## Quick start (Windows — recommended)

Local Flutter + Android SDK setup is documented in **[docs/guidelines/windows_android_setup.md](docs/guidelines/windows_android_setup.md)**.

```powershell
flutter doctor -v
cd app_flutter
flutter run          # phone or emulator connected
```

**Physical device** is the best way to test audio. See the guide for USB debugging steps.

### Dev Container (optional)

For Linux/CI parity only — not the primary Windows workflow. See [.devcontainer/README.md](.devcontainer/README.md).

Native engine (from repo root):

```bash
cmake -S engine_juce -B build/engine -G Ninja
cmake --build build/engine
```

## Development modes (Android)

1. **Build in container, run on host/device** — Container builds APK; install on a physical device or host-managed emulator via ADB.
2. **Container with ADB** — Optional ADB forwarding; not required for MVP.

Emulator acceleration inside the container is not assumed.

## JUCE dependency

JUCE is fetched via CMake FetchContent (pinned version). See [docs/architecture/juce_dependency.md](docs/architecture/juce_dependency.md).

## Testing

```bash
./tools/test_all.sh
```

## Documentation

- [Roadmap & user stories](docs/milestones/roadmap.md)
- [Tickets](tickets/README.md)
- [Architecture overview](docs/architecture/overview.md)
- [Realtime audio rules](docs/architecture/realtime_audio_rules.md)
- [Flutter/native bridge](docs/bridge/flutter_native_bridge.md)

## Current milestone

**Milestone 01** — First real sound ([roadmap](docs/milestones/roadmap.md), [US-01-01](tickets/milestone-01/US-01-01-play-hears-juce-audio.md)).

Milestone 00 (foundation) is complete.

## License

TBD.
