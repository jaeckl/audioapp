# Performance Budgets

Initial budgets for MVP. Update when measured on target devices.

## Audio callback

| Metric | Budget |
|--------|--------|
| Allocations per callback | 0 |
| Lock acquisitions | 0 |
| Max callback duration | < 50% of buffer period at 48 kHz / 256 samples |
| NaN/Inf in output | 0 |

## Graph rebuild

| Metric | Budget |
|--------|--------|
| Rebuild during playback | Deferred to stop or block boundary swap |
| Snapshot swap on audio thread | Pointer flip only; no allocation |

## Flutter UI

| Metric | Budget |
|--------|--------|
| Engine event handling | Coalesce to ≤ 30 Hz for playhead |
| Full timeline rebuild on transport tick | Not allowed |
| Target frame rate | 60 fps on mid-range Android tablet |

## Memory

| Metric | Budget |
|--------|--------|
| Sample load | Lazy; stream large files later |
| Per-voice allocation in sampler | Pool voices; no alloc per note in RT |

## Offline render

| Metric | Budget |
|--------|--------|
| Speed | Faster than realtime for simple projects (Milestone 09 target) |
| Determinism | Same project → same output hash |

## Violations

Document exceptions here with rationale and ticket reference before merging.
