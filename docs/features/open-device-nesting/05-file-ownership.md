# File Ownership: Open Device Nesting

Implementation agents may only edit files assigned to their WP. Shared files marked carefully.

| File/path | Owner WP | Allowed changes | Forbidden changes |
|-----------|----------|-----------------|-------------------|
| `engine_juce/include/audioapp/devices/NestingError.hpp` | WP-01 | Create + error types | Business mutate logic |
| `engine_juce/include/audioapp/devices/DeviceNestingValidator.hpp` | WP-01 | Create + API | Audio-thread code |
| `engine_juce/src/devices/DeviceNestingValidator.cpp` | WP-01 | Validator impl | ProjectEngine add UX |
| `engine_juce/include/audioapp/devices/DeviceTreeWalk.hpp` | WP-01 stub / WP-02 | Walk API + impl | Flutter |
| `engine_juce/src/devices/DeviceTreeWalk.cpp` | WP-01 stub / WP-02 | Walk impl | DSP processors |
| `engine_juce/include/audioapp/DeviceSubgraph.hpp` | WP-01 | Overflow helpers / estimates only if needed | Redesign roles |
| `engine_juce/src/DeviceSubgraph.cpp` | WP-01 | Estimate step count / overflow reporting hooks | Change fused executor semantics casually |
| `engine_juce/include/audioapp/devices/instances/ChainModel.hpp` | WP-01 | Optional: expose `kMaxDevicesPerNestBranch` if moved here | Unrelated fields |
| `engine_juce/src/ProjectEngine.cpp` | WP-02 (find/auto/mod), WP-06 (drop rejects + call validator), WP-03 (meter assign in rebuild) | See WP notes | Unrelated transport |
| `engine_juce/include/audioapp/ProjectEngine.hpp` | WP-01/02/06 | Error-returning overloads if needed | Public API rename without contract update |
| `engine_juce/src/ProjectJson.cpp` | WP-06 | Remove drop filters; recursive load keep | New file format |
| `engine_juce/src/devices/*Split*DeviceType.cpp` | WP-06 | Delete `isForbiddenNestedType` | DSP |
| `engine_juce/src/devices/SpectralLoudSplitDeviceType.cpp` | WP-06 | Delete forbidden nested | DSP |
| `engine_juce/src/devices/MultibandSplitDeviceType.cpp` | WP-06 | Delete forbidden nested | DSP |
| `engine_juce/src/devices/ChainDeviceType.cpp` | WP-03/06 | Recursive playback children; no type skip | Unrelated params |
| `engine_juce/src/DeviceChainOrchestrator.cpp` | WP-03, WP-04 | Forward meter ctx; scratch guard at nest entry if owned here | Algorithm redesign |
| `engine_juce/include/audioapp/DeviceChainScratch.hpp` | WP-04 | `DeviceChainScratchFrame` / guard | Change `kScratchFrames` casually |
| `engine_juce/src/devices/processors/ChainProcessor.cpp` | WP-03, WP-04 | Ctx forward + scratch guard | UI |
| `engine_juce/src/devices/processors/SplitProcessor.cpp` | WP-03, WP-04 | Ctx forward + scratch guard | UI |
| `engine_juce/src/devices/processors/MultibandSplitProcessor.cpp` | WP-03, WP-04 | Ctx forward + scratch guard | Raise ring size without WP-01 |
| `engine_juce/src/devices/processors/SpectralLoudSplitProcessor.cpp` | WP-03, WP-04 | Ctx forward + scratch guard | Same |
| `engine_juce/src/devices/processors/DrumMachineProcessor.cpp` | WP-03, WP-04 | Ctx forward + scratch guard | Pad UX |
| `engine_juce/include/audioapp/dsp/ProcessContext.hpp` | WP-03 | Doc / ensure fields available to nest | Remove meter fields |
| `engine_juce/include/audioapp/DeviceChain.hpp` | WP-03 | `meterSlot` assign docs / helpers | Unrelated device kinds |
| Native bridge MethodChannel glue (Android/engine host) | WP-01/06 | Map NestingError → PlatformException | New unrelated methods |
| `app_flutter/lib/features/device_strip/meter_subscription.dart` | WP-03 | Recursive viewport + expanded ids | Device picker |
| `app_flutter/lib/features/device_strip/device_chain_layout.dart` | WP-05 | Recursive widths for expanded hosts | Engine |
| `app_flutter/lib/features/device_strip/device_chain_minimap_*.dart` | WP-05 | Nested preview if in scope | Engine |
| `app_flutter/lib/features/device_strip/device_chain_row_private_*.dart` | WP-05 / WP-06 | Recursive virtual strips; delete reject sets | Unrelated chrome |
| `app_flutter/lib/bridge/project_snapshot.dart` | WP-05 | Nested snapshot helpers if needed | Transport fields |
| `app_flutter/lib/bridge/engine_bridge_add_device_to_*.dart` | WP-06 | Surface NestingError (no swallow) | New device types |
| `engine_juce/tests/*` nesting / processor_graph / routing | WP-07 (+ unit in owning WP) | Deep nest + flip rejects | Unrelated suites |
| `app_flutter/test/*nest*` / spectral / device_strip | WP-07 | Flip reject expectations | Unrelated goldens |

## Shared integration files (care)

| File | Why shared | Coordination |
|------|------------|--------------|
| `ProjectEngine.cpp` | WP-02, WP-03, WP-06 | Sequential edits preferred; WP-01 adds validator call stubs first |
| `DeviceChainOrchestrator.cpp` | WP-03 + WP-04 | WP-04 first or same agent; meter forward is small |
| Virtual strip dart parts | WP-05 + WP-06 | WP-05 wires recursion; WP-06 deletes reject consts in same files — **sequential** WP-05 then WP-06 |

## Stub package (if parallel start)

WP-01 may land empty/skeleton:

- `NestingError.hpp`
- `DeviceNestingValidator` with `validateInsert` returning `None`
- `DeviceTreeWalk` declaring `walkDeviceTree`

Before WP-02/03/04/05 parallelize.
