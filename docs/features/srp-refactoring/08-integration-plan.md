# Integration Plan

## 8.1 Recommended Implementation Order

```
Step 0: Create docs directory structure (already done)

Step 1: WP3 — Bridge Utility Extraction
  - Extracts bridge helpers and argument parsers from ProjectJson.cpp
  - Creates BridgeUtil.hpp + BridgeUtil.cpp
  - Updates BridgeHost.cpp and EngineHost_commands.cpp includes
  - ProjectJson.cpp becomes smaller, focused on serialization only
  - Estimated diff: -80 lines from ProjectJson, +100 lines in BridgeUtil

Step 2a: WP1 — Per-Device Serialization Extraction  (parallel with 2b)
  - Creates 14 serializer headers
  - Replaces deviceToVar/deviceFromVar inline bodies with dispatch
  - Estimated diff: -700 lines from ProjectJson, +350 lines in serializers

Step 2b: WP2 — Per-Device Process Extraction  (parallel with 2a)
  - Creates 14 process .cpp files
  - Replaces switch-case inline bodies with function calls
  - Estimated diff: -400 lines from DeviceChain, +450 lines in process files

Step 3: WP4 — LFO Math Declaration Fix
  - Move LFO declarations from ProjectJson.hpp to LfoTypes.hpp
  - Update all includes
  - Can be done any time after Step 1

Step 4: Integration & Verification
  - Build engine: cmake --build build/engine --target audioapp_engine
  - Run all engine tests
  - Run Flutter tests: cd app_flutter && flutter test
  - Optional: render WAV, verify bit-exact output
```

## 8.2 Parallelization Summary

| Package | Parallel-Safe With | Sequential After |
|---------|-------------------|-----------------|
| WP3 | WP4 | Nothing |
| WP1 | WP2, WP4 | WP3 (same file: ProjectJson.cpp) |
| WP2 | WP1, WP4 | Nothing |
| WP4 | WP1, WP2, WP3 | Nothing (but needs WP3 for clean ProjectJson.hpp) |

### Parallel execution plan:

**Batch 1:** WP3 (modifies ProjectJson.cpp/.hpp, BridgeHost.cpp)
**Batch 2:** WP1 (modifies ProjectJson.cpp) + WP2 (modifies DeviceChain.cpp) + WP4 (modifies ProjectJson.hpp, LfoTypes.hpp)
  — All three modify different files, or non-overlapping regions of the same file.

## 8.3 Shared Files Requiring Care

### `engine_juce/src/ProjectJson.cpp`

Modified by WP3 (remove bridge helpers + arg parsers) and WP1 (replace
deviceToVar/deviceFromVar with dispatch). These modify NON-OVERLAPPING regions:

- WP3 removes lines ~998–1064 (bridge helpers) and ~907–996 (arg parsers)
- WP1 replaces lines ~79–428 (deviceToVar/deviceFromVar bodies) and
  ~637–731 (LFO/mod edge serializers) with dispatch

**Merge strategy:** Do WP3 first (serial → single threaded), then WP1 on the
resulting file. After WP3, ProjectJson.cpp is ~880 lines. After WP1, it's
~300 lines.

### `engine_juce/include/audioapp/ProjectJson.hpp`

Modified by WP4 (remove LFO math declarations) and WP3 (remove bridge helper
declarations). These are non-overlapping sections in the header. Merge cleanly.

### `native_bridge/src/BridgeHost.cpp` and `engine_juce/src/EngineHost_commands.cpp`

Only touched by WP3 (include change). No conflict.

## 8.4 Contract Gaps and Risks

### Risk 1: LFO math header dependency trail

`ProjectJson.hpp` is included by many files purely for LFO math declarations.
Running `rg "#include .*ProjectJson.hpp"` across the repo and checking each
consumer is mechanical but tedious.

**Mitigation:** After WP4, compile the project. Any file that only needs LFO
math but still includes `ProjectJson.hpp` will compile (it's still valid), but
adds unnecessary dependencies. The actual bug is only if a file that currently
gets LFO declarations via `ProjectJson.hpp` loses them — but since WP4 adds
them to `LfoTypes.hpp`, any file that also includes `LfoTypes.hpp` directly
or transitively will be fine. The most common path is:
`BridgeHost.cpp` → includes `ProjectJson.hpp` → declares LFO math → available.
After WP4: `BridgeHost.cpp` includes `ProjectJson.hpp` (now without LFO math)
but also includes `LfoTypes.hpp` transitively via other headers.

**Actually, many files include `ProjectJson.hpp` for serialization, NOT for LFO
math. Those files are fine. Files that need LFO math:**
- `LfoEngine.cpp` — already includes `ProjectJson.hpp` (wrong) but should
  include `LfoTypes.hpp` (correct)
- Any other file calling `lfoEvaluate()` or `modulatorEvaluate*()` directly

**Mitigation:** The WP4 worker MUST check which files call the LFO functions
directly and update their includes.

### Risk 2: Legacy compatibility in serializers

`deviceFromVar()` has legacy fallback code (e.g., `hasProperty("cymbalMetal")`
→ combine with `hasProperty("cymbalBrightness")` to compute `cymbalColor`).
These must be preserved exactly in per-device serializers.

**Mitigation:** Document each legacy fallback with a comment in the serializer
file: `// Legacy: pre-v2 files used "cymbalMetal" and "cymbalBrightness"`

### Risk 3: `processDeviceChain()` signature (22 parameters) is unchanged

The refactoring does NOT reduce parameter count. The per-device process
functions may also have many parameters. This is acceptable for Phase 1 —
the goal is SRP, not parameter reduction.

### Risk 4: `DeviceChainScratch` is an anonymous-namespace thread_local in DeviceChain.cpp

The extracted process functions need scratch buffers. Three approaches:
A. Keep scratch in `processDeviceChain`, pass relevant sub-buffers as params
   (cleanest — each device type uses different scratch regions)
B. Make `DeviceChainScratch` a public struct and pass a reference
C. Leave it as-is and make extracted functions methods on a struct

**Recommendation:** Approach A. Each device type only uses certain scratch
regions (e.g., oscillator uses `s.scratch`, sampler uses `s.samplerRegions`,
cymbals use `s.tempStereoL/R`). Pass the relevant regions as parameters.

### Risk 5: `applyModulation` overloads stay in DeviceChain.cpp

The 14 `applyModulation(Params&, float, uint16_t)` overloads are called via
`std::visit` in `applyDspModulationAtFrame` and `applyDspAutomationAtBeat`.
These stay in DeviceChain.cpp in Phase 1. They are already cleanly factored
as overloads and don't violate SRP in the same way as the switch-case bodies.

## 8.5 Final State After All WPs

```
                      BEFORE                          AFTER
                      ------                          -----
ProjectJson.cpp       ~1067 lines (all concerns)      ~300 lines (serialization only)
ProjectJson.hpp       ~72 lines (all declarations)     ~30 lines (serialization only)
DeviceChain.cpp       ~854 lines (all devices)        ~400 lines (dispatch only)
DeviceState.hpp       ~134 lines (monolithic)         ~134 lines (unchanged)

NEW serializer .hpp   0                                14 files × ~25 lines = ~350 lines
NEW process .cpp      0                                14 files × ~32 lines = ~450 lines
NEW BridgeUtil.*      0                                2 files × ~100 lines = ~100 lines

Total source lines    ~2127 (in 3 monolithic files)   ~2134 (in 33 files)
                                                    (~0.3% increase, but
                                                     each file has clear SRP)
```
