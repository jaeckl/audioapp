part of 'arrangement_view.dart';

extension ArrangementViewStateStartclipresizeOperation on ArrangementViewState {
void _startClipResize({
    required String clipId,
    required String trackId,
    required double startBeat,
    required double lengthBeats,
    required Offset globalPosition,
    required double adjacentClipStartBeat,
    required ClipContentKind kind,
  }) {
    final pointerBeatAtStart = _beatFromGlobal(globalPosition);
    final minLength = _resizeMinLengthForKind(kind);
    final previewLengthBeats =
        lengthBeats < minLength ? minLength : lengthBeats;
    final session = _ClipResizeSession(
      clipId: clipId,
      trackId: trackId,
      originalLengthBeats: lengthBeats,
      startBeat: startBeat,
      adjacentClipStartBeat: adjacentClipStartBeat,
      pointerBeatAtStart: pointerBeatAtStart,
      previewLengthBeats: previewLengthBeats,
    );
    HapticFeedback.mediumImpact();
    if (widget.followPlayheadEnabled && widget.playing) {
      _suspendFollow();
    }
    setState(() => _resizeSession = session);
  }
}
