import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_note_ops.dart';
import 'piano_roll_theme.dart';

class PianoRollKeyColumn extends StatelessWidget {
  const PianoRollKeyColumn({
    super.key,
    required this.minPitch,
    required this.maxPitch,
    required this.rowHeight,
  });

  final int minPitch;
  final int maxPitch;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final height = PianoRollMetrics.gridHeight(minPitch, maxPitch, rowHeight);
    return SizedBox(
      width: PianoRollMetrics.keyColumnWidth,
      height: height,
      child: ColoredBox(
        color: PianoRollTheme.keyColumnBackground,
        child: Column(
          children: [
            for (var pitch = maxPitch; pitch >= minPitch; pitch--)
              _KeyRow(pitch: pitch, rowHeight: rowHeight),
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.pitch, required this.rowHeight});

  final int pitch;
  final double rowHeight;

  bool get _isBlack => PianoRollNoteOps.isBlackKey(pitch);

  @override
  Widget build(BuildContext context) {
    final isC = pitch % 12 == 0;
    final bg = _isBlack ? PianoRollTheme.blackKeyRow : PianoRollTheme.whiteKeyRow;

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: _isBlack ? const Color(0xFF1E1E24) : const Color(0xFFD9D0C4),
            width: 0.5,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: isC
          ? Text(
              PianoRollMetrics.octaveLabel(pitch),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _isBlack ? PianoRollTheme.cKeyAccent : PianoRollTheme.whiteKeyLabel,
              ),
            )
          : null,
    );
  }
}
