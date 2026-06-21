# Data Contracts (JSON / Dart Types)

All new data types live in the Flutter layer (`app_flutter/`). The only new bridge‑returned data type is `ClipPreviewData`; all other types already exist in the codebase.

---

## ClipPreviewData

Returned by `fetchClipPreview(String itemId)` via the bridge. Used to render a miniature waveform in `_LeadingVisual` for MIDI and automation items.

```dart
class ClipPreviewData {
  final List<double> peaks;  // Normalised amplitude peaks (0.0–1.0), ~100 values
  final Duration length;     // Total clip duration, e.g. Duration(milliseconds: 4000)
}
```

### JSON wire format (bridge response)

```json
{
  "peaks": [0.12, 0.45, 0.78, 0.62, 0.33, 0.05, 0.0, 0.21, ...],
  "lengthMs": 4000
}
```

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `peaks` | `List<double>` | Amplitude envelope peaks at regular intervals. | 0.0 – 1.0; length typically 50–200 values. |
| `lengthMs` | `int` | Total clip duration in milliseconds. | ≥ 1 |

### Dart mapping

```dart
ClipPreviewData({
  required this.peaks,
  required this.length,  // Duration(milliseconds: lengthMs)
});
```

### Error behaviour

- Bridge returns an empty `ClipPreviewData` (`peaks: []`, `length: Duration.zero`) on failure.
- Caller (`library_content_pane.dart`) shows a fallback placeholder when `peaks.isEmpty`.

---

## SampleLibraryEntrySnapshot (existing, reference only)

Defined in `app_flutter/lib/bridge/project_snapshot.dart` (line 1239). Unchanged by this feature.

```dart
class SampleLibraryEntrySnapshot {
  final String id;
  final String name;
  final String source;          // "bundled" | "project" | "imported"
  final double durationBeats;
  final List<double> waveformPeaks;
}
```

### JSON wire format

```json
{
  "id": "sample:kick-01",
  "name": "Kick 01",
  "source": "bundled",
  "durationBeats": 4.0,
  "waveformPeaks": [0.0, 0.8, 0.9, 0.6, ...]
}
```

---

## LibraryItem hierarchy (existing, reference only)

Defined in `app_flutter/lib/features/content_library/library_catalog.dart`. Unchanged by this feature.

### Sealed class

```dart
sealed class LibraryItem {
  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
}
```

### Conrete subtypes

| Type | Extra fields | Used for |
|------|-------------|----------|
| `LibraryAudioItem` | `sample: SampleLibraryEntrySnapshot`, `isProjectClip: bool` | Audio samples and project audio clips |
| `LibraryMidiItem` | `clip: MidiClipSnapshot`, `trackId: String?`, `isFactory: bool` | Factory and project MIDI clips |
| `LibraryAutomationItem` | `parameterLabel: String`, `trackId: String?`, `clip: AutomationClipSnapshot?`, `suggestedParamId: String?` | Automation clips and templates |
| `LibraryPresetItem` | `deviceType: String` | Device preset entries |

### `id` prefix conventions

| Subtype | Prefix pattern | Example |
|---------|---------------|---------|
| `LibraryAudioItem` (sample) | `sample:<id>` | `sample:kick-01` |
| `LibraryAudioItem` (clip) | `clip:<clipId>` | `clip:clip_abc123` |
| `LibraryMidiItem` (factory) | manifest entry `id` | `factory_808_pattern` |
| `LibraryMidiItem` (project) | `midi:<clipId>` | `midi:clip_def456` |
| `LibraryAutomationItem` | `auto-clip:<clipId>` | `auto-clip:clip_ghi789` |
| `LibraryPresetItem` | manifest entry `id` | `sub_synth_bright` |

---

## Device preset filter types (static enum)

The `DevicePresetFilterList` widget filters `LibraryPresetItem` entries by their `deviceType` string.  The device type values come from the manifest JSON and represent engine device types known at build time.

### Known device type values (manifest)

These are the canonical `deviceType` strings used in `assets/content_library/manifest.json`:

| Value | Display label | Notes |
|-------|---------------|-------|
| `simple_sampler` | Sampler | – |
| `subtractive_synth` | Synth | – |
| `kick_generator` | Kick | Drum synth |
| `snare_generator` | Snare | Drum synth |
| `clap_generator` | Clap | Drum synth |
| `cymbal_generator` | Cymbal | Drum synth |
| `hi_hat_generator` | Hi‑hat | Drum synth |
| `bass_synth` | Bass Synth | – |
| `dynamics_fx` | Dynamics | Compressor / gate |

### Filter list schema

The `DevicePresetFilterList` widget renders a vertical list of **device type chips** (static). Each chip represents one filter.

```dart
class DevicePresetFilter {
  final String deviceType;    // Canonical device type string
  final String label;         // Human‑readable label
  final IconData icon;        // Material icon for visual identification
}
```

### Static filter entries

```dart
const List<DevicePresetFilter> kDevicePresetFilters = [
  DevicePresetFilter(deviceType: 'simple_sampler',     label: 'Sampler',      icon: Icons.album_outlined),
  DevicePresetFilter(deviceType: 'subtractive_synth',  label: 'Synth',        icon: Icons.waves),
  DevicePresetFilter(deviceType: 'kick_generator',     label: 'Kick',         icon: Icons.circle),
  DevicePresetFilter(deviceType: 'snare_generator',    label: 'Snare',        icon: Icons.circle_outlined),
  DevicePresetFilter(deviceType: 'clap_generator',     label: 'Clap',         icon: Icons.pan_tool_outlined),
  DevicePresetFilter(deviceType: 'cymbal_generator',   label: 'Cymbal',       icon: Icons.music_note_outlined),
  DevicePresetFilter(deviceType: 'hi_hat_generator',   label: 'Hi‑hat',      icon: Icons.timer_outlined),
  DevicePresetFilter(deviceType: 'bass_synth',         label: 'Bass Synth',   icon: Icons.waves),
  DevicePresetFilter(deviceType: 'dynamics_fx',        label: 'Dynamics',     icon: Icons.tune),
];
```

### Filtering logic

When a filter chip is selected (tapped), the parent `LibraryContentPane` filters the current `LibraryPresetItem` list:

```dart
items.where((item) =>
  item is LibraryPresetItem && item.deviceType == selectedDeviceType
)
```

- Only one filter can be active at a time (single‑select, or "All" to clear).
- Selecting a device type **clears** `selectedItemId` if the selected item is no longer visible.
- The filter bar for device presets **replaces** the current `LibraryTagFilterBar` when `category == LibraryCategory.devicePresets`.