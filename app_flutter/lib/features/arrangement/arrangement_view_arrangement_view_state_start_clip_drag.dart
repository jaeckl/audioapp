part of 'arrangement_view.dart';

extension ArrangementViewStateStartclipdragOperation on ArrangementViewState {
void _startClipDrag({
    required String trackId,
    required String clipId,
    required double lengthBeats,
    required bool isMidi,
    required double originalStartBeat,
    required Offset globalPosition,
    MidiClipSnapshot? midiClip,
    SampleClipSnapshot? sampleClip,
    AutomationClipSnapshot? automationClip,
  }) {
    final pointerBeat = _beatFromGlobal(globalPosition);
    final trackIndex = _sourceTrackIndex(trackId);
    final track = _trackByIndex(trackIndex);
    final session = ArrangementClipDragSession(
      clipId: clipId,
      sourceTrackId: trackId,
      lengthBeats: lengthBeats,
      isMidi: isMidi,
      originalStartBeat: originalStartBeat,
      pointerBeatAtStart: pointerBeat,
      midiClip: midiClip,
      sampleClip: sampleClip,
      automationClip: automationClip,
      targetTrackIndex: trackIndex,
      previewStartBeat: originalStartBeat,
    );
    final previewStart = _previewStartBeatForTrack(
      track,
      session,
      _desiredBeatForDrag(globalPosition, session),
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _clipDrag = session.copyWith(previewStartBeat: previewStart);
    });
  }
}
