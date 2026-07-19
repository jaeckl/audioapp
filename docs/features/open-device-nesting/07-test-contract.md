# Test Contract: Open Device Nesting

## Principles

- Prefer real project JSON / real `ProjectEngine` mutations over mocks for nest topology.
- Audio tests use `renderOffline` where behavior is audible/measurable.
- Flutter tests flip former “containers rejected” expectations.
- Silent empty add = test failure.

## WP-owned unit / component tests

| WP | Required tests |
|----|----------------|
| WP-01 | `device_nesting_validator_test`: each `NestingErrorCode`; ring-lease estimate; subgraph step estimate; known type always allowed |
| WP-02 | Depth-3 `findDeviceLocked`; `setDeviceParameter` on leaf; modulation target resolve; automation unlink on nested remove |
| WP-03 | Nested meter atomic write; Flutter `MeterSubscription` includes nested id when expanded + in viewport |
| WP-04 | Nested `processChain` does not corrupt outer per-frame gain (buffer compare) |
| WP-05 | Widget: expand nested `VirtualStripHostSnapshot` shows sub-strip |
| WP-06 | Engine add container-into-container success; JSON round-trip; Flutter no reject-list early return |
| WP-07 | Smoke matrix below; CI green |

## Deep-nest smoke matrix (WP-07)

| ID | Topology | Assert |
|----|----------|--------|
| S1 | track → chain → chain → compressor | Param + GR meter + audible gain reduction |
| S2 | track → spectral → PRE → device_chain → delay | Audio wet; expand UI |
| S3 | track → mb_split → band → lr_split → branch → FX | Both branches process |
| S4 | track → drum pad → chain → FX | Pad hit through nested FX |
| S5 | track → synth → audioFx → chain → FX | Note + FX path |
| S6 | Cap: 9th device on chain | `branch_device_cap` PlatformException |
| S7 | Ring: exceed leases via nested delays | `ring_lease_exhausted` on add |
| S8 | Schedule bomb: deep container fan-out | `subgraph_step_overflow` or reject before bypass |

## Flipped tests (explicit)

Locate and invert:

- `app_flutter/test/spectral_loud_split_device_test.dart` comment/expectations about container reject
- Any engine test asserting `addDeviceTo*` returns empty for `device_chain` / splits inside containers
- Playback builder tests that expect nested containers skipped

## Performance / RT

- WP-04 guard: no allocations (optional asan/heap counter in test harness if available)
- Validator only on control thread — no audio-thread tests for NestingError throw

## Manual PO script

1. Fresh project, add audio clip + Device Chain.  
2. Expand → add Device Chain → expand → add Compressor.  
3. Play; move threshold; see GR.  
4. Add Spectral Loud on track; put MB split in PRE; put Chain in a band; put Delay in chain.  
5. Automate nested delay mix.  
6. Attempt 9th device on a full branch → error toast.  
7. Save/reload project → tree intact.
