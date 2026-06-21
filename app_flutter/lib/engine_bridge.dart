// Engine bridge for communicating with native engine via MethodChannel
import 'package:flutter/services.dart';

class EngineBridge {
  static const MethodChannel _channel = MethodChannel('engine/effect');

  static Future<void> addEffect(String type) async {
    await _channel.invokeMethod('addEffect', {'effectType': type, 'trackId': 0});
  }

  static Future<void> removeEffect(String type) async {
    await _channel.invokeMethod('removeEffect', {'trackId': 0, 'deviceIndex': 0});
  }

  static Future<void> enableEffect(String type, bool enabled) async {
    await _channel.invokeMethod('enableEffect', {'trackId': 0, 'deviceIndex': 0, 'enabled': enabled});
  }

  static Future<void> setEffectParameter(String type, String param, dynamic value) async {
    await _channel.invokeMethod('setEffectParameter', {
      'trackId': 0,
      'deviceIndex': 0,
      'paramName': param,
      'value': value,
    });
  }

  static Future<Map<String, dynamic>> getEffectSnapshot(String type) async {
    final result = await _channel.invokeMethod('getEffectSnapshot', {'trackId': 0, 'deviceIndex': 0});
    // The platform side returns a Map<String, dynamic>
    return Map<String, dynamic>.from(result as Map);
  }
}