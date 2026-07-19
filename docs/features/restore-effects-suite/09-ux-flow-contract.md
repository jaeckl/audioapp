# UX Flow Contract: Restore Effects Suite

## Layout rules (all devices)

Minimal strip cards — no preview graphs, no header button groups.

- Single page — no container tabs, no header actions
- `designWidth` **96** (one vertical knob column)
- `inputPanelWidth: 0`
- Output chrome per device (not Mix/Width — restore is insert/destructive):
  - **DC Offset / De-Crackler** → empty chrome cap (`EmptyChromeOutputPanel`, width 30)
  - **De-Esser / De-Hum / De-Noise** → Gain + Pan bottom-aligned (`StereoGainPanPanel`, width 64)
- Body: optional **popup combobox** (mode) + **vertical** knobs
- Strip knobs 56dp
- No Listen / ear control (card already has bypass; detection-listen stays engine default off)

```
[ Combobox? ]              [ Gain? ]
[ Knob ]                   [ Pan?  ]   ← only de-ess / de-hum / de-noise
[ Knob ]
```

## Per-device layouts

### DC Offset — designWidth 88

Body combobox: **Mean | HPF**

| Control | Kind | Param ID |
|---------|------|----------|
| Amount | knob | `dcAmount` |
| Cutoff | knob (greyed in Mean) | `dcCutoff` |

### De-Crackler — designWidth 80

| Control | Kind | Param ID |
|---------|------|----------|
| Sense | knob | `crackSense` |
| Strength | knob | `crackStrength` |
| Width | knob | `crackWidth` |

### De-Esser — designWidth 80

| Control | Kind | Param ID |
|---------|------|----------|
| Freq | knob | `deFreq` |
| Thresh | knob | `deThresh` |
| Amount | knob | `deAmount` |

### De-Hum — designWidth 88

Body combobox: **50 Hz | 60 Hz**

| Control | Kind | Param ID |
|---------|------|----------|
| Depth | knob | `humDepth` |
| Harmonics | knob | `humHarmonics` |

### De-Noise — designWidth 80

| Control | Kind | Param ID |
|---------|------|----------|
| Thresh | knob | `dnThresh` |
| Reduce | knob | `dnReduce` |
| Smooth | knob | `dnSmooth` |

## Demo script

1. Picker → **Restore Effects**
2. DC Offset → combobox Mean/HPF → Amount
3. De-Esser → Freq / Thresh / Amount
4. De-Crackler → Sense / Strength / Width
5. De-Hum → 50/60 combobox → Depth / Harmonics
6. De-Noise → Thresh / Reduce / Smooth
7. Bypass via card header; Gain/Pan on De-Esser / De-Hum / De-Noise only
8. Save/reload — params persist
