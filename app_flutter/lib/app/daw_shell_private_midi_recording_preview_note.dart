part of 'daw_shell.dart';

class _MidiRecordingPreviewNote {
  const _MidiRecordingPreviewNote({
    required this.pitch,
    required this.startBeat,
    required this.velocity,
  });

  final int pitch;
  final double startBeat;
  final double velocity;
}
