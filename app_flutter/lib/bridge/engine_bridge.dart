import 'package:flutter/services.dart';

/// Flutter ↔ native engine bridge (MethodChannel).
class EngineBridge {
  EngineBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.audioapp.daw/engine');

  final MethodChannel _channel;

  Future<String> ping() async {
    final result = await _channel.invokeMethod<String>('ping');
    return result ?? '';
  }

  Future<void> play() async {
    await _channel.invokeMethod<void>('play');
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }
}
