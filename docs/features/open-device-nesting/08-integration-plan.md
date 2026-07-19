# Integration Plan: Open Device Nesting

## Merge order

```
WP-01 (validator + stubs + NestingError bridge shape)
   ├─► WP-02 (recursive find + auto/mod)     ──┐
   ├─► WP-04 (scratch frames)               ──┼─► WP-03 (meters) ──┐
   └─► WP-05 (virtual strips UI)            ──┘                   │
                                                                   ▼
                                                              WP-06 (drop rejects)
                                                                   ▼
                                                              WP-07 (smokes + deploy)
```

## Shared files requiring care

1. **`ProjectEngine.cpp`** — WP-02 (walk), WP-03 (meterSlot assign), WP-06 (validator on add). Prefer single sequential owner after stubs, or tiny ordered PRs.
2. **Container processors** — WP-03 (ctx) + WP-04 (scratch). Land WP-04 first if conflict.
3. **Flutter `device_chain_row_private_*_virtual_*.dart`** — WP-05 then WP-06 (delete reject consts).

## Integration checkpoints

| Gate | Criteria |
|------|----------|
| G1 after WP-01 | Validator unit tests green; error code strings stable |
| G2 after WP-02+WP-04 | Depth-3 setParam + nested render without stomp |
| G3 after WP-03+WP-05 | Nested meter + expand chrome on stubbed allowed types |
| G4 after WP-06 | Open type insert; JSON round-trip |
| G5 after WP-07 | Smoke matrix + device deploy |

## Contract gaps / risks

| Risk | Mitigation |
|------|------------|
| Ring-lease estimate ≠ actual multi-lease devices (MB/Spectral) | WP-01 audit `ensureBuffers` call counts per type |
| `kMaxDevicesPerTrack` flatten vs deep tree | Validator counts all nodes in walk, not just top-level |
| Playback arrays still `devices[8]` | Cap remains soft; builders must not skip types |
| Bridge still returns empty string on some adds | WP-01 defines PlatformException; WP-06 converts all paths |
| File size blow-up in `device_chain_row_*` | Extract nest layout helper if >300 LOC delta |
| Silent audio bypass on schedule overflow | WP-01/06: reject on rebuild/add; never bypass quietly for new graphs |
| Auto/mod scans outside ProjectEngine | Grep for 1-level container loops in whole engine |

## Non-blocking follow-ups (not DoD)

- Persist UI expansion set
- Raise soft caps after profiling
- Minimap nested thumbnail polish beyond width correctness

## Architect final checklist

- [x] Vertical WPs (not horizontal layers)
- [x] Canonical vocabulary binding
- [x] File ownership non-overlap except marked shared
- [x] Parallel classification explicit
- [x] Blockers B1–B5 mapped to WPs
- [x] Policy gate removals assigned to WP-06
- [ ] `09-ux-flow-contract.md` — layout-contract-designer after this contract
