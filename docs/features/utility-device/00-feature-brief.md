# Utility Device — Feature Brief

## User-Visible Goal

One **Utility** FX device with modes: mono sum, polarity invert, channel swap, trim, autopan. Cheap DSP; single strip card.

## Type ID

| typeId | Name | Accent |
|--------|------|--------|
| `utility` | Utility | `#94A3B8` |

## Params (0–1 unless noted)

| Param | Role |
|-------|------|
| `utilMono` | ≥0.5 = mono sum |
| `utilPolarity` | 0=off, ~0.33=L, ~0.66=R, 1=both |
| `utilSwap` | ≥0.5 = L↔R |
| `utilTrim` | gain 0..1 (1 = unity) |
| `utilAutopan` | ≥0.5 on |
| `utilAutopanRate` | LFO rate |
| `utilAutopanDepth` | pan depth |

## Non-Goals

- Sidechain
- Separate devices per function
- Tempo-sync autopan v1 (free-running Hz OK)

## Acceptance

Mono/polarity/swap/trim/autopan audible; JSON round-trip; unit test; deploy.
