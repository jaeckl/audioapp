import 'package:flutter/material.dart';

import '../../app/shell_insets.dart';
import 'transport_overflow_sheet.dart';

class TransportBar extends StatelessWidget {
  const TransportBar({
    super.key,
    required this.bpm,
    required this.playheadBeats,
    required this.version,
    required this.loopEnabled,
    required this.loopLengthBeats,
    this.onBpmChanged,
    this.onLoopToggled,
    this.onLoopLengthChanged,
    this.onExportMix,
  });

  final int bpm;
  final double playheadBeats;
  final String version;
  final bool loopEnabled;
  final double loopLengthBeats;
  final ValueChanged<int>? onBpmChanged;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<double>? onLoopLengthChanged;
  final VoidCallback? onExportMix;

  String get _playheadLabel {
    final bar = (playheadBeats / 4).floor() + 1;
    final beat = (playheadBeats % 4).floor() + 1;
    return '$bar.$beat';
  }

  void _nudgeBpm(int delta) {
    onBpmChanged?.call((bpm + delta).clamp(40, 300));
  }

  void _openOverflow(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A22),
      showDragHandle: true,
      builder: (context) => TransportOverflowSheet(
        bpm: bpm,
        loopEnabled: loopEnabled,
        loopLengthBeats: loopLengthBeats,
        onBpmChanged: (value) => onBpmChanged?.call(value),
        onLoopToggled: (value) => onLoopToggled?.call(value),
        onLoopLengthChanged: (value) => onLoopLengthChanged?.call(value),
        onExportMix: onExportMix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positionStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontFamily: 'monospace',
          color: Colors.white70,
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E14),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Slower',
            onPressed: onBpmChanged == null ? null : () => _nudgeBpm(-1),
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$bpm', style: Theme.of(context).textTheme.titleSmall),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Faster',
            onPressed: onBpmChanged == null ? null : () => _nudgeBpm(1),
            icon: const Icon(Icons.add, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: loopEnabled ? 'Loop on' : 'Loop off',
            onPressed: onLoopToggled == null ? null : () => onLoopToggled!(!loopEnabled),
            icon: Icon(
              loopEnabled ? Icons.loop : Icons.loop_outlined,
              size: 20,
              color: loopEnabled ? const Color(0xFFE8A54B) : Colors.white38,
            ),
          ),
          Expanded(
            child: Center(child: Text(_playheadLabel, style: positionStyle)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'More transport options',
            onPressed: onBpmChanged == null ? null : () => _openOverflow(context),
            icon: const Icon(Icons.more_horiz, size: 22, color: Colors.white54),
          ),
          Text(
            'v$version',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.white38,
                ),
          ),
        ],
      ),
    );
  }

  static Widget padded({
    required BuildContext context,
    required int bpm,
    required double playheadBeats,
    required String version,
    required bool loopEnabled,
    required double loopLengthBeats,
    ValueChanged<int>? onBpmChanged,
    ValueChanged<bool>? onLoopToggled,
    ValueChanged<double>? onLoopLengthChanged,
    VoidCallback? onExportMix,
  }) {
    return Padding(
      padding: ShellInsets.headerPadding(context).copyWith(bottom: 4),
      child: TransportBar(
        bpm: bpm,
        playheadBeats: playheadBeats,
        version: version,
        loopEnabled: loopEnabled,
        loopLengthBeats: loopLengthBeats,
        onBpmChanged: onBpmChanged,
        onLoopToggled: onLoopToggled,
        onLoopLengthChanged: onLoopLengthChanged,
        onExportMix: onExportMix,
      ),
    );
  }
}
