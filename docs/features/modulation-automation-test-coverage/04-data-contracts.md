# Data Contracts

## Engine test JSON snapshot structure

The `ProjectFileData` parsed from `host.getProjectFileJson()` contains:

```json
{
  "lfos": [
    {
      "id": 1,
      "modulatorType": 0,
      "retrigger": 0,
      "waveform": 0,
      "rate": 1.0,
      "syncDivision": 0,
      "phase": 0.0,
      "polarity": 0,
      "attack": 0.1,
      "decay": 0.25,
      "sustain": 0.7,
      "release": 0.35
    }
  ],
  "modEdges": [
    {
      "lfoId": 1,
      "deviceId": "dev-1",
      "paramId": "filterCutoff",
      "amount": 0.75
    }
  ]
}
```

## Default `LfoState` values

| Field | LFO type (0) | ADSR/ADR type (1/2) |
| ----- | ------------ | ------------------- |
| `modulatorType` | 0 | 1 or 2 |
| `retrigger` | 1 (Sync) | 2 (OnNote) |
| `waveform` | 0 (Sine) | ignored |
| `rate` | 1.0 | 1.0 |
| `syncDivision` | 3 (1/4) | 3 (1/4) |
| `phase` | 0.0 | 0.0 |
| `polarity` | 0 (bipolar) | 0 (bipolar) |
| `attack` | 0.1 | 0.08 |
| `decay` | 0.25 | 0.22 |
| `sustain` | 0.7 | 0.65 |
| `release` | 0.35 | 0.28 |

## Flutter mock snapshot shape

```dart
// Minimal mock for lfos in snapshot
final mockLfos = [
  {
    'id': 1,
    'modulatorType': 0,
    'retrigger': 1,
    'waveform': 0,
    'rate': 1.0,
    'syncDivision': 3,
    'phase': 0.0,
    'polarity': 0,
    'attack': 0.1,
    'decay': 0.25,
    'sustain': 0.7,
    'release': 0.35,
    'name': '',
  },
];

// Minimal mock for modEdges in snapshot
final mockModEdges = [
  {
    'lfoId': 1,
    'deviceId': 'dev-1',
    'paramId': 'filterCutoff',
    'amount': 0.75,
  },
];

// Minimal mock for createLfo response
{
  'ok': true,
  'snapshot': {
    ...baseSnapshot,
    'lfos': mockLfos,
    'modEdges': mockModEdges,
  },
};
```