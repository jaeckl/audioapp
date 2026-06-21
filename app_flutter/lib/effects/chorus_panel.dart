import 'package:flutter/material.dart';
import '../engine_bridge.dart';
import 'effect_device_strip.dart';

/// Panel for configuring Chorus effect.
class ChorusPanel extends StatelessWidget {
  const ChorusPanel({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _loadSnapshot() {
    return EngineBridge.getEffectSnapshot('chorus');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSnapshot(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data ?? {};
        return EffectDeviceStrip(type: 'chorus', snapshot: data);
      },
    );
  }
}
