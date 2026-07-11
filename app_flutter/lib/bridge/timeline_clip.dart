part 'clip_timeline_span.dart';
part 'clip_length_target.dart';

/// Shared timeline span for arrangement clips (MIDI, audio, automation).
enum ClipContentKind { midi, sample, automation }

/// Minimum clip length in beats (matches engine `kMinClipLengthBeats`).
const double kMinClipLengthBeats = 0.25;

/// Which span `setClipLength` updates when loop mode is enabled.
