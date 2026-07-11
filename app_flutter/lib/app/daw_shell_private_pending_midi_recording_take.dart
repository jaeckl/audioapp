part of 'daw_shell.dart';

class _PendingMidiRecordingTake {
  const _PendingMidiRecordingTake({
    required this.startBeat,
    required this.endBeat,
    required this.notes,
  });

  final double startBeat;
  final double endBeat;
  final List<MidiNoteSnapshot> notes;

  double get lengthBeats =>
      (endBeat - startBeat).clamp(0.25, 1024.0).toDouble();
}
