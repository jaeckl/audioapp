part of 'engine_bridge.dart';

extension EngineBridgeCommitcaptureOperation on EngineBridge {
  Future<ProjectSnapshot> commitCapture() async {
    return _invokeForSnapshot('commitCapture');
  }
}
