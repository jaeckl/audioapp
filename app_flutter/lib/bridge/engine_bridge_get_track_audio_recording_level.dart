part of 'engine_bridge.dart';

extension EngineBridgeGettrackaudiorecordinglevelOperation on EngineBridge {
  Future<double> getTrackAudioRecordingLevel() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getTrackAudioRecordingLevel',
    );
    if (result == null || result['ok'] != true) return 0;
    return (result['level'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0;
  }
}
