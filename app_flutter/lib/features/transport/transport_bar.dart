import 'package:flutter/material.dart';

class TransportBar extends StatelessWidget {
  const TransportBar({
    super.key,
    required this.playing,
    required this.bpm,
    required this.onPlayStop,
  });

  final bool playing;
  final int bpm;
  final VoidCallback onPlayStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E14),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: onPlayStop,
            icon: Icon(playing ? Icons.stop : Icons.play_arrow),
            tooltip: playing ? 'Stop' : 'Play',
          ),
          const SizedBox(width: 16),
          Text('BPM $bpm', style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          Text(
            '1.1.1',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}
