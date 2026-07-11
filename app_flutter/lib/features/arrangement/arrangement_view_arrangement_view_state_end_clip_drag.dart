part of 'arrangement_view.dart';

extension ArrangementViewStateEndclipdragOperation on ArrangementViewState {
Future<void> _endClipDrag() async {
    final session = _clipDrag;
    if (session == null) {
      return;
    }
    setState(() => _clipDrag = null);

    final targetTrack = widget.snapshot.tracks[session.targetTrackIndex];
    if (targetTrack.isGroup && session.automationClip == null) {
      return;
    }
    await widget.onMoveClip(
      clipId: session.clipId,
      trackId: targetTrack.id,
      startBeat: session.previewStartBeat,
    );
  }
}
