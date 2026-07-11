part of 'engine_bridge.dart';

extension EngineBridgeSetmetersubscriptionsOperation on EngineBridge {
Future<void> setMeterSubscriptions(List<String> deviceIds) async {
    await _channel.invokeMethod<void>(
      'setMeterSubscriptions',
      {'deviceIds': deviceIds},
    );
  }
}
