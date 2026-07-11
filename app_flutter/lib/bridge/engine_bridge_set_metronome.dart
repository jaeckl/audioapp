part of 'engine_bridge.dart';

extension EngineBridgeSetmetronomeOperation on EngineBridge {
Future<void> setMetronome({
    required bool enabled,
    required double level,
    required int countInBars,
  }) =>
      _invokeOk('setMetronome', {
        'enabled': enabled,
        'level': level,
        'countInBars': countInBars,
      });
}
