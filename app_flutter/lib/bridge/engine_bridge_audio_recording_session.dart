part of 'engine_bridge.dart';

class AudioRecordingSession {
  const AudioRecordingSession({
    required this.snapshot,
    required this.sampleId,
    required this.clipId,
  });

  final ProjectSnapshot snapshot;
  final String sampleId;
  final String clipId;
}
