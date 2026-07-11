part of 'arrangement_view.dart';

class _ClipResizeSession {
  _ClipResizeSession({
    required this.clipId,
    required this.trackId,
    required this.originalLengthBeats,
    required this.startBeat,
    required this.adjacentClipStartBeat,
    required this.pointerBeatAtStart,
    required this.previewLengthBeats,
  });

  final String clipId;
  final String trackId;
  final double originalLengthBeats;
  final double startBeat;

  /// Beat of the next clip's start on the same track lane, or
  /// `double.infinity` if there is no adjacent clip.
  final double adjacentClipStartBeat;

  /// Timeline beat under the pointer at drag start (for computing delta).
  final double pointerBeatAtStart;

  /// Live-updating preview during drag; initially equals [originalLengthBeats].
  /// After [committed] flips to true this is treated as the target end-pill
  /// position — the resize handle stays at this x until the engine snapshot
  /// catches up so the UI does not snap back.
  double previewLengthBeats;

  /// True once the gesture has ended and we are waiting for the bridge to
  /// commit. While true, the resize handle continues to render at the
  /// preview position instead of reverting to the original clip end.
  bool committed = false;

  /// Maximum allowed length before overlapping the next clip on this track.
  double get maxLengthBeats => adjacentClipStartBeat.isFinite
      ? (adjacentClipStartBeat - startBeat)
      : double.infinity;
}
