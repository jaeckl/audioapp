# Drum device family presets

**Status:** Voice presets + 15 `drum_machine` kits via `presetRef`

Fifteen stylistic families. Each voice is a `DevicePresetStore` leaf +
`manifest.json` entry. Kits are `drum_machine` presets whose pads
reference voice presets (`presetRef`) and resolve in Flutter
(`FactoryPresetJson`) before `applyDevicePreset`.

## Constraints

- CHH / OHH = two presets on `hihat_generator` (decay / tightness).
- Tom Lo / Mid / Hi = three presets on `tom_generator` (`tomPitch`).
- No cowbell / shaker / conga synth devices — omitted.
- Rock / reggae / ambient are synthesized approximations.
- Kit pads: notes 36–51 (Kick/Snare/CHH/OHH/…); hats share chokeGroup 1.

## Families

| Family | Slug | Voices | Genre tags |
|--------|------|--------|------------|
| 808 | `808` | Kick, Snare, Clap, Closed Hat, Open Hat, Rim, Tom Lo, Tom Mid, Tom Hi, Crash | edm, electro |
| 909 | `909` | Kick, Snare, Clap, Closed Hat, Open Hat, Rim, Tom Lo, Tom Mid, Tom Hi, Ride, Crash | house, techno |
| Electro | `electro` | Kick, Snare, Clap, Closed Hat, Open Hat, Rim, Tom Mid, Crash | electro |
| Trap | `trap` | Kick, Snare, Clap, Closed Hat, Open Hat, Rim, Tom Lo | trap |
| Boom Bap | `boombap` | Kick, Snare, Rim, Closed Hat, Open Hat, Tom Lo, Tom Mid | hiphop, lofi |
| House | `house` | Kick, Snare, Clap, Closed Hat, Open Hat, Ride, Crash | house |
| Techno | `techno` | Kick, Snare, Closed Hat, Open Hat, Rim, Ride, Crash | techno, dark |
| Pop | `pop` | Kick, Snare, Clap, Closed Hat, Open Hat, Rim, Tom Mid, Crash | pop, clean |
| R&B | `rnb` | Kick, Snare, Rim, Closed Hat, Open Hat, Clap, Tom Lo | rnb |
| Reggae | `reggae` | Kick, Snare, Rim, Closed Hat, Open Hat | reggae |
| Rock | `rock` | Kick, Snare, Rim, Closed Hat, Open Hat, Tom Lo, Tom Mid, Tom Hi, Ride, Crash | rock |
| Breakbeat | `breakbeat` | Kick, Snare, Rim, Closed Hat, Open Hat, Tom Lo, Tom Hi, Crash | breakbeat |
| Disco | `disco` | Kick, Snare, Clap, Closed Hat, Open Hat, Ride | disco, funk |
| DnB | `dnb` | Kick, Snare, Closed Hat, Open Hat, Rim, Crash | dnb |
| Ambient | `ambient` | Kick, Snare, Closed Hat, Open Hat, Rim | ambient |

**Voice presets:** 112
**Kit presets:** 15 (`preset:kit-{family}`)

## IDs

- Voice: `preset:{family}-{voice}` e.g. `preset:808-kick`
- Kit: `preset:kit-{family}` e.g. `preset:kit-808`

## Regenerating

```powershell
python tools/generate_drum_family_presets.py
```

Updates Dart maps under `device_preset_store_drums_*.dart` and appends
drum family + kit rows in `manifest.json` (keeps non-drum presets).
Kit pad JSON lives in `factory_preset_kits.dart`.
