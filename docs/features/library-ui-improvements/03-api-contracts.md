# API Contracts – Library UI Improvements

## Overview
The UI layer interacts with the native bridge to fetch previews and perform insert actions. The following public functions/events are defined for this feature.

| API Name | Owner | Description | Input | Output | Threading / Async | Errors |
|----------|-------|-------------|-------|--------|-------------------|--------|
| `onPreviewAudio` | UI | Request audio preview playback for a sample library entry. | `SampleLibraryEntrySnapshot sample` | `void` (plays audio) | UI thread, async bridge call | Throws if preview data unavailable (shows toast). |
| `onInsertAudio` | UI | Insert selected audio sample into the current project. | `SampleLibraryEntrySnapshot sample` | `void` | UI thread, async bridge call | Errors propagate as toast; no insertion if validation fails. |
| `fetchClipPreview` | Bridge | Returns waveform peak data for a given library item ID (audio, MIDI, automation). | `String itemId` | `Future<ClipPreviewData>` | Runs off‑main thread, returns `Future`. | Returns empty data on failure; caller must handle fallback. |
| `globalInsertAction` | UI | Inserts the currently selected library item (audio, MIDI, automation, preset). | `String selectedItemId` | `void` | UI thread, async bridge call using specific insert callbacks. | No‑op if `selectedItemId` is null or item type unsupported. |

## Data Types

```dart
// Represents waveform data for a clip preview.
class ClipPreviewData {
  final List<double> peaks; // Normalised amplitude peaks (0.0‑1.0)
  final Duration length;   // Duration of the preview clip.
  const ClipPreviewData({required this.peaks, required this.length});
}

// Existing type used for audio samples.
class SampleLibraryEntrySnapshot {
  final String id; // Unique identifier across library items.
  final List<double> waveformPeaks; // Used by existing waveform painter.
  // ... other fields omitted for brevity
}
```

## Event Flow
1. User taps **play preview** button → UI calls `onPreviewAudio` → bridge streams audio.
2. UI needs visual waveform for MIDI/automation → UI calls `fetchClipPreview(itemId)` → bridge returns `ClipPreviewData` → `_LeadingVisual` renders using `WaveformPainter`.
3. User selects an item (tap on tile) → UI updates `selectedItemId` state; no immediate insert.
4. User presses **global Insert** button → UI calls `globalInsertAction(selectedItemId)` → bridge inserts based on item type.

All callbacks must be invoked on the Flutter UI thread; bridge implementations run on a background isolate.
