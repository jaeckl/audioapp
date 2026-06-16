import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

class DeviceStrip extends StatelessWidget {
  const DeviceStrip({
    super.key,
    required this.track,
    required this.onFrequencyChanged,
  });

  final TrackSnapshot? track;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        color: const Color(0xFF121218),
        child: Text(
          'Select a track to show device strip',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white38),
        ),
      );
    }

    DeviceSnapshot? oscillator;
    for (final device in track!.visibleDevices) {
      if (device.type == 'simple_oscillator') {
        oscillator = device;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF121218),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device strip — ${track!.name}', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          if (oscillator == null)
            Text(
              'No instrument on this track',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
            )
          else
            Row(
              children: [
                _DeviceCard(
                  title: 'Oscillator',
                  subtitle: '${oscillator.frequencyHz.round()} Hz',
                ),
                const SizedBox(width: 12),
                const Text('Frequency'),
                Expanded(
                  child: Slider(
                    min: 110,
                    max: 880,
                    divisions: 14,
                    value: oscillator.frequencyHz.clamp(110, 880),
                    label: '${oscillator.frequencyHz.round()} Hz',
                    onChanged: (value) => onFrequencyChanged(oscillator!.id, value),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        '$title · $subtitle',
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
