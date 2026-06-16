# Flutter Guidelines

## Principles

- Engine state is authoritative; Dart holds display projections
- No production audio generation in Dart
- Functional UI before polish

## Structure

```text
app_flutter/lib/
  main.dart
  app/
  features/
    arrangement/
    transport/
    device_strip/
  bridge/
  theme/
```

## State

- Prefer explicit state classes over ad-hoc `setState` in large widgets
- Throttle engine-driven rebuilds (transport, playhead)
- Avoid rebuilding entire timeline on every event

## Bridge

- Single `EngineBridge` service wrapping MethodChannel / EventChannel
- Parse events in one place

## Layout

- Phone: track area + bottom device strip priority
- Tablet: adaptive multi-panel when space allows
- See [mobile_ui_guidelines.md](mobile_ui_guidelines.md)

## Tests

- Widget tests for shell and transport
- Integration tests for bridge flows (Milestone 01+)
