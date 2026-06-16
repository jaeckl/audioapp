# Native bridge

Android JNI and Flutter MethodChannel wiring.

## Layout

```text
native_bridge/
  include/     C++ BridgeHost command dispatch
  src/         BridgeHost.cpp

app_flutter/android/app/src/main/
  kotlin/.../MainActivity.kt         MethodChannel + SAF pickers
  kotlin/.../ProjectArchiveStore.kt  Zip archive I/O (ADR-0006)
  cpp/jni_bridge.cpp                 JNI entry points
```

## Responsibilities (ADR-0006)

| Component | Role |
|-----------|------|
| `BridgeHost` | Engine commands; JSON serialize API for Android JNI |
| `ProjectArchiveStore` (Kotlin) | Build/read `.audioapp.zip` via SAF document URIs |
| `ProjectArchive.cpp` (C++) | Zip archive I/O on desktop / tests |
| `ProjectJson.cpp` (C++) | `project.json` schema (all platforms) |

See [flutter_native_bridge.md](../docs/bridge/flutter_native_bridge.md) and [ADR-0006](../docs/adr/ADR-0006-os-bridge-project-files.md).
