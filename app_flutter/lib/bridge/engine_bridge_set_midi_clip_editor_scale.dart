part of 'engine_bridge.dart';

extension EngineBridgeSetmidiclipeditorscaleOperation on EngineBridge {
Future<void> setMidiClipEditorScale({
    required String clipId,
    required int rootPitchClass,
    required String scaleId,
    required bool highlight,
    required bool snapToScale,
    required String chordQuality,
  }) async {
    await _invokeOk('setMidiClipEditorScale', {
      'clipId': clipId,
      'rootPitchClass': rootPitchClass,
      'scaleId': scaleId,
      'highlight': highlight,
      'snapToScale': snapToScale,
      'chordQuality': chordQuality,
    });
  }
}
