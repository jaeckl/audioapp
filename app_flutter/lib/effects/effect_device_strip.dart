import 'package:flutter/material.dart';
import '../engine_bridge.dart';

/// A reusable UI strip for a single effect device.
///
/// It displays an enable switch and a set of sliders for the effect's
/// parameters. The caller supplies the effect [type] and a [snapshot]
/// containing the current state returned from the native engine. When a
/// control changes, it forwards the update via [EngineBridge].
class EffectDeviceStrip extends StatelessWidget {
  final String type;
  final Map<String, dynamic> snapshot;

  const EffectDeviceStrip({
    Key? key,
    required this.type,
    required this.snapshot,
  }) : super(key: key);

  // Parameter configuration: min, max for each known parameter.
  static const Map<String, Map<String, List<double>>> _paramRanges = {
    'delay': {
      'timeMs': [0, 2000],
      'feedback': [0, 0.95],
      'mix': [0, 1],
      'filterCutoffHz': [20, 20000],
    },
    'reverb': {
      'roomSize': [0, 1],
      'damping': [0, 1],
      'wetLevel': [0, 1],
      'dryLevel': [0, 1],
      'width': [0, 1],
    },
    'chorus': {
      'depth': [0, 1],
      'rateHz': [0.1, 5],
      'mix': [0, 1],
      'centreDelayMs': [0, 20],
      'feedback': [0, 0.95],
    },
    'phaser': {
      'depth': [0, 1],
      'rateHz': [0.1, 5],
      'feedback': [0, 0.95],
      'centreFrequencyHz': [20, 20000],
    },
  };

  @override
  Widget build(BuildContext context) {
    final bool enabled = snapshot['enabled'] as bool? ?? false;
    final Map<String, dynamic> params = snapshot['params'] as Map<String, dynamic>? ?? {};
    final ranges = _paramRanges[type] ?? {};

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${type[0].toUpperCase()}${type.substring(1)} Effect',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) async {
                    await EngineBridge.enableEffect(type, value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...params.entries.map((e) {
              final param = e.key;
              final double value = (e.value as num).toDouble();
              final range = ranges[param];
              if (range == null) return const SizedBox.shrink();
              final min = range[0];
              final max = range[1];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$param: ${value.toStringAsFixed(2)}'),
                  Slider(
                    min: min,
                    max: max,
                    divisions: 100,
                    value: value.clamp(min, max),
                    onChanged: (newVal) async {
                      await EngineBridge.setEffectParameter(type, param, newVal);
                    },
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
