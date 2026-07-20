# UX Flow Contract: Ducker

## Layout

Dynamics-style card with **Sidechain input** row above knobs.

- `designWidth` ~220
- Input chrome: Dynamics trim (left)
- Output chrome: Stereo gain+pan (right)
- GR meter on dynamics output rail

```
[ Trim ] [ Sidechain combo ] [ knobs ] [ Gain/Pan + GR ]
```

## Sidechain combo (`AudioSourcePicker`)

Rows: track icon + name; device rows add “· DeviceLabel”.

| Entry | id |
|-------|-----|
| Off | `""` |
| Track output | `track-audio:{trackId}` |
| Device | `{deviceId}` |

Disabled + reason: cycle / same-track after ducker. No hardware input in v1.

## Knobs (0–1 norm)

| Control | Param ID | Default |
|---------|----------|---------|
| Threshold | `duckThreshold` | 0.45 |
| Depth | `duckDepth` | 0.75 |
| Attack | `duckAttack` | 0.15 |
| Release | `duckRelease` | 0.45 |

String param: `sidechainSourceId`.
