# Data Contracts (JSON Schema)

All effect parameters are persisted in the project JSON under a device entry:

```json
{
  "type": "delay", // one of "delay", "reverb", "chorus", "phaser"
  "enabled": true,
  "params": { /* effect‑specific fields */ }
}
```

## Common fields (present in every effect snapshot)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `type` | string (enum) | Effect type identifier. | Must be one of `delay`, `reverb`, `chorus`, `phaser` |
| `enabled` | boolean | Whether the effect processes audio. | – |
| `bypass` | boolean (optional) | Alias for `enabled` = false for compatibility. | – |

## DelayParams schema

```json
{
  "timeMs": 250.0,          // delay time in milliseconds (0 – 2000)
  "feedback": 0.4,          // feedback amount (0.0 – 0.95)
  "mix": 0.5,               // dry/wet mix (0.0 – 1.0)
  "filterCutoffHz": 8000,   // optional low‑pass cutoff (20 – 20000)
  "sync": false             // sync to host tempo (optional)
}
```

## ReverbParams schema

```json
{
  "roomSize": 0.5,          // 0.0 – 1.0
  "damping": 0.5,          // 0.0 – 1.0
  "wetLevel": 0.33,        // 0.0 – 1.0
  "dryLevel": 0.7,         // 0.0 – 1.0
  "width": 1.0,            // 0.0 – 1.0 (stereo width)
  "freezeMode": false      // boolean flag
}
```

## ChorusParams schema

```json
{
  "depth": 0.25,            // 0.0 – 1.0
  "rateHz": 1.5,            // 0.1 – 5.0 Hz
  "mix": 0.4,               // 0.0 – 1.0
  "centreDelayMs": 7.0,     // 0 – 20 ms
  "feedback": 0.0           // 0.0 – 0.95 (optional)
}
```

## PhaserParams schema

```json
{
  "depth": 0.5,             // 0.0 – 1.0
  "rateHz": 0.8,            // 0.1 – 5.0 Hz
  "feedback": 0.3,          // 0.0 – 0.95
  "centreFrequencyHz": 1000 // 20 – 20000
}
```

All numeric fields are stored as floating‑point numbers. Validation is performed on the control thread; out‑of‑range values are clamped to the nearest bound and a warning is logged.
