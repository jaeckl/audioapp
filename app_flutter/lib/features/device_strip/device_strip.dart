import 'package:flutter/material.dart';

class DeviceStrip extends StatelessWidget {
  const DeviceStrip({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
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

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF121218),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device strip', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _DeviceCard(title: 'Oscillator', subtitle: 'Instrument'),
                SizedBox(width: 8),
                _DeviceCard(title: '+ Device', subtitle: 'Add (M02)'),
              ],
            ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
