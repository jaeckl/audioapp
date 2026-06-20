# Test Contract

## Engine test conventions

Every engine test file:
1. Is a standalone `.cpp` with `int main()` — no test framework
2. Returns `EXIT_SUCCESS` (0) on pass, `EXIT_FAILURE` (1) on fail
3. Includes its own inline audio analysis helpers (rms, peak, highFrequencyEnergy, etc.)
4. Uses `audioapp::EngineHost` for project setup and rendering
5. Produces meaningful offline renders (≥48000 samples at 48 kHz)
6. Does NOT modify any production code files
7. Uses canonical parameter name strings from `paramIdFromString()` mapping

### Required includes

```cpp
#include "audioapp/EngineHost.hpp"
#include <cmath>
#include <cstdlib>
#include <vector>

namespace {
// audio analysis helpers inline
}
```

### Audio analysis helper template

```cpp
float rms(const std::vector<float>& samples, int start, int count) {
    double acc = 0.0;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i)
        acc += static_cast<double>(samples[static_cast<size_t>(i)]) *
               static_cast<double>(samples[static_cast<size_t>(i)]);
    return end > start ? static_cast<float>(std::sqrt(acc / (end - start))) : 0.0f;
}

float peak(const std::vector<float>& samples, int start, int count) {
    float p = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start; i < end; ++i)
        p = std::max(p, std::abs(samples[static_cast<size_t>(i)]));
    return p;
}

float highFrequencyEnergy(const std::vector<float>& samples, int start, int count) {
    float energy = 0.0f;
    const int end = std::min(start + count, static_cast<int>(samples.size()));
    for (int i = start + 1; i < end; ++i) {
        const float diff = samples[static_cast<size_t>(i)] - samples[static_cast<size_t>(i - 1)];
        energy += diff * diff;
    }
    return energy;
}

bool filterSweepDetected(const std::vector<float>& block, int windows, float minRatio) {
    const int windowFrames = static_cast<int>(block.size()) / windows;
    if (windowFrames <= 1) return false;
    float brightest = 0.0f;
    float darkest = std::numeric_limits<float>::infinity();
    for (int w = 0; w < windows; ++w) {
        const int start = w * windowFrames;
        const float hf = highFrequencyEnergy(block, start, windowFrames);
        if (hf <= 0.0f) return false;
        brightest = std::max(brightest, hf);
        darkest = std::min(darkest, hf);
    }
    if (darkest <= 0.0f) return false;
    return brightest >= darkest * minRatio;
}
```

### Pattern: TestSetup helper (optional, copy from modulation_e2e_test.cpp)

```cpp
struct TestSetup {
    audioapp::EngineHost host;
    std::string trackId;
    std::string deviceId;
    std::string midiClipId;

    TestSetup() {
        host.createProject();
        trackId = host.addTrack("Test");
        host.selectTrack(trackId);
        deviceId = host.addDeviceToTrack(trackId, "subtractive_synth");
        midiClipId = host.createMidiClip(trackId, 0.0, 4.0);
        std::vector<audioapp::MidiNoteState> notes;
        notes.push_back({60, 0.0, 4.0, 100.0f});
        host.setMidiClipNotes(midiClipId, notes);
    }
};
```

## Flutter test conventions

Every Flutter test file:
1. Uses `TestWidgetsFlutterBinding.ensureInitialized()`
2. Sets up `MethodChannel('com.audioapp.daw/engine')` mock in `setUp`
3. Removes mock handler in `tearDown`
4. Uses existing `EngineBridge` and snapshot types
5. Does NOT modify any production code files
6. Does NOT require a real engine instance

### Mock handler template

```dart
setUp(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'createLfo':
        return {
          'ok': true,
          'snapshot': {
            ...baseSnapshot,
            'lfos': [/* mock LFO */],
          },
        };
      case 'removeLfo':
        return { 'ok': true, 'snapshot': { ...baseSnapshot, 'lfos': [] } };
      // ... other methods
      default:
        return null;
    }
  });
});
```

### Base snapshot template

```dart
const baseSnapshot = {
  'bpm': 120,
  'playheadBeats': 0.0,
  'playing': false,
  'selectedTrackId': 'track-1',
  'loopEnabled': false,
  'loopRegionStartBeat': 0.0,
  'loopRegionEndBeat': 16.0,
  'recordArmed': false,
  'master': { 'id': 'master', 'gain': 1.0 },
  'samples': [],
  'tracks': [
    {
      'id': 'track-1',
      'name': 'Track 1',
      'devices': [],
      'midiClips': [],
      'sampleClips': [],
      'automationClips': [],
    },
  ],
  'lfos': [],
  'modEdges': [],
};
```

## Compilation

### Engine tests (Linux / WSL)

```bash
g++ -I engine_juce/include -std=c++20 \
    engine_juce/tests/<test_name>.cpp \
    build/engine/libaudioapp_engine.a \
    -lasound -lpthread -ldl -lrt \
    -o /tmp/<test_name>
/tmp/<test_name> && echo "PASS" || echo "FAIL"
```

### Flutter tests

```bash
cd app_flutter && flutter test test/<test_name>.dart
```

## Test verification order

1. Compile test (C++) or analyze (Dart) — must succeed
2. Run test — must pass
3. For C++: verify `echo $?` is 0
4. For Flutter: verify `flutter test` exits 0
5. Verify file does not modify any production code (grep for non-test file changes)