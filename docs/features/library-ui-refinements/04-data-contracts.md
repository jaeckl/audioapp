# Library UI Refinements — Data Contracts

## `ClipPreviewCache` (Flutter, new)

### File
`app_flutter/lib/features/content_library/library_preview_cache.dart`

### Contract
```dart
class ClipPreviewCache {
  ClipPreviewCache({int maxEntries = kMaxCacheEntries});

  static const int kMaxCacheEntries = 50;

  /// Returns cached data if present, null otherwise.
  ClipPreviewData? get(String itemId);

  /// Stores data in cache, evicting LRU entry if full.
  void put(String itemId, ClipPreviewData data);

  /// Removes a single entry. Used when cleaning up on item delete.
  void remove(String itemId);

  /// Clears all entries. Called on library close.
  void clear();

  /// Returns current number of cached entries.
  int get size;

  /// Returns true if the itemId has a cached entry.
  bool containsKey(String itemId);
}
```

### Implementation notes
- Uses `LinkedHashMap<String, ClipPreviewData>` with access-order iteration for LRU
- On `get`: move entry to end (most recently used)
- On `put` when at capacity: remove first entry (least recently used), then insert
- Not thread-safe — called from Flutter UI thread only

---

## `LibraryPreviewState` enum (Flutter, new)

### File
`app_flutter/lib/features/content_library/library_preview_state.dart` (or inline in `library_fly_in_panel.dart`)

```dart
enum LibraryPreviewState {
  none,
  audio,
  midi,
  automation,
  preset,
}
```

---

## Preview state shape (in `LibraryFlyInPanelState`)

```dart
// In LibraryFlyInPanelState:

String? _previewingItemId;       // Which item is currently previewing
LibraryPreviewState _previewState = LibraryPreviewState.none;
bool _presetPreviewLoopEnabled = true;
```

---

## `PresetPreviewBar` configuration (Flutter, new)

### File
`app_flutter/lib/features/content_library/library_preset_preview_bar.dart`

### Widget inputs
```dart
class PresetPreviewBar extends StatefulWidget {
  const PresetPreviewBar({
    super.key,
    required this.trackSnapshot,    // TrackSnapshot for clip positions
    required this.accent,           // Theme accent color
    required this.loopEnabled,      // 8-bar loop toggle
    required this.onLoopToggled,    // Callback when loop toggled
    required this.onScrub,          // Callback when user drags scrub handle
    required this.playheadBeats,    // Current playhead position
    this.height = 64,               // Bar height
  });
}
```

### Internal state
```dart
double _localPlayheadBeats;   // Adjusted by scrubbing
bool _isDragging = false;
```

### Layout
```
┌─────────────────────────────────────────────┐
│ [🔁]   ▐█▌    ▐███▌          ▐█▌           │
│ Loop   │ clip │  clip  │     │ clip │       │
│ on     └──────┴────────┘     └──────┘       │
│        ▲ scrub handle                        │
└─────────────────────────────────────────────┘
```

---

## Engine-side: `FallbackPreviewOscillator` state (C++, new)

### File
`engine_juce/include/audioapp/FallbackPreviewOscillator.hpp`

### Contract
```cpp
namespace audioapp {

static constexpr int kPreviewMaxVoices = 8;

struct PreviewVoiceState {
    bool active = false;
    int pitch = 60;
    float velocity = 100.0f;
    double startBeat = 0.0;
    double durationBeats = 1.0;
    float phase = 0.0f;
};

class FallbackPreviewOscillator {
public:
    void reset() noexcept;
    void noteOn(int pitch, float velocity, double startBeat, double durationBeats) noexcept;
    void noteOff(int pitch) noexcept;
    void allNotesOff() noexcept;
    void processBlock(float* monoOut, int numFrames, double sampleRate, double playheadBeat) noexcept;

private:
    PreviewVoiceState voices_[kPreviewMaxVoices];
    int stealIndex_ = 0;
};

} // namespace audioapp
```

### Implementation notes
- Simple sine-wave oscillator per voice (no filter, no envelope — minimal CPU)
- Voice stealing: oldest active voice replaced when all 8 slots full
- Velocity affects amplitude linearly
- `processBlock` iterates voices, generates sine at pitch frequency, sums to mono

---

## Engine-side: `PresetPreviewSlot` state (C++, new)

### File
`engine_juce/src/PresetPreviewSlot.cpp` (internal detail)

### Contract
```cpp
namespace audioapp {

struct PresetPreviewSlot {
    std::string deviceId;              // Which device was cloned
    std::string deviceType;            // Type identifier
    // Saved parameter state (restore point)
    DeviceSlot originalSlot;           // Full DeviceSlot copy before preview
    DeviceSlot previewSlot;            // Temporary DeviceSlot with preset applied
    bool active = false;
};

} // namespace audioapp
```

### Behavior
- On `previewPreset`: copy the DeviceSlot, apply preset params to `previewSlot`
- On `stopPresetPreview`: copy `originalSlot` back to the actual device slot, set `active = false`
- If a new preview starts while another is active, save-and-restore happens implicitly