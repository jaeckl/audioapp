part of 'engine_bridge.dart';

extension EngineBridgeUpdatelfoparamOperation on EngineBridge {
Future<ProjectSnapshot> updateLfoParam({
    required int lfoId,
    required String param,
    required double value,
  }) async {
    return _invokeForSnapshot('updateLfoParam', {
      'lfoId': lfoId,
      'param': param,
      'value': value,
    });
  }
}
