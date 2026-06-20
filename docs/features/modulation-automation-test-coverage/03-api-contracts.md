# API Contracts

All test files use existing, proven APIs. No new engine production code is required.

## EngineHost API surface used by tests

```cpp
// Lifecycle
host.createProject();
std::string trackId = host.addTrack("name");
host.selectTrack(trackId);

// Devices
std::string devId = host.addDeviceToTrack(trackId, "device_type");
host.setDeviceParameter(devId, "paramId", 0.5f);

// MIDI clips
std::string clipId = host.createMidiClip(trackId, 0.0, 4.0);
host.setMidiClipNotes(clipId, notes);  // vector<MidiNoteState>

// Automation
std::string aclipId = host.createAutomationClip(trackId, 0.0, 4.0);
host.assignAutomationTarget(aclipId, devId, "paramId");
host.setAutomationPoints(aclipId, points);  // vector<AutomationPointState>

// LFO / Modulation
int lfoId = host.createLfo(modulatorType);          // 0=LFO, 1=ADSR, 2=ADR
host.updateLfoParam(lfoId, "paramName", value);
host.assignModulation(lfoId, devId, "paramId", amount);   // amount ∈ [-1, 1]
host.removeModulation(lfoId, "paramId");
host.removeLfo(lfoId);

// Playback + render
host.setPlaying(true);
std::vector<float> block = host.renderOffline(lengthBeats, sampleRate);

// Persistence
std::string json = host.getProjectFileJson();
host.loadProjectFileJson(json);
```

## Audio analysis helpers (pattern, inline in each test file)

```cpp
float rms(const std::vector<float>& samples, int start, int count);
float peak(const std::vector<float>& samples, int start, int count);
float highFrequencyEnergy(const std::vector<float>& samples, int start, int count);
bool modulationChangedFilter(const std::vector<float>& samples, int windowA, int windowB, int windowSize);
bool filterSweepDetected(const std::vector<float>& block, int windows, float minRatio);
```

## LFO `updateLfoParam` parameters

| `param` string | Value meaning | Valid range | Notes |
| -------------- | ------------- | ----------- | ----- |
| `"waveform"` | Waveform enum | 0–4 (Sine=0, Tri=1, Saw=2, Square=3, Ramp=4) | |
| `"rate"` | Rate/frequency | 0.01–1.0 (UI normalized) | Maps to 0.05–8.0 Hz or 0.25x–4x sync |
| `"syncDivision"` | Sync division | 0–5 (0=free, 1=1/1, 2=1/2, 3=1/4, 4=1/8, 5=1/16) | |
| `"retrigger"` | Retrigger mode | 0–2 (0=Free, 1=Sync, 2=OnNote) | |
| `"phase"` | Initial phase | 0.0–1.0 | |
| `"polarity"` | Polarity | 0–2 (0=bipolar, 1=positive, 2=negative) | |
| `"attack"` | Envelope attack | 0.0–1.0 | For ADSR/ADR |
| `"decay"` | Envelope decay | 0.0–1.0 | |
| `"sustain"` | Envelope sustain | 0.0–1.0 | For ADSR only |
| `"release"` | Envelope release | 0.0–1.0 | |
| `"modulatorType"` | Type | 0–2 (0=LFO, 1=ADSR, 2=ADR) | |

## Flutter Bridge API surface (mocked)

```dart
bridge.createLfo(modulatorType: 0)       → ProjectSnapshot
bridge.removeLfo(lfoId)                   → ProjectSnapshot
bridge.updateLfoParam(lfoId:, param:, value:) → ProjectSnapshot
bridge.assignModulation(lfoId:, deviceId:, paramId:, amount:) → ProjectSnapshot
bridge.removeModulation(lfoId:, paramId:) → ProjectSnapshot
bridge.getProjectSnapshot()               → ProjectSnapshot
bridge.saveProject()                      → String URI
bridge.loadProject()                      → ProjectSnapshot?
```

## Flutter snapshot types (mocked return values)

```dart
LfoSnapshot.fromMap(Map) → LfoSnapshot
  fields: id, modulatorType, retrigger, waveform, rate, syncDivision,
          phase, polarity, attack, decay, sustain, release, name

ModulationEdgeSnapshot.fromMap(Map) → ModulationEdgeSnapshot
  fields: lfoId, deviceId, paramId, amount

ProjectSnapshot.fromMap(Map) → ProjectSnapshot
  fields: ..., lfos (List<LfoSnapshot>), modEdges (List<ModulationEdgeSnapshot>),
          automationClips (List<AutomationClipSnapshot>)
```