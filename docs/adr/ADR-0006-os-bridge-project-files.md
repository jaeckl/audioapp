# ADR-0006: OS Bridge Owns Project File I/O (Hybrid)

## Status

Accepted

## Context

Projects are `.audioapp.zip` archives with `project.json` inside ([ADR-0005](ADR-0005-diffable-project-format.md)). The C++ engine is the authoritative project model; Flutter is the UI.

Early Android attempts used C++ filesystem I/O and folder-tree SAF pickers. Issues included path mismatches, JSON parse bugs, and poor UX (“Use this folder”). **Zip archives** with standard save/open file dialogs are the on-disk format.

## Decision

**Hybrid split:**

| Platform | Archive I/O | Serialize / deserialize |
|----------|-------------|-------------------------|
| **Android** | Kotlin `ProjectArchiveStore` + SAF (`CreateDocument` / `OpenDocument`) | C++ JNI (`nativeGetProjectFileJson`, `nativeLoadProjectFileJson`) |
| **Desktop** (JUCE shell, tests) | C++ `saveProjectToArchive` / `loadProjectFromArchive` | Same `projectFileToJson` / `parseProjectFileJson` |
| **Future iOS** | Swift OS bridge (planned) | C++ via FFI |

Rules:

1. **C++ engine** owns project state and `project.json` schema.
2. **C++ does not** open archives on Android; it only returns or accepts JSON text.
3. **OS bridge** shows **save/open file** dialogs for `*.audioapp.zip`, builds or reads zip bytes, owns URI permissions.
4. **Flutter** exposes Save/Load UI; no duplicate project mutation logic.
5. `BridgeHost::handleCommand("saveProject" | "loadProject")` is **desktop only** (`#ifndef __ANDROID__`).

Default save filename: `project.audioapp.zip`.

## Consequences

**Easier:** Correct SAF UX; single portable file; clear OS ownership.

**Harder:** Two I/O paths (Kotlin zip vs C++ zip).

**Mitigations:** Shared archive layout; `project_archive_test.cpp`; `ProjectArchiveStore` on Android.

## References

- [project_model.md](../architecture/project_model.md)
- [flutter_native_bridge.md](../bridge/flutter_native_bridge.md)
