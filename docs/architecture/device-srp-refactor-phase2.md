# Device SRP Refactoring — Phase 2: Migrate Persistence to Registry Dispatch

> **STATUS: COMPLETED** — Implemented in commit `2bcaf6b`. `projectFileToJson` and `parseProjectFileJson` now take `const DeviceRegistry&`. Persistence path uses `trackToVarPersistence`/`trackFromVarPersistence`. Snapshot path preserved for Phase 3 migration.

> Eliminate the old if/else-if chain from the persistence (file save/load) path by routing it through the existing `DeviceSlot`-based registry dispatch. The snapshot bridge path is preserved unchanged.

---

## A. Canonical Vocabulary

| Concept | Canonical name | Location | Notes |
|---------|----------------|----------|-------|
| Old serialization (anonymous) | `deviceToVar(DeviceState)` | `ProjectJson.cpp` lines 79–263 | Big if/else-if chain. **Kept** for snapshot bridge only. |
| Old deserialization (anonymous) | `deviceFromVar(var)` | `ProjectJson.cpp` lines 265–428 | Big if/else-if chain. **Kept** for snapshot bridge only. |
| Snapshot track serializer (anonymous) | `trackToVar(TrackState)` | `ProjectJson.cpp` lines 574–604 | Calls old `deviceToVar`. **Kept** for snapshot bridge. |
| Snapshot track deserializer (anonymous) | `trackFromVar(var)` | `ProjectJson.cpp` lines 606–633 | Calls old `deviceFromVar`. **Kept** for snapshot bridge. |
| Persistence track serializer (anonymous, NEW) | `trackToVarPersistence(TrackState, Registry)` | `ProjectJson.cpp` | Calls `audioapp::deviceToVar(DeviceState, Registry)` for each device. |
| Persistence track deserializer (anonymous, NEW) | `trackFromVarPersistence(var, Registry)` | `ProjectJson.cpp` | Calls `audioapp::deviceFromVar(var, Registry)` for each device var. |
| Registry-aware overload (existing) | `audioapp::deviceToVar(DeviceState, Registry)` | `ProjectJson.cpp` line 864 / `ProjectJson.hpp` line 33 | Converts DeviceState→DeviceSlot→slotToVar→JSON. |
| Registry-aware overload (existing) | `audioapp::deviceFromVar(var, Registry)` | `ProjectJson.cpp` line 871 / `ProjectJson.hpp` line 36 | Converts JSON→varToSlot→DeviceSlot→DeviceState. |
| Public-API persistence functions (modified) | `projectFileToJson(ProjectFileData, Registry)` | `ProjectJson.hpp` line 29 + `ProjectJson.cpp` line 880 | NEW registry parameter. |
| Public-API parse function (modified) | `parseProjectFileJson(string, ProjectFileData&, Registry)` | `ProjectJson.hpp` line 30 + `ProjectJson.cpp` line 885 | NEW registry parameter. |
| Engine registry getter (NEW) | `ProjectEngine::deviceRegistry()` | `ProjectEngine.hpp` | Public const accessor for `deviceRegistry_`. |
| Snapshot serializer (unchanged) | `snapshotToJson(ProjectSnapshot)` | `ProjectJson.hpp` line 38 + `ProjectJson.cpp` line 877 | No change. Still calls old `snapshotToVar` → old `trackToVar` → old `deviceToVar`. |
| Meter injection (unchanged) | `applyLiveDeviceMetersLocked(ProjectSnapshot&)` | `ProjectEngine.cpp` line 1078 | Writes meter values into TrackState.devices AFTER building snapshot. Only reaches snapshot path. |

---

## B. What Stays the Same (Critical Invariants)

| Invariant | Rationale |
|-----------|-----------|
| Audio thread code (`DeviceChain.cpp`, DSP modules) | Not touched. |
| `DeviceState.hpp`, `DeviceSlot.hpp`, `DeviceChain.hpp` | No changes. |
| All instance struct headers (`instances/*Instance.hpp`) | No changes. |
| `IDeviceType.hpp` — `slotToVar`/`varToSlot` signatures | No changes. Phase 1 complete. |
| `DeviceRegistry.hpp` — no new methods | No changes. |
| `TrackState` struct | Still `std::vector<DeviceState> devices;` — no change. |
| `ProjectSnapshot` struct | No change. |
| `ProjectFileData` struct | No change. |
| `snapshotToJson(ProjectSnapshot)` | Signature unchanged. Still uses old if/else-if chain through anonymous `snapshotToVar` → `trackToVar` → `deviceToVar(DeviceState)`. |
| Snapshot bridge JSON schema | Field names, nesting, defaults identical to current. The snapshot path still uses the old serialization code. |
| File JSON schema | **Identical** — the registry-aware overloads produce the same field names and structure as the old chain (they were extracted from it). Meters will be 0.0 in file JSON, which they already are in practice since meters are runtime-only values. |
| JSON pretty-printing | `projectFileToJson` uses `juce::JSON::toString(..., true)` (pretty). `snapshotToJson` uses `juce::JSON::toString(..., false)` (compact). Unchanged. |
| All existing device-type implementations | `slotToVar`/`varToSlot` already done. No changes needed. |

---

## C. What Changes

### C.1 New anonymous-namespace functions in `ProjectJson.cpp`

```cpp
// Persistence-only track serializers that use registry-aware dispatch.

juce::var trackToVarPersistence(const TrackState& track,
                                 const DeviceRegistry& registry) {
    juce::Array<juce::var> devices;
    devices.ensureStorageAllocated(static_cast<int>(track.devices.size()));
    for (const auto& device : track.devices) {
        devices.add(audioapp::deviceToVar(device, registry));
    }

    // ... same midiClips, sampleClips, automationClips as trackToVar ...
    // ... same top-level id/name/object construction ...

    return juce::var(object);
}

TrackState trackFromVarPersistence(const juce::var& value,
                                    const DeviceRegistry& registry) {
    TrackState track;
    if (const auto* object = value.getDynamicObject()) {
        track.id = varToString(object->getProperty("id"));
        track.name = varToString(object->getProperty("name"));
        if (const auto* devices = varArray(object->getProperty("devices"))) {
            for (const auto& deviceVar : *devices) {
                track.devices.push_back(
                    audioapp::deviceFromVar(deviceVar, registry));
            }
        }
        // ... same midiClips, sampleClips, automationClips logic ...
    }
    return track;
}
```

**Key difference from the existing `trackToVar`/`trackFromVar`:** The device serialization/deserialization calls `audioapp::deviceToVar(DeviceState, DeviceRegistry)` / `audioapp::deviceFromVar(var, DeviceRegistry)` instead of the anonymous-namespace `deviceToVar(DeviceState)` / `deviceFromVar(var)`.

The midi clip, sample clip, and automation clip serialization logic is **identical** (those are not being refactored).

### C.2 Modified `projectFileToVar` (anonymous namespace, `ProjectJson.cpp`)

Change line 793 from `tracks.add(trackToVar(track))` to `tracks.add(trackToVarPersistence(track, registry))`.

The function signature changes to accept a `const DeviceRegistry&` parameter:

```cpp
juce::var projectFileToVar(const ProjectFileData& project,
                            const DeviceRegistry& registry);
```

### C.3 Modified `parseProjectFileJson` (namespace audioapp, `ProjectJson.cpp`)

Change line 921 from `trackFromVar(trackVar)` to `trackFromVarPersistence(trackVar, registry)`.

The function signature changes to accept a `const DeviceRegistry&` parameter:

```cpp
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry);
```

### C.4 Updated public API in `ProjectJson.hpp`

```cpp
// OLD (unchanged for snapshot path):
std::string snapshotToJson(const ProjectSnapshot& snapshot);

// MODIFIED — added DeviceRegistry parameter:
std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry);
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry);
```

### C.5 New getter on `ProjectEngine`

```cpp
// In ProjectEngine.hpp, public section:
const DeviceRegistry& deviceRegistry() const { return deviceRegistry_; }
```

### C.6 Updated `EngineHost_commands.cpp`

```cpp
// Line 295-296 — save path:
std::string EngineHost::getProjectFileJson() const {
    return projectFileToJson(project_.toProjectFileData(),
                             project_.deviceRegistry());
}

// Lines 299-302 — load path:
bool EngineHost::loadProjectFileJson(const std::string& json) {
    ProjectFileData data;
    if (!parseProjectFileJson(json, data, project_.deviceRegistry()))
        return false;
    return project_.loadFromProjectFileData(data);
}
```

### C.7 File JSON output — meter fields

The old `deviceToVar(DeviceState)` writes `meterGainReductionDb` and `meterInputLevel` from the DeviceState fields. The registry-aware `deviceToVar(DeviceState, Registry)` goes through `DeviceSlot` — which has no meter fields — so the output writes 0.0 for meters.

**This is fine.** Meters are runtime values:
- In `toProjectFileData()` (ProjectEngine.cpp line 808), each device is converted via `deviceRegistry_.toSnapshotState(device)` which sets meter fields to defaults (0.0).
- In `applyLiveDeviceMetersLocked()` (ProjectEngine.cpp line 1078), meters are injected — but only into the snapshot path (`ProjectSnapshot`), not the persistence path (`ProjectFileData`).

So both old and new persistence paths produce `"meters": { "gainReductionDb": 0.0, "inputLevel": 0.0 }` for dynamics devices. The registry path is consistent with the current behavior.

---

## D. File Ownership

| File/path | Owner package | Allowed changes | Forbidden changes |
|-----------|--------------|-----------------|-------------------|
| `engine_juce/src/ProjectJson.cpp` | Package P0 | Add `trackToVarPersistence`/`trackFromVarPersistence`. Modify `projectFileToVar` signature and body. Modify `parseProjectFileJson` signature and body. | Remove or change `trackToVar`/`trackFromVar`/`deviceToVar(DeviceState)`/`deviceFromVar(var)`. Change `snapshotToVar`. |
| `engine_juce/include/audioapp/ProjectJson.hpp` | Package P0 | Change `projectFileToJson` and `parseProjectFileJson` signatures to add `DeviceRegistry` param. | Remove `snapshotToJson` or change its signature. |
| `engine_juce/include/audioapp/ProjectEngine.hpp` | Package P0 | Add `const DeviceRegistry& deviceRegistry() const` public getter. | Change `deviceRegistry_` member. Change any public API method signatures. |
| `engine_juce/src/EngineHost_commands.cpp` | Package P0 | Update `getProjectFileJson()` and `loadProjectFileJson()` to pass registry. | Change `snapshotToJson` call or `getProjectSnapshotJson()`. |
| `engine_juce/src/devices/*DeviceType.cpp` | NONE — read-only | None. All `slotToVar`/`varToSlot` already done in Phase 1. | No changes needed. |
| `engine_juce/include/audioapp/devices/IDeviceType.hpp` | NONE — read-only | None. Already has `slotToVar`/`varToSlot` as non-pure virtuals with `jassertfalse`. | No changes needed. |
| `engine_juce/include/audioapp/devices/DeviceRegistry.hpp` | NONE — read-only | None. | No changes needed. |
| `engine_juce/include/audioapp/DeviceState.hpp` | NONE — read-only | None. | No changes needed. |
| `engine_juce/include/audioapp/devices/DeviceSlot.hpp` | NONE — read-only | None. | No changes needed. |
| `engine_juce/include/audioapp/ProjectEngine.hpp` (TrackState) | NONE — read-only | None. `TrackState` stays as `std::vector<DeviceState>`. | No changes. |
| `engine_juce/tests/device_slot_serialization_test.cpp` | NONE — read-only | None. Already tests registry dispatch directly. | No changes needed. |
| `engine_juce/tests/project_serialization_test.cpp` | NONE — read-only | None. Uses `EngineHost` API which will be updated internally. | No changes needed. |
| `engine_juce/CMakeLists.txt` | NONE — read-only | None. No new test files. | No changes needed. |

---

## E. Vertical Work Packages

### Package P0 (Prerequisite): Update persistence path to registry dispatch

**Behavior:** The file save/load path (`projectFileToJson` / `parseProjectFileJson`) uses registry-aware `deviceToVar(DeviceState, Registry)` / `deviceFromVar(var, Registry)` instead of the old anonymous-namespace if/else-if chain. The snapshot bridge path is unchanged.

**Files changed (4 files):**
- `engine_juce/src/ProjectJson.cpp`
- `engine_juce/include/audioapp/ProjectJson.hpp`
- `engine_juce/include/audioapp/ProjectEngine.hpp`
- `engine_juce/src/EngineHost_commands.cpp`

**Specific changes per file:**

1. **`ProjectEngine.hpp` (line ~294)** — Add public getter:
```cpp
const DeviceRegistry& deviceRegistry() const { return deviceRegistry_; }
```

2. **`ProjectJson.hpp` (lines 29–30)** — Add `const DeviceRegistry&` parameter to both functions:
```cpp
std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry);
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry);
```

3. **`ProjectJson.cpp` — anonymous namespace:**
   - Add `trackToVarPersistence(const TrackState&, const DeviceRegistry&)` — copies current `trackToVar` body but replaces `deviceToVar(device)` with `audioapp::deviceToVar(device, registry)`
   - Add `trackFromVarPersistence(const juce::var&, const DeviceRegistry&)` — copies current `trackFromVar` body but replaces `deviceFromVar(deviceVar)` with `audioapp::deviceFromVar(deviceVar, registry)`
   - Change `projectFileToVar` signature to accept `const DeviceRegistry&` parameter
   - Change `projectFileToVar` body: replace `trackToVar(track)` with `trackToVarPersistence(track, registry)` (line 794)
   - Change `parseProjectFileJson` signature to accept `const DeviceRegistry&` parameter
   - Change `parseProjectFileJson` body: replace `trackFromVar(trackVar)` with `trackFromVarPersistence(trackVar, registry)` (line 921)

4. **`ProjectJson.cpp` — namespace audioapp (lines 880–882, 885–889):**
   - Update `projectFileToJson` signature:
```cpp
std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry) {
    return toStdString(juce::JSON::toString(projectFileToVar(project, registry), true));
}
```
   - Update `parseProjectFileJson` signature:
```cpp
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry) {
    // ... existing body, but passes `registry` through to internal helpers ...
    // Line 921 changes from trackFromVar(trackVar) to trackFromVarPersistence(trackVar, registry)
}
```

5. **`EngineHost_commands.cpp` (lines 295–302):**
```cpp
std::string EngineHost::getProjectFileJson() const {
    return projectFileToJson(project_.toProjectFileData(),
                             project_.deviceRegistry());
}

bool EngineHost::loadProjectFileJson(const std::string& json) {
    ProjectFileData data;
    if (!parseProjectFileJson(json, data, project_.deviceRegistry()))
        return false;
    return project_.loadFromProjectFileData(data);
}
```

**Canonical names used:** `DeviceRegistry`, `DeviceState`, `DeviceSlot`, `IDeviceType`, `TrackState`, `ProjectFileData`

**API contracts used:** `audioapp::deviceToVar(DeviceState, DeviceRegistry)` (existing), `audioapp::deviceFromVar(var, DeviceRegistry)` (existing)

**Dependencies:** None. Phase 1 is complete (all `slotToVar`/`varToSlot` implemented, dispatch functions exist, registry-aware overloads exist).

**Acceptance criteria:**
- All existing tests compile and pass
- `project_serialization_test.cpp` passes (save → parse → save → parse round-trip)
- `device_slot_serialization_test.cpp` passes (unchanged)
- Snapshot JSON (`getProjectSnapshotJson()`) is byte-identical to before
- File JSON (`getProjectFileJson()`) produces same structure and values (meters = 0.0 in both old and new paths)
- File JSON round-trip: save → parse → save → parse produces identical `ProjectFileData` (confirmed by existing test)

**Parallelization:** Single package (everything is sequential within this change).

---

### Package P1 (Future, out of scope for this contract): Remove old if/else-if chain

**Not part of this Phase 2.** After Phase 2, the old `deviceToVar(DeviceState)` / `deviceFromVar(var)` in the anonymous namespace are only called by the snapshot path (`snapshotToVar` → `trackToVar` → `deviceToVar`). They are NOT dead code.

To eventually remove them, the snapshot path must also be migrated. That requires handling meter injection — meters are set in `ProjectState` after building, then written to JSON. A future package could:
1. Add meter fields to `DeviceSlot` (not recommended — bloat)
2. Add meter fields as a separate array on `TrackState` (preferred — clean separation)
3. Inject meters at the JSON level (write meters after serialization)

---

## F. Parallelism and Dependencies

```
Package P0 (prerequisite — Phase 2 core)
  │
  └──→ Done

Package P1 (remove old chain — future, out of scope)
```

**Package P0** is a single sequential package. All 4 files must change together — there's no parallelism within Phase 2.

---

## G. API/Data Contracts

### G.1 Modified `projectFileToJson`

```cpp
// engine_juce/include/audioapp/ProjectJson.hpp

/// Serialize project to JSON for file persistence.
/// Uses registry-aware device dispatch. Meter values are preserved
/// as stored in DeviceState (typically 0.0 for persistence).
/// @param project The project file data to serialize.
/// @param registry Device registry for type lookup.
/// @returns Pretty-printed JSON string.
std::string projectFileToJson(const ProjectFileData& project,
                               const DeviceRegistry& registry);
```

### G.2 Modified `parseProjectFileJson`

```cpp
/// Parse project JSON from file persistence.
/// Uses registry-aware device dispatch for backward-compatible
/// deserialization of all device types.
/// @param json The JSON string to parse.
/// @param out [out] Parsed project file data.
/// @param registry Device registry for type lookup.
/// @returns true if parsing succeeded and format version matches.
bool parseProjectFileJson(const std::string& json,
                          ProjectFileData& out,
                          const DeviceRegistry& registry);
```

### G.3 New `ProjectEngine::deviceRegistry()` getter

```cpp
// engine_juce/include/audioapp/ProjectEngine.hpp (public section)

/// Expose the device registry for serialization dispatch.
/// The registry owns all IDeviceType instances and provides
/// type lookup for slotToVar/varToSlot dispatch.
const DeviceRegistry& deviceRegistry() const { return deviceRegistry_; }
```

### G.4 Internal `trackToVarPersistence` / `trackFromVarPersistence`

```cpp
// Anonymous namespace in ProjectJson.cpp (internal, not in header)

/// Serialize a track's devices using registry-aware dispatch.
/// Mid/sample/automation clip serialization is identical to trackToVar.
juce::var trackToVarPersistence(const TrackState& track,
                                 const DeviceRegistry& registry);

/// Deserialize a track's devices using registry-aware dispatch.
/// Mid/sample/automation clip deserialization is identical to trackFromVar.
TrackState trackFromVarPersistence(const juce::var& value,
                                    const DeviceRegistry& registry);
```

### G.5 Error handling

| Scenario | Behavior |
|----------|----------|
| Unknown device type in file persist (`deviceToVar(DeviceState, Registry)` slotFromSnapshot returns empty/missing type) | Returns `juce::var()` (null) — same as current registry-aware overload behavior |
| Unknown device type in file load (`deviceFromVar(var, Registry)`) | Returns default `DeviceState` with empty id — caller in `loadFromProjectFileData` skips it |
| Missing "id" or "type" fields in loaded device JSON | `audioapp::deviceFromVar` returns empty DeviceState, `trackFromVarPersistence` skips it |
| Registry is null/empty | `deviceToVar` returns empty var; `deviceFromVar` returns empty DeviceState |

---

## H. Tests

### H.1 Existing tests that must continue to pass

| Test file | What it validates | Why it must pass |
|-----------|-------------------|-----------------|
| `engine_juce/tests/project_serialization_test.cpp` | Save/load round-trip via EngineHost | Confirms persistence path works with registry dispatch |
| `engine_juce/tests/device_slot_serialization_test.cpp` | `slotToVar`/`varToSlot` round-trip for all 14 types | Unchanged — still tests same dispatch |
| `engine_juce/tests/device_registry_test.cpp` | Registry type lookup, default creation | No changes to registry |
| `engine_juce/tests/device_types_test.cpp` | Per-type param set, playback node build | No changes to device types |
| `engine_juce/tests/device_chain_test.cpp` | Audio DSP processing | No changes to audio thread |
| `engine_juce/tests/project_serialization_test.cpp` (round-trip check) | `projectFileToJson` + `parseProjectFileJson` round-trip | NEW: also confirms save→parse→save→parse produces identical size |

### H.2 Test update requirement

`project_serialization_test.cpp` calls `host.getProjectFileJson()` and then `parseProjectFileJson(json, parsed)`. Since the EngineHost API is unchanged (the registry is passed internally), the test needs **no changes**. It will automatically exercise the new persistence path.

**No new tests needed** for Phase 2. The existing tests cover:
- Registry dispatch works (device_slot_serialization_test)
- File persistence round-trip works (project_serialization_test)
- Snapshot path unchanged (implicitly tested by project_serialization_test snapshot check)

### H.3 Manual verification

1. Save a project, inspect the JSON output. Verify device JSON structure matches what `device_slot_serialization_test` produces.
2. Load the saved project. Verify all device parameters are restored.
3. Take a snapshot before and after the change. Verify they are byte-identical.

---

## I. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Snapshot path accidentally goes through registry dispatch**: If `trackToVar`'s implementation is mistakenly changed instead of creating `trackToVarPersistence` | High | Strictly add NEW functions. Do not modify existing `trackToVar`/`trackFromVar`. Code review must verify snapshot code path is untouched. |
| **Registry parameter added to public API**: Callers outside the engine must now pass a registry | Low | The only external caller is `EngineHost` which has access to `ProjectEngine::deviceRegistry()`. No external API consumers in this codebase. |
| **Const correctness**: `deviceRegistry()` returns `const DeviceRegistry&` but some registry methods may be non-const | Low | `find()`, `findForSlot()`, `findTypeForSlot()` are already const. Verify at compile time. |
| **Meters in file JSON change**: Old path wrote meters from DeviceState fields. Registry path writes meters via `DeviceSlot` → `slotToVar` which writes 0.0. | Low | Both paths produce the same result (meters are always 0.0 in `toProjectFileData()` which builds the ProjectFileData from internal DeviceSlots). Verify by comparing output. |
| **`trackToVarPersistence` diverges from `trackToVar`**: Future changes to clip serialization might update only one copy | Medium | Both functions share clip serialization logic. Consider extracting shared clip serialization into a helper, or leave a comment referencing the other function. Deduplication is a future concern. |
| **Compilation failure if `DeviceRegistry.hpp` not included in `ProjectEngine.hpp`** | Low | `DeviceRegistry.hpp` is already included in `ProjectEngine.hpp` (line 24). The getter will compile. |
| **ProjectEngine::deviceRegistry_ is constructed in initializer list, accessible after construction** | None | The member `deviceRegistry_{DeviceRegistry::createBuiltIn()}` is initialized before any use. The getter is safe. |
| **Old `deviceToVar(DeviceState)` vs registry-aware `deviceToVar(DeviceState, Registry)` overload resolution ambiguity** | None | The anonymous namespace version and the `audioapp::` namespace version have different parameter lists. `audioapp::deviceToVar(device, registry)` is unambiguous. |

---

## J. Implementation Order

### Phase 2 — Single package (P0), implement in this order:

1. **`ProjectEngine.hpp`**: Add `deviceRegistry()` public getter
2. **`ProjectJson.hpp`**: Update `projectFileToJson` and `parseProjectFileJson` signatures with `const DeviceRegistry&` parameter
3. **`ProjectJson.cpp` (anonymous namespace)**: Add `trackToVarPersistence` and `trackFromVarPersistence` functions
4. **`ProjectJson.cpp` (anonymous namespace)**: Update `projectFileToVar` signature and body to accept registry and use `trackToVarPersistence`
5. **`ProjectJson.cpp` (namespace audioapp)**: Update `projectFileToJson` and `parseProjectFileJson` to accept registry and pass it through
6. **`EngineHost_commands.cpp`**: Update `getProjectFileJson()` and `loadProjectFileJson()` to pass `project_.deviceRegistry()`

### Verification order:

1. Compile (all targets)
2. Run `device_slot_serialization_test` (should pass — unchanged)
3. Run `project_serialization_test` (should pass — uses EngineHost which passes registry internally)
4. Run all other existing tests (should pass — no behavior changes)
5. Manual: compare snapshot JSON before/after (must be identical)
6. Manual: compare file JSON before/after (must be identical structure, meter values same)

---

## K. Life After Phase 2

After Phase 2, the call graph is:

```
snapshotToJson
  └→ snapshotToVar (anonymous)
       └→ trackToVar (anonymous)           ← unchanged
            └→ deviceToVar(DeviceState)     ← OLD if/else-if chain, snapshot-only

projectFileToJson
  └→ projectFileToVar (anonymous)
       └→ trackToVarPersistence (anonymous)  ← NEW
            └→ audioapp::deviceToVar(DeviceState, Registry)  ← registry dispatch

parseProjectFileJson
  └→ trackFromVarPersistence (anonymous)     ← NEW
       └→ audioapp::deviceFromVar(var, Registry)  ← registry dispatch
```

The old if/else-if chain (`deviceToVar(DeviceState)` / `deviceFromVar(var)` lines 79–428) is now **snapshot-only code**. It is NOT dead code and must NOT be removed.

**Future work (Phase 3):**
- To eventually remove the old chain, migrate the snapshot path. Options:
  - Add meter arrays to `TrackState` separate from device parameters
  - Serialize meters as a separate step in the snapshot path
  - Add meter fields to `DeviceSlot` (requires changes to audio thread snapshot building)
- This is intentionally out of scope for Phase 2.

---

## L. Worker Instructions for Implementation Agent

The implementation worker for Package P0 MUST:

1. **Read the current code** — understand `ProjectJson.cpp` structure (anonymous namespace, `namespace audioapp` block).
2. **Do NOT modify** `trackToVar`, `trackFromVar`, `deviceToVar(DeviceState)`, `deviceFromVar(var)`, or `snapshotToVar` in the anonymous namespace. These are the snapshot path — untouched.
3. **Create new functions** `trackToVarPersistence` and `trackFromVarPersistence` in the anonymous namespace. Copy the clip serialization logic (midi, sample, automation) verbatim from the existing functions. Only change the device serialization/deserialization calls.
4. **Update signatures** for `projectFileToVar`, `projectFileToJson`, and `parseProjectFileJson` to accept `const DeviceRegistry&`.
5. **Pass the registry** through the call chain: `projectFileToJson` → `projectFileToVar` → `trackToVarPersistence` → `audioapp::deviceToVar(DeviceState, Registry)`.
6. **Include `#include "audioapp/devices/DeviceRegistry.hpp"`** in `ProjectEngine.hpp` if not already present (verify — line 24 already includes it).
7. **Keep `snapshotToJson` signature unchanged** — it must not take a registry.
8. **Verify compilation** — all 4 files must be updated together to compile.
9. **Stop and report** if any contract item is ambiguous or missing.

---

## M. Success Criteria (Checklist)

- [ ] `ProjectEngine` exposes `const DeviceRegistry& deviceRegistry() const`
- [ ] `projectFileToJson` takes `const DeviceRegistry&` parameter
- [ ] `parseProjectFileJson` takes `const DeviceRegistry&` parameter
- [ ] `trackToVarPersistence` and `trackFromVarPersistence` exist in anonymous namespace
- [ ] `projectFileToVar` uses `trackToVarPersistence` (not `trackToVar`)
- [ ] `parseProjectFileJson` uses `trackFromVarPersistence` (not `trackFromVar`)
- [ ] `snapshotToVar` still uses old `trackToVar` → old `deviceToVar(DeviceState)` (snapshot path 100% unchanged)
- [ ] `snapshotToJson` signature unchanged
- [ ] All existing C++ tests pass unchanged (0 modifications to test files)
- [ ] `project_serialization_test.cpp` pass (save/load/save round-trip works)
- [ ] File JSON structure is identical before/after (meters = 0.0 in both)
- [ ] Snapshot JSON structure is byte-identical before/after
- [ ] Audio thread code (`DeviceChain.cpp`, DSP modules) has zero changes
- [ ] `DeviceState.hpp`, `DeviceSlot.hpp`, instance structs have zero changes
- [ ] `device_engine_juce/tests/` files have zero changes