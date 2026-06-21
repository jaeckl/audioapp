# Library UI Refinements — API Contracts

## Bridge: New method — `previewMidi`

### Owner
`EngineBridge` (Flutter), `EngineHost` (C++)

### Dart signature
```dart
Future<void> previewMidi({
  required MidiClipSnapshot clip,
  String? trackId,
  double bpm = 120,
}) async
```

### C++ signature
```cpp
bool previewMidi(const MidiClipState& clip, const std::string& trackId);
```

### Input fields
| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `clip` | `MidiClipSnapshot` / `MidiClipState` | No | — | MIDI notes and timing |
| `trackId` | `String` / `std::string` | Yes (Flutter) | Empty | Selected track ID. Empty = fallback oscillator |
| `bpm` | `double` | No (Flutter) | 120 | Project BPM for tempo-accurate playback |

### `MidiClipSnapshot` (existing, reused)
```dart
class MidiClipSnapshot {
  final String id;
  final double startBeat;
  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;
}
```

### Method channel envelope (Android JNI)
```
Method: 'previewMidi'
Args: {
  'clip': {
    'id': string,
    'startBeat': double,
    'lengthBeats': double,
    'notes': List<{
      'pitch': int,
      'startBeat': double,
      'durationBeats': double,
      'velocity': double,
    }>
  },
  'trackId': string,
  'bpm': double,
}
Returns: { 'ok': true } | { 'ok': false, 'error': string }
```

### Behavior
- Copies MIDI notes into a preview buffer on the engine
- Schedules repeating playback loop (clip length = loop length)
- Plays through the selected track's device chain if trackId is non-empty and has instruments
- Falls back to `FallbackPreviewOscillator` (polyphonic, 8 voices) if track has no instrument or trackId is empty
- Plays at the project BPM for correct tempo/pitch
- Loops continuously until `stopPreview()` is called or a new preview starts

### Error behavior
- Returns `ok: false` if engine is not yet initialized
- Track not found: silent fallback to oscillator (not an error)
- Empty MIDI clip: returns `ok: true` but no audio generated

---

## Bridge: New method — `stopPreview`

### Owner
`EngineBridge` (Flutter), `EngineHost` (C++)

### Dart signature
```dart
Future<void> stopPreview() async
```

### C++ signature
```cpp
void stopPreview();
```

### Method channel envelope
```
Method: 'stopPreview'
Args: {}
Returns: { 'ok': true }
```

### Behavior
- Stops any active MIDI preview playback
- Stops any active audio sample preview (complementary to `previewSample` stop)
- Stops any active preset preview, reverts temporary device slot
- Sends `allNotesOff()` to the engine

---

## Bridge: New method — `previewPreset`

### Owner
`EngineBridge` (Flutter), `EngineHost` (C++)

### Dart signature
```dart
Future<void> previewPreset({
  required String presetId,
  required String deviceType,
}) async
```

### C++ signature
```cpp
bool previewPreset(const std::string& presetId, const std::string& deviceType);
```

### Method channel envelope
```
Method: 'previewPreset'
Args: {
  'presetId': string,
  'deviceType': string,
}
Returns: { 'ok': true } | { 'ok': false, 'error': string }
```

### Behavior
- Engine saves a snapshot of the current device parameters (restore point)
- Creates a temporary clone device slot (does not modify the project's device chain)
- Applies the preset parameters to the clone
- The arrangement continues playing through the clone as if it were the actual device
- Does NOT start transport — arrangement must already be playing or user hits play

### Error behavior
- `ok: false` if deviceType is unknown
- `ok: false` if presetId not found
- Track has no device of matching type: `ok: false` with descriptive error

---

## Bridge: New method — `stopPresetPreview`

### Owner
`EngineBridge` (Flutter), `EngineHost` (C++)

### Dart signature
```dart
Future<void> stopPresetPreview() async
```

### C++ signature
```cpp
void stopPresetPreview();
```

### Method channel envelope
```
Method: 'stopPresetPreview'
Args: {}
Returns: { 'ok': true }
```

### Behavior
- Reverts the temporary device slot to the pre-preview state
- Destroys the clone slot
- Does NOT stop transport

---

## Existing: `onPreviewAudio` (unchanged)

### Owner
`LibraryContentPane`, `DAWShell`

### Current behavior
```dart
final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
```
Plays the audio sample preview via `bridge.previewSample(sampleId)`.

### Refinement
Now also called from `_onItemTap` for audio items (not just play button).

---

## New callback: `onMidiPreviewTap`

### Owner
`LibraryContentPane`

### Dart signature
```dart
final void Function(LibraryMidiItem item)? onMidiPreviewTap;
```

### Behavior
- Called from `_onItemTap` when tapping a MIDI item
- The handler in `DAWShell` calls `bridge.previewMidi(clip: item.clip, trackId: selectedTrackId, bpm: snapshot.bpm)`
- Loop playback until user selects another item or closes library

### Note
This REPLACES the current `onMidiClipTap` for the play-button action as well. The play button now also triggers preview (not insert). Insert is only via the header Insert button.

---

## New callback: `onAutomationPreviewTap`

### Owner
`LibraryContentPane`

### Dart signature
```dart
final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
```

### Behavior
- Called from `_onItemTap` when tapping an automation item
- Handler in `DAWShell` starts playback of the automation curve on the selected track
- If the automation clip has a linked target device/param, applies the curve live
- If the clip is unlinked, sends the raw curve values to the selected track's first instrument filter cutoff (default behavior)

---

## New callback: `onInsertItem`

### Owner
`LibraryContentPane`

### Dart signature
```dart
final VoidCallback? onInsertItem;
```

### Behavior
- Existing `onInsert` behavior was dispatched through `LibraryFlyInPanelState._onInsert`
- The play button no longer inserts — only the header Insert button does
- This callback is internal to `LibraryFlyInPanel` (not exposed to `DAWShell`)

---

## `fetchClipPreview` (unchanged signature, cached)

### Owner
`EngineBridge`

### Current signature
```dart
Future<ClipPreviewData> fetchClipPreview(String itemId)
```

### `ClipPreviewData` (unchanged)
```dart
class ClipPreviewData {
  final List<double> peaks; // Normalised 0.0–1.0
  final Duration length;
}
```

### Refinement
Wrapped in `ClipPreviewCache` — callers check cache first. No contract change.