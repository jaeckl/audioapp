part of 'engine_bridge.dart';

extension EngineBridgeSetsampleclippropertiesOperation on EngineBridge {
Future<ProjectSnapshot> setSampleClipProperties({
    required String clipId,
    required double sourceStart,
    required double sourceEnd,
    required double gain,
    required double fadeIn,
    required double fadeOut,
    required double fadeInCurve,
    required double fadeOutCurve,
    required bool reversed,
  }) =>
      _invokeForSnapshot('setSampleClipProperties', {
        'clipId': clipId,
        'sourceStart': sourceStart,
        'sourceEnd': sourceEnd,
        'gain': gain,
        'fadeIn': fadeIn,
        'fadeOut': fadeOut,
        'fadeInCurve': fadeInCurve,
        'fadeOutCurve': fadeOutCurve,
        'reversed': reversed,
      });
}
