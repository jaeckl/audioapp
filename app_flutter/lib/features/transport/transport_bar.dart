import 'package:flutter/material.dart';

import '../../app/shell_insets.dart';

class TransportBar extends StatelessWidget {
  const TransportBar({
    super.key,
    required this.bpm,
    required this.playheadBeats,
    required this.version,
  });

  final int bpm;
  final double playheadBeats;
  final String version;

  String get _playheadLabel {
    final bar = (playheadBeats + 1).floor();
    final beat = ((playheadBeats % 1) * 4 + 1).floor();
    return '$bar.$beat.1';
  }

  @override
  Widget build(BuildContext context) {
    final positionStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontFamily: 'monospace',
          color: Colors.white70,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E14),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
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
          Text(_playheadLabel, style: positionStyle),
        ],
      ),
    );
  }

  static Widget padded({
    required BuildContext context,
    required int bpm,
    required double playheadBeats,
    required String version,
  }) {
    return Padding(
      padding: ShellInsets.headerPadding(context).copyWith(bottom: 4),
      child: TransportBar(bpm: bpm, playheadBeats: playheadBeats, version: version),
    );
  }
}
