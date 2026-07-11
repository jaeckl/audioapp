part of 'engine_bridge.dart';

extension EngineBridgeSetplayheadbeatsOperation on EngineBridge {
Future<void> setPlayheadBeats(double playheadBeats) async {
    await invokeRaw('setPlayheadBeats', {'playheadBeats': playheadBeats});
  }
}
