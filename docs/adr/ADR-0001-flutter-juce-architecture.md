# ADR-0001: Flutter + JUCE Architecture

## Status

Accepted

## Context

We need a mobile DAW with a rich touch UI and professional low-latency audio. Web technologies cannot meet realtime DSP requirements on mobile. A single-language UI framework plus a proven audio library reduces risk.

## Decision

- **Flutter** for all UI and user interaction on Android (iOS later).
- **JUCE (C++)** for audio callback, DSP, project model authority, and serialization core.
- **Native bridge** (MethodChannel + EventChannel) between Flutter and C++.

No server backend in MVP.

## Consequences

**Easier:** Proven audio path, portable engine, fast UI iteration in Flutter.

**Harder:** Bridge maintenance, two-language codebase, Android NDK/Gradle integration.

**Risks:** Bridge latency for state sync; mitigated by throttling and authoritative C++ model.
