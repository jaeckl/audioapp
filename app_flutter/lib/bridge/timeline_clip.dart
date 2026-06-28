/// Shared timeline span for arrangement clips (MIDI, audio, automation).
enum ClipContentKind { midi, sample, automation }

abstract class ClipTimelineSpan {
  String get id;
  double get startBeat;
  double get lengthBeats;
  ClipContentKind get kind;

  double get endBeat => startBeat + lengthBeats;
}

/// Minimum clip length in beats (matches engine `kMinClipLengthBeats`).
const double kMinClipLengthBeats = 0.25;

/// Which span `setClipLength` updates when loop mode is enabled.
enum ClipLengthTarget { arrangement, content }
