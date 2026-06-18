import '../../bridge/project_snapshot.dart';

/// Active long-press drag of a timeline clip.
class ArrangementClipDragSession {
  ArrangementClipDragSession({
    required this.clipId,
    required this.sourceTrackId,
    required this.lengthBeats,
    required this.isMidi,
    required this.originalStartBeat,
    required this.pointerBeatAtStart,
    this.midiClip,
    this.sampleClip,
    this.automationClip,
    required this.targetTrackIndex,
    required this.previewStartBeat,
  });

  final String clipId;
  final String sourceTrackId;
  final double lengthBeats;
  final bool isMidi;
  final double originalStartBeat;
  final double pointerBeatAtStart;
  final MidiClipSnapshot? midiClip;
  final SampleClipSnapshot? sampleClip;

  final AutomationClipSnapshot? automationClip;

  int targetTrackIndex;
  double previewStartBeat;

  ArrangementClipDragSession copyWith({
    int? targetTrackIndex,
    double? previewStartBeat,
  }) {
    return ArrangementClipDragSession(
      clipId: clipId,
      sourceTrackId: sourceTrackId,
      lengthBeats: lengthBeats,
      isMidi: isMidi,
      originalStartBeat: originalStartBeat,
      pointerBeatAtStart: pointerBeatAtStart,
      midiClip: midiClip,
      sampleClip: sampleClip,
      automationClip: automationClip,
      targetTrackIndex: targetTrackIndex ?? this.targetTrackIndex,
      previewStartBeat: previewStartBeat ?? this.previewStartBeat,
    );
  }
}
