part of 'engine_bridge.dart';

extension EngineBridgePreviewpresetOperation on EngineBridge {
  Future<void> previewPreset({
    required String deviceType,
    required Map<String, double> params,
    required List<MidiNoteSnapshot> notes,
    required double lengthBeats,
    required int bpm,
    double startBeat = 0.0,
    bool loop = true,
  }) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('previewPreset', {
      'deviceType': deviceType,
      'params': params,
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
        code: result?['error']?.toString() ?? 'preview_preset_failed',
        message: 'Failed to preview preset',
      );
    }
  }
}
