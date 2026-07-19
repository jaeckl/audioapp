# API Contracts: Open Device Nesting

## Owner modules

| API | Owner WP | Module |
|-----|----------|--------|
| `NestingError` / `NestingErrorCode` | WP-01 | `devices/NestingError.hpp` |
| `DeviceNestingValidator` | WP-01 | `devices/DeviceNestingValidator.*` |
| `DeviceTreeWalk` | WP-01 stubs → WP-02 complete | `devices/DeviceTreeWalk.*` |
| `findDeviceLocked` behavior change | WP-02 | `ProjectEngine` |
| Auto/mod target enumeration | WP-02 | `ProjectEngine` (+ modulation helpers) |
| Meter slot assign + ctx forward | WP-03 | playback rebuild + container processors |
| `DeviceChainScratchFrame` | WP-04 | `DeviceChainScratch.*` |
| Virtual strip recursion | WP-05 | Flutter `device_chain_row_private_*` |
| Reject-filter removal | WP-06 | Engine + Flutter + ProjectJson |

---

## `NestingError`

```cpp
enum class NestingErrorCode {
    None = 0,
    BranchDeviceCap,
    PadDeviceCap,
    TrackDeviceCap,
    SubgraphStepOverflow,
    RingLeaseExhausted,
    UnknownParent,
    UnknownType,
};

struct NestingError {
    NestingErrorCode code = NestingErrorCode::None;
    std::string message;       // human-readable
    std::string parentDeviceId;
    std::string deviceType;    // attempted insert type, if any
    int limit = 0;
    int attempted = 0;
};
```

**Threading:** control only.  
**Nullability:** `code == None` means success.  
**Bridge mapping (binding):**

```text
PlatformException(
  code: <snake_case of NestingErrorCode>,  // e.g. "branch_device_cap"
  message: NestingError.message,
  details: {
    parentDeviceId, deviceType, limit, attempted
  }
)
```

Agents must not invent alternate bridge shapes after WP-01 lands the first MethodChannel path.

---

## `DeviceNestingValidator`

```cpp
class DeviceNestingValidator {
public:
  // Estimates post-insert topology against soft limits.
  // Does not mutate. Safe under ProjectEngine write lock.
  static NestingError validateInsert(
      const DeviceSlot& parent,
      std::string_view childTypeId,
      const NestingCapacityLimits& limits,
      /* track-level lease + flatten context */);

  static NestingError validateTree(
      const DeviceSlot& root,
      const NestingCapacityLimits& limits);
};
```

**Validation rules:**

1. Parent exists (caller ensures via find).
2. `childTypeId` known — else `UnknownType`.
3. Parent branch/list size + 1 ≤ `kMaxDevicesPerNestBranch` (or pad max) — else cap error.
4. Estimated flattened device count ≤ `kMaxDevicesPerTrack`.
5. Estimated compiled subgraph steps ≤ `kMaxCompiledDeviceSubgraphSteps`.
6. Estimated simultaneous ring leases ≤ `kMaxTimeBasedEffects`.

**Error behavior:** return `NestingError`; never throw on audio thread.

---

## `DeviceTreeWalk`

```cpp
// Invokes visitor(slot) for every DeviceSlot in subtree including root.
// Order: pre-order. Containers: chain children, split branches, MB bands,
// spectral pre/bands/post, drum pads, noteFx, audioFx — recursively.
template <typename Fn>
void walkDeviceTree(DeviceSlot& root, Fn&& visitor);

template <typename Fn>
void walkDeviceTree(const DeviceSlot& root, Fn&& visitor);
```

**Used by:** `findDeviceLocked`, `collectDeviceTreeIds`, auto/mod target scan, meter publishers enumeration, JSON diagnostics.

---

## `ProjectEngine::findDeviceLocked` (behavior contract)

**Before:** one generation into each container kind.  
**After (WP-02):** search all tracks’ top-level devices; for each, `walkDeviceTree` until id match.

```cpp
DeviceSlot* ProjectEngine::findDeviceLocked(const std::string& deviceId);
```

**Nullability:** `nullptr` if missing → callers map to `UnknownParent` / false.  
**Threading:** caller holds engine mutex.

---

## `addDeviceTo*` mutation contract (all nest entry points)

Applies to:

- `addDeviceToChain`
- `addDeviceToSplitBranch`
- `addDeviceToMultibandBand`
- `addDeviceToSpectralLoudPreFx` / `Band` / `PostFx`
- `addDeviceToDrumPad`
- `addDeviceToSynthAudioFx` / `addDeviceToSynthNoteFx`
- (any future sub-strip add)

**Algorithm:**

1. Lock + `findDeviceLocked(parentId)` — fail → NestingError `unknown_parent`.
2. **Remove type-based rejects** (WP-06): do not reject containers.
3. `DeviceNestingValidator::validateInsert` — fail → NestingError (no mutate).
4. Insert child; `rebuildTrackPlaybackLocked`.
5. Return new device id (success).

**Forbidden:** `return {}` without bridge error after WP-01 wiring for that method.

Flutter counterparts must await and surface `PlatformException`.

---

## Meter APIs

### Engine playback rebuild (WP-03)

When building nested `DeviceNodePlayback` trees:

- Assign monotonically increasing `meterSlot` for every node that publishes meters (dynamics, analysis, splits), including nested.
- Nested `DeviceChainOrchestrator::Context` / `ProcessContext` **must copy** `deviceMeters`, `maxDeviceMeters`, `meterSlotSubscribed` from parent ctx.

### Flutter `MeterSubscription.visibleMeterDeviceIds`

**After:** walk top-level devices; for each expanded virtual host, add nested strip widths to x-cursor and include nested publishing device ids in viewport.

Signature stays; behavior becomes recursive. Expansion set input may be added:

```dart
static List<String> visibleMeterDeviceIds({
  required TrackSnapshot track,
  required DeviceStripSlotDensity density,
  required ScrollController scrollController,
  required double viewportWidth,
  double listPadding = 8,
  Set<String> expandedDeviceIds = const {}, // NEW optional, default empty
});
```

If expansion lives only inside row State, WP-05 may pass expanded ids from row into subscription update — do not invent a second source of truth.

---

## Scratch re-entrancy (WP-04)

```cpp
struct DeviceChainScratchFrame {
  // Saves/restores regions nested processChain overwrites:
  // perFrameGain, perFramePan, tempStereoL, tempStereoR
  // (exact fields per DeviceChainScratch usage audit in WP-04)
};

class DeviceChainScratchGuard { // optional RAII name binding
public:
  explicit DeviceChainScratchGuard(DeviceChainScratch& scratch) noexcept;
  ~DeviceChainScratchGuard() noexcept;
};
```

**Usage:** every nested `processChain` call site (Split, MB, Spectral, Chain, DrumMachine, synth FX) must enter with guard/frame.

**Threading:** audio only; `noexcept`; no heap.

---

## Policy APIs to delete (WP-06)

| API / symbol | Action |
|--------------|--------|
| `isForbiddenNestedType` | Delete; builders append all children subject to count cap only |
| `ProjectEngine` type rejects on add | Delete type checks; keep known-type + validator |
| ProjectJson nested container drops | Delete skip-on-type filters |
| Flutter `_*NestingRejectedTypes` | Delete; picker may return any type |

---

## Example usage

```cpp
if (auto err = DeviceNestingValidator::validateInsert(*parent, deviceType, limits);
    err.code != NestingErrorCode::None) {
  // bridge: throw PlatformException from JNI/FFI layer
  return err;
}
```

```dart
try {
  await bridge.addDeviceToChain(chainId: id, deviceType: type);
} on PlatformException catch (e) {
  showNestingErrorSnackBar(e); // e.code == 'branch_device_cap' etc.
}
```
