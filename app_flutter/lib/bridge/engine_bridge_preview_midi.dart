part of 'engine_bridge.dart';

extension EngineBridgePreviewmidiOperation on EngineBridge {
  Future<void> previewMidi({
    required List<MidiNoteSnapshot> notes,
    required double lengthBeats,
    required int bpm,
    double startBeat = 0.0,
    bool loop = true,
  }) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('previewMidi', {
      'notes': notes
          .map((n) => {
                'pitch': n.pitch,
                'startBeat': n.startBeat,
                'durationBeats': n.durationBeats,
                'velocity': n.velocity,
              })
          .toList(),
      'lengthBeats': lengthBeats,
      'bpm': bpm,
      'startBeat': startBeat,
      'loop': loop,
    });
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preview_midi_failed',
        message: 'Failed to preview MIDI',
      );
    }
  }
}
