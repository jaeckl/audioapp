part of 'engine_bridge.dart';

extension EngineBridgeSetsampleclipslicesOperation on EngineBridge {
Future<ProjectSnapshot> setSampleClipSlices({
    required String clipId,
    required List<double> markers,
  }) =>
      _invokeForSnapshot('setSampleClipSlices', {
        'clipId': clipId,
        'markers': markers,
      });
}
