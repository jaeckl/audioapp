part of 'engine_bridge.dart';

extension EngineBridgeBatchupdatelfoparamsOperation on EngineBridge {
  Future<ProjectSnapshot> batchUpdateLfoParams({
    required int lfoId,
    required List<Map<String, dynamic>> params,
  }) async {
    return _invokeForSnapshot('batchUpdateLfoParams', {
      'lfoId': lfoId,
      'params': params,
    });
  }
}
