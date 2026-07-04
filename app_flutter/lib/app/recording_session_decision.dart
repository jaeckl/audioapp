import '../bridge/project_snapshot.dart';
import '../features/device_strip/device_strip_device_kind.dart';

class RecordingSessionDecision {
  const RecordingSessionDecision({
    required this.trackId,
    required this.recordAudio,
    required this.recordMidi,
    required this.recordAutomation,
  });

  final String trackId;
  final bool recordAudio;
  final bool recordMidi;
  final bool recordAutomation;

  bool get active => recordAudio || recordMidi || recordAutomation;

  String get modeLabel {
    final modes = <String>[
      if (recordAudio) 'AUDIO',
      if (recordMidi) 'MIDI',
    ];
    return modes.isEmpty ? 'REC' : 'REC ${modes.join(' + ')}';
  }
}

RecordingSessionDecision? decideRecordingSession(ProjectSnapshot? snapshot) {
  final track = snapshot?.selectedTrack;
  if (snapshot?.recordArmed != true ||
      track == null ||
      track.isGroup ||
      track.freeze.enabled) {
    return null;
  }

  final recordMidi = track.visibleInstrumentCount > 0;
  return RecordingSessionDecision(
    trackId: track.id,
    recordAudio: !recordMidi,
    recordMidi: recordMidi,
    recordAutomation: true,
  );
}
