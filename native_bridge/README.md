# Native bridge

Android JNI and Flutter plugin wiring lives here.

## Layout

```text
native_bridge/
  include/     C++ bridge API
  src/         BridgeHost command dispatch
  android/     Kotlin/Java MethodChannel handler (Milestone 01)
```

## Status

Milestone 00: C++ `BridgeHost` with `ping`, `play`, `stop` stubs. Kotlin registration in `app_flutter/android` completes the Flutter path in Milestone 01.

See [flutter_native_bridge.md](../docs/bridge/flutter_native_bridge.md).
