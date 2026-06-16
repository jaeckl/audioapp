# Architecture Overview

## Summary

Monorepo containing three primary code areas:

| Layer | Location | Responsibility |
|-------|----------|----------------|
| UI | `app_flutter/` | Layout, editing, transport UI, state display |
| Engine | `engine_juce/` | Audio callback, graph, project model, DSP |
| Bridge | `native_bridge/` | Command dispatch, event streaming |

## Data flow

```text
Flutter UI
    │ commands (MethodChannel)
    ▼
Native bridge (non-realtime thread)
    │ validated commands
    ▼
C++ project engine
    │ graph snapshots / scheduling
    ▼
JUCE audio callback (realtime thread)
    │ audio out
    ▼
Android audio output
```

State flows upward as throttled snapshots/events — never from the audio thread directly to Flutter.

## Authoritative state

The C++ project engine owns:

- tracks, clips, devices, routing
- transport position and BPM
- parameter values
- serialization

Flutter holds display state derived from engine snapshots. Commands are sent to C++; Flutter does not maintain a parallel project model.

## Graph-based engine

Audio and MIDI flow through a directed graph:

- **Track** → **DeviceChain** → master output
- Devices are internal built-in modules (oscillator, sampler, gain, etc.)
- Graph mutations are applied at safe points; the audio thread reads immutable snapshots

## Platform scope (MVP)

- **Android** — first target
- **iOS** — planned; abstractions should not block it
- **Desktop** — not MVP; engine design stays portable where practical
- **No server** — local projects only

## Related documents

- [Realtime audio rules](realtime_audio_rules.md)
- [Project model](project_model.md)
- [Audio graph](audio_graph.md)
- [Device model](device_model.md)
- [JUCE dependency](juce_dependency.md)
- [Flutter/native bridge](../bridge/flutter_native_bridge.md)

## ADRs

- [ADR-0001](../adr/ADR-0001-flutter-juce-architecture.md) — Flutter + JUCE
- [ADR-0002](../adr/ADR-0002-android-first-mvp.md) — Android-first MVP
- [ADR-0003](../adr/ADR-0003-graph-based-engine.md) — Graph-based engine
- [ADR-0004](../adr/ADR-0004-no-external-plugin-formats.md) — No external plugins
- [ADR-0005](../adr/ADR-0005-diffable-project-format.md) — Diffable project format
- [ADR-0006](../adr/ADR-0006-os-bridge-project-files.md) — OS bridge owns file I/O (hybrid)
