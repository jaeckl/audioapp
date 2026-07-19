part of 'arrangement_view.dart';

extension ArrangementViewStateUpdateclipdragatOperation on ArrangementViewState {
void _updateClipDragAt(Offset globalPosition) {
    final session = _clipDrag;
    if (session == null) {
      return;
    }
    final targetIndex = _trackIndexFromGlobal(globalPosition);
    final targetTrack = _trackByIndex(targetIndex);
    final desiredBeat = _desiredBeatForDrag(globalPosition, session);
    final previewStart =
        _previewStartBeatForTrack(targetTrack, session, desiredBeat);
    setState(() {
      _clipDrag = session.copyWith(
        targetTrackIndex: targetIndex,
        previewStartBeat: previewStart,
      );
    });
  }
}
