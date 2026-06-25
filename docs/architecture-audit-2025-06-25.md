# DAW Architecture Audit — June 25, 2026

## Scope

Full-stack audit of a DAW/audio-production application with C++/JUCE engine, Flutter
frontend, and native bridge. Investigates whether the recent SRP refactor created
meaningful architectural boundaries or merely split flat code into smaller pieces.

## Key Verdict

**SRP refactor is REAL in the engine core, SUPERFICIAL in the bridge and Flutter
layers.**

The engine SRP refactor successfully introduced `IDeviceType`, `DeviceProcessor`,
per-device parameter variants, `ProcessorArena`, and double-buffered modulation.
However, the refactor stopped at the engine boundary:

- `AutomationPlayback.cpp` (1100L) remains a monolithic megafile with 4 switch ladders
- `DeviceChainAutomationModulation.cpp` duplicates per-device dispatch logic
- Bridge layer: flat 40+ command if-chain, no protocol version, full-snapshot responses
- Flutter layer: 1720-line god widget `DawShell`, string-typed params, DTO-as-ViewModel

**The Flutter/bridge layer is the current architectural bottleneck.**

## Architecture Map

```
┌─────────────────────────────────────────────────────┐
│                    Flutter UI                         │
│  DawShell (1720L god widget)                         │
│  ├─ setState(_snapshot) — full state replacement     │
│  ├─ _buildDevice() — 22-case switch per device type  │
│  ├─ param strings: 'gain','filterCutoff' — untyped   │
│  └─ _transportStopwatch for playhead animation       │
│  Per-feature widgets + DTO-as-ViewModel usage         │
│  State: no Provider/Riverpod. Pure setState.          │
│  Bridge: MethodChannel only. No EventChannel.         │
└──────────────┬──────────────────────────────────────┘
               │  MethodChannel("com.audioapp.daw/engine")
               │  40+ command methods, no protocol version
               │  EVERY mutation returns full ProjectSnapshot
               ▼
┌─────────────────────────────────────────────────────┐
│                Kotlin Bridge (MainActivity.kt)         │
│  MethodChannel handler → JSON string → JNI call       │
│  SAF file pickers for save/load/import                │
└──────────────┬──────────────────────────────────────┘
               │  JNI call
               ▼
┌─────────────────────────────────────────────────────┐
│              C++ Bridge (BridgeHost.cpp)               │
│  40+ command if-chain, each returns full snapshot     │
│  BridgeHost owns singletons: engine()                 │
│  No EventChannel support → no streaming               │
└──────────────┬──────────────────────────────────────┘
               │  Direct method call
               ▼
┌─────────────────────────────────────────────────────┐
│              Native Engine (ProjectEngine)             │
│  ┌─────────────────────────────────────┐              │
│  │ Control Thread                       │              │
│  │  TrackRepository, ClipRepository     │              │
│  │  DeviceRegistry (22 types)           │              │
│  │  AutomationClipStore (global)        │              │
│  │  ModulationGraph (global)            │              │
│  │  rebuildTrackPlaybackLocked()        │              │
│  └─────────┬───────────────────────────┘              │
│            │  shared_mutex / atomic                    │
│            ▼                                           │
│  ┌─────────────────────────────────────┐              │
│  │ Audio Thread (processBlock)          │              │
│  │  shared_lock(mutex_)                  │              │
│  │  DeviceChainOrchestrator             │              │
│  │  ├─ DeviceProcessor::process()       │              │
│  │  ├─ applyAutomation → overwrite      │              │
│  │  ├─ applyModulation → additive       │              │
│  │  └─ thread_local scratch buffers     │              │
│  └─────────────────────────────────────┘              │
│                                                       │
│  Serialization: projectFileToVar vs snapshotToVar      │
│  Pretty JSON (persist) / compact JSON (bridge)         │
│  ZIP stored archive (.audioapp)                        │
└─────────────────────────────────────────────────────┘
```

## Critical Findings

### 1. shared_lock in Audio Thread — CRITICAL

**Path:** `engine_juce/src/ProjectEngine.cpp:594`

```cpp
std::shared_lock<std::shared_mutex> lock(mutex_);
mixAtPlayheadBeatStereo(...)
```

The audio callback acquires a `shared_lock` on every process call. If the control thread
holds an exclusive lock (e.g., during `addDevice`, `removeDevice`, `saveProject`), the
audio thread blocks. At 48 kHz / 512-sample buffer (~10.7 ms deadline), any control
operation that exceeds this causes a dropout.

### 2. God Widget DawShell — CRITICAL

**Path:** `app_flutter/lib/app/daw_shell.dart` — 1720 lines

Holds 30+ fields mixing UI state (tab selection, library open state, arrangement scroll
position), engine state (playing, bpm, loop settings), transport sync state (stopwatch,
ticker, timers), bridge callbacks, and device routing. Violates every SRP guideline.

### 3. Full Snapshot on Every Param Change — HIGH

**Path:** `native_bridge/src/BridgeHost.cpp:79-87`

Every `setDeviceParameter` call returns a complete `ProjectSnapshot` serialized as JSON.
A slider drag (10-100 values/second) causes full engine serialization + JSON parse +
Flutter widget rebuild for every intermediate value. This is ~90% wasted traffic.

### 4. MIDI Recording Clip Placement Bug — HIGH

**Path:** `engine_juce/src/ProjectEngine_live.cpp:182`

```cpp
clipStart = transport_.playheadBeats(); // WRONG — should use captureStartSample_
```

When committing a MIDI capture, `clipStart` is set to the current transport playhead
position, not the sample-accurate capture start time. Recorded clips misalign by the
time between pressing record and playing the first note.

### 5. No EventChannel — HIGH

**Path:** `app_flutter/android/app/src/main/kotlin/com/audioapp/daw/MainActivity.kt`

The Kotlin bridge only registers a `MethodChannel`. There is no `EventChannel` for
streaming high-frequency data (meters, transport position, waveform updates).
Everything is poll-based or piggybacks on command responses.

## Finding Summary

| Area | Critical | High | Medium | Low |
|------|----------|------|--------|-----|
| Bridge | 0 | 5 | 3 | 0 |
| Flutter | 2 | 3 | 4 | 0 |
| Engine (non-realtime) | 0 | 2 | 3 | 0 |
| Engine (realtime) | 1 | 1 | 0 | 0 |
| Recording | 0 | 1 | 1 | 0 |
| Serialization | 0 | 1 | 7 | 1 |
| **Total** | **3** | **13** | **18** | **1** |

## Priority Migration Plan

### Stage 1: Protect Audio Boundaries
- Replace `shared_lock` with double-buffered publish/subscribe for track playback
- Use atomic pointer swap for render graph
- Files: ProjectEngine.cpp, ProjectEngine.hpp
- Risk: Medium, impact: High

### Stage 2: Fix Recording Bugs
- Fix clipStart = captureStartSample conversion
- Replace unbounded vector with ring buffer for capture events
- Files: ProjectEngine_live.cpp, ProjectEngine.hpp
- Risk: Low, impact: Medium

### Stage 3: Bridge Protocol + EventChannel
- Add protocol version to bridge responses
- Add EventChannel(s) for meters, transport, waveform
- Files: MainActivity.kt, BridgeHost.cpp, engine_bridge.dart
- Risk: Medium, impact: High

### Stage 4: Extract DawShell State
- Separate UI state, engine state, transport state
- Use ChangeNotifier / ValueNotifier per domain
- Files: daw_shell.dart (split), new controllers
- Risk: Large, impact: High

### Stage 5: Type Bridge Parameter API
- Serialize ParameterMetadata (labels, ranges, defaults, units) per device type
- Files: DeviceType serializers, bridge messages, Dart device_families
- Risk: Low, impact: Medium

### Stage 6: Replace Central Switches
- Move param metadata/automation into IDeviceType interface
- Files: AutomationPlayback.cpp, DeviceChainAutomationModulation.cpp
- Risk: Large, impact: Medium

### Stage 7: Variant-to-Registry Dispatch
- Replace std::get dispatches with registry-based dispatch
- Risk: Low, impact: Low

### Stage 8: Incremental Snapshot Delivery
- setParameter returns {ok:true}, not full snapshot
- Risk: Low, impact: High

## Detailed Findings

### All Findings

| # | Title | Severity | Area | File | Line(s) | Current Behavior | Why Matters | Recommended Fix |
|---|-------|----------|------|------|---------|-----------------|-------------|-----------------|
| 1 | shared_lock in audio callback | CRITICAL | Real-time | ProjectEngine.cpp | 594 | Audio thread acquires shared_lock on every process call | Dropout risk when control thread holds exclusive lock | Double-buffered render graph with atomic swap |
| 2 | DawShell god widget | CRITICAL | Flutter | daw_shell.dart | 1-1720 | 30+ fields mixing UI/engine/transport state | Blocks all feature work, violates SRP | Extract into AppController, per-screen ViewModels |
| 3 | Param change returns full snapshot | HIGH | Bridge | BridgeHost.cpp | 79-87 | Every setDeviceParameter serializes complete project | 90% wasted bridge traffic, UI lag | Return {ok:true}, let Flutter request snapshot separately |
| 4 | MIDI recording clip misalignment | HIGH | Recording | ProjectEngine_live.cpp | 182 | clipStart = playheadBeats() at commit time | Recorded clips misaligned by capture delay | Use captureStartSample_ → beat conversion |
| 5 | No EventChannel support | HIGH | Bridge | MainActivity.kt | 246-332 | MethodChannel only, no streaming | Meters/transport UI poll-based, wasteful | Add EventChannels per stream type |
| 6 | Device snapshot 22-case switch | HIGH | Bridge | device_snapshot.dart | 45-72 | fromMap switch on type string | Unknown type crashes Flutter, fragile | Registry pattern or codegen |
| 7 | AutomationPlayback megafile | HIGH | Engine | AutomationPlayback.cpp | 54-1136 | 4 switch ladders, 1100 lines total | Each new device edits 4 switch cases | Move param logic into IDeviceType |
| 8 | String-typed params across bridge | HIGH | Flutter | engine_bridge.dart | 115 | setDeviceParameter(String, double) | No compile-time safety, typos cause silent bugs | Typed param IDs + metadata on bridge |
| 9 | Duplicate serialization C++/Dart | HIGH | Cross-layer | ProjectJson.hpp + device_snapshot.dart | multiple | Both layers manually serialize same shape | Must keep in sync, easy to drift | Codegen bridge types from canonical schema |
| 10 | captureEvents unbounded vector | MEDIUM | Recording | ProjectEngine.hpp | 260 | std::vector<CaptureEvent> grows indefinitely | Memory exhaustion risk in long sessions | Fixed ring buffer |
| 11 | No bridge protocol version | MEDIUM | Bridge | ProjectJson.hpp | 27 | Only project file has version, bridge has none | Bridge shape change silently misparsed | Add version field to all bridge responses |
| 12 | Defaults duplicated 2-3x | MEDIUM | Serialization | multiple | multiple | Every field default in C++, Dart fromMap, and Flutter widgets | Changing a default updates 3 places | Single source of truth in C++ metadata |
| 13 | Device metadata absent from bridge | MEDIUM | Serialization | AutomationPlayback.cpp | 675-813 | ParamDescriptor only in C++, never serialized | Flutter hardcodes labels/ranges per device | Serialize ParamDescriptor per device type |
| 14 | ModulationGraph is global | MEDIUM | Engine | ProjectEngine.hpp | 306 | Single global ModulationGraph on ProjectEngine | Limits per-track modulation isolation | Move toward per-track or per-device mod graphs |
| 15 | updateLfoParam unsynchronized | MEDIUM | Real-time | ModulationGraph.cpp | 108-118 | Direct field writes to live modulator without atomic | Race: audio reads partial multi-field update | Atomic swap or double-buffer modulator params |
| 16 | thread_local vector may realloc | MEDIUM | Real-time | ProjectEngine.cpp | 624 | conditional reserve() on first audio callback | One-time allocation is acceptable but suboptimal | Pre-allocate max capacity or use fixed array |
| 17 | loopEnabled default mismatch | MEDIUM | Serialization | project_snapshot.dart | 77 | Defaults to true, but persist format omits field | First load shows loop on even if backend state differs | Include loopEnabled in project file format |
| 18 | DevicePickerSheet hardcoded tiles | MEDIUM | Flutter | device_picker_sheet.dart | 23-184 | 20 hardcoded ListTile entries per device | New device needs Flutter code change | Derive from device metadata |
| 19 | No generic param editor | MEDIUM | Flutter | device_strip_slot.dart | 720+ | Per-device custom editors with hardcoded fields | Slow to add devices, duplicates code | Build generic editor from ParamDescriptor metadata |
| 20 | LFO params in bridge snapshot | MEDIUM | Cross-layer | project_snapshot.dart | 349-673 | 30 LfoSnapshot fields with defaults duplicated | C++ and Dart must stay in sync | Versioned schema or codegen |
| 21 | AUDIO RECORDING NOT IMPLEMENTED | LOW (gap) | Recording | n/a | n/a | No audio input capture, no ring buffer, no disk writer | Cannot record audio yet | Future feature |
| 22 | ZIP archive no CRC check | LOW | Serialization | ProjectArchive.cpp | 103-139 | ZIP stored without verification on load | Corrupted files silently load as empty project | Add CRC-32 verification |
| 23 | CaptureEvent push_back on control thread | LOW | Recording | ProjectEngine_live.cpp | 76-85 | vector push_back for each note event | Unbounded, but control-thread only | Ring buffer |

## File Change Counts

### To add a new device type: ~18-22 files

**Engine C++ (12-14):**
- DeviceTypeIds.hpp (add constexpr string)
- AutomationTypes.hpp (add ParamKind + param enum)
- DeviceChain.hpp (add DeviceNodeKind + params struct)
- New device type header + cpp
- New processor header + cpp
- DeviceRegistry.cpp (include + registerType)
- AutomationPlayback.cpp (3-4 switch cases)
- DeviceChainAutomationModulation.cpp (modulation case)
- CMakeLists.txt
- Tests (registry + roundtrip)

**Flutter/Dart (5-6):**
- device_snapshot.dart (part directive + fromMap case)
- New device_families/*_family.dart file
- device_strip_device_kind.dart (category)
- device_picker_sheet.dart (new ListTile)
- device_strip_slot.dart (new switch case)

### To add one param to existing device: ~7-8 files

**Engine C++ (5-6):**
- AutomationTypes.hpp (add enum value)
- Instance model header (new field)
- DeviceType .cpp (serialize + setParameter)
- Processor .cpp (process the param)
- AutomationPlayback.cpp (name, descriptor, apply)
- DeviceChainAutomationModulation.cpp

**Flutter/Dart (2):**
- device_families/*_family.dart (field + map + copyWith)
- Optional editor screen update