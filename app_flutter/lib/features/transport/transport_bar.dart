import 'package:flutter/material.dart';

import '../../app/shell_insets.dart';

class TransportBar extends StatelessWidget {
  const TransportBar({
    super.key,
    required this.bpm,
    required this.version,
  });

  final int bpm;
  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E14),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Text('BPM $bpm', style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          Text(
            'v$version',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.white54,
                ),
          ),
        ],
      ),
    );
  }

  static Widget padded({
    required BuildContext context,
    required int bpm,
    required String version,
  }) {
    return Padding(
      padding: ShellInsets.headerPadding(context).copyWith(bottom: 4),
      child: TransportBar(bpm: bpm, version: version),
    );
  }
}
