import 'package:flutter/material.dart';
import '../engine_bridge.dart';
import 'effect_device_strip.dart';

/// Panel for configuring Phaser effect.
class PhaserPanel extends StatelessWidget {
  const PhaserPanel({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _loadSnapshot() {
    return EngineBridge.getEffectSnapshot('phaser');
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
        return EffectDeviceStrip(type: 'phaser', snapshot: data);
      },
    );
  }
}
