part of 'engine_bridge.dart';

extension EngineBridgeRegisterdemosampleOperation on EngineBridge {
  Future<ProjectSnapshot> registerDemoSample({
    required String id,
    required String name,
    required Uint8List bytes,
  }) =>
      _invokeForSnapshot('registerDemoSample', {
        'id': id,
        'name': name,
        'bytes': bytes,
      });
}
