# Milestone 14 — Dynamics FX

**Theme:** Gate, compressor, expander, limiter as in-chain stereo effects.

## Stories

| ID | Title | Status |
|----|-------|--------|
| US-14-01 | Gate effect device | done |
| US-14-02 | Compressor effect device | done |
| US-14-03 | Expander effect device | done |
| US-14-04 | Limiter effect device | done |
| US-14-20 | M14 PO demo — dynamics chain on drum track | todo |

## Demo script (US-14-20)

1. Create track with kick generator + MIDI clip.
2. Insert **Gate** → adjust threshold; verify noise floor drops between hits.
3. Insert **Compressor** → lower threshold, raise ratio; verify punch.
4. Insert **Limiter** on bus before track gain; verify peaks capped.
5. Save project, reload, confirm parameters round-trip.

See [dynamics_fx design doc](../design/dynamics_fx/README.md).
