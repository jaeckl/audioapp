# Canonical Vocabulary: Open Device Nesting

Implementation agents **must** use these names. Do not invent synonyms.

| Concept | Canonical name | Type/file | Notes |
|---------|----------------|-----------|-------|
| Feature | `open-device-nesting` | `docs/features/open-device-nesting/` | Folder name binding |
| Structured failure | `NestingError` | new `include/audioapp/devices/NestingError.hpp` | Control-thread only |
| Error code enum | `NestingErrorCode` | same | See data contract |
| Soft limits aggregate | `NestingCapacityLimits` | same or `DeviceNestingValidator.hpp` | Constants + getters |
| Pre-mutate validator | `DeviceNestingValidator` | `include/audioapp/devices/DeviceNestingValidator.hpp` | Estimate + validate |
| Recursive slot walk | `DeviceTreeWalk` | `include/audioapp/devices/DeviceTreeWalk.hpp` | Shared visitor |
| Find by id | `ProjectEngine::findDeviceLocked` | `ProjectEngine.cpp` | Must become fully recursive via `DeviceTreeWalk` |
| Collect subtree ids | `collectDeviceTreeIds` | `ProjectEngine.cpp` | Must use same walk |
| Subgraph tree | `DeviceSubgraphTree` | `DeviceSubgraph.hpp` | Existing |
| Compile schedule | `compileDeviceSubgraphTree` | `DeviceSubgraph.cpp` | Existing; overflow → validator |
| Schedule overflow flag | `CompiledDeviceSubgraphSchedule::overflow` | existing | Must surface as `subgraph_step_overflow` |
| Max schedule steps | `kMaxCompiledDeviceSubgraphSteps` | `512` existing | Soft capacity |
| Meter atomics | `DeviceMeterAtomic` | `DeviceChain.hpp` | Existing |
| Meter index | `meterSlot` | `DeviceNodePlayback` | Assign for nested publishers |
| Process ctx meters | `ProcessContext::deviceMeters` | `ProcessContext.hpp` | Must forward into nested `processChain` |
| Nested orchestrator entry | `DeviceChainOrchestrator::processChain` | existing | Re-entrant |
| Scratch struct | `DeviceChainScratch` | existing | Track-scoped |
| Scratch frame | `DeviceChainScratchFrame` | new in `DeviceChainScratch.hpp` | Push/pop for re-entrancy |
| Ring arena | `DeviceChainScratchArena` | existing | `kMaxTimeBasedEffects = 6` |
| Ring allocate | `DeviceChainScratchArena::allocate` | existing | Failure → NestingError on rebuild/add |
| Branch soft max | `kMaxDevicesPerNestBranch` | **new name** for the `8` cap | Prefer named constant over magic `8` |
| Pad soft max | `DrumMachineModel::kMaxDevicesPerPad` | existing `4` | Keep |
| Track flatten max | `kMaxDevicesPerTrack` | existing `24` | Soft for nested flatten |
| Forbidden-type helper | `isForbiddenNestedType` | Spectral/MB DeviceType .cpp | **DELETE** |
| Flutter reject sets | `_splitNestingRejectedTypes`, `_mbNestingRejectedTypes`, `_slNestingRejectedTypes` | virtual_* dart parts | **DELETE** |
| Virtual host snapshot | `VirtualStripHostSnapshot` | existing | Any depth |
| Meter subscription helper | `MeterSubscription` | `meter_subscription.dart` | Recursive viewport |
| Layout widths | `DeviceChainLayout` | existing | Recursive expanded widths |
| Top-level visible list | `TrackSnapshot.visibleDevices` | existing | Unchanged meaning (top-level only); nested via host fields |

## Forbidden Synonyms

Do **not** create:

- `NestError` / `DeviceNestError` instead of `NestingError`
- `DeviceWalker` / `SlotVisitor` instead of `DeviceTreeWalk`
- `ScratchScope` instead of `DeviceChainScratchFrame`
- `isIllegalNestedType` instead of deleting forbidden-type gates
- `maxNestedDevices` without aligning to `kMaxDevicesPerNestBranch`

## Naming Conventions

- Error codes: `snake_case` string for bridge (`branch_device_cap`).
- C++ enum: `NestingErrorCode::BranchDeviceCap`.
- New headers under `engine_juce/include/audioapp/devices/`.
- Flutter: no new reject-list names; capacity errors use bridge `NestingError.code`.
