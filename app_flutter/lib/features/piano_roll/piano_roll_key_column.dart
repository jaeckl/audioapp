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
    this.highlightPitch,
    this.onPitchTap,
  });

  final int minPitch;
  final int maxPitch;
  final double rowHeight;

  /// GM drum lane (e.g. 38 = D2 snare) — show full note name on this row.
  final int? highlightPitch;
  final ValueChanged<int>? onPitchTap;

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
              _KeyRow(
                pitch: pitch,
                rowHeight: rowHeight,
                highlight: highlightPitch == pitch,
                onTap: onPitchTap == null ? null : () => onPitchTap!(pitch),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.pitch,
    required this.rowHeight,
    this.highlight = false,
    this.onTap,
  });

  final int pitch;
  final double rowHeight;
  final bool highlight;
  final VoidCallback? onTap;

  bool get _isBlack => PianoRollNoteOps.isBlackKey(pitch);

  @override
  Widget build(BuildContext context) {
    final isC = pitch % 12 == 0;
    final bg =
        _isBlack ? PianoRollTheme.blackKeyRow : PianoRollTheme.whiteKeyRow;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTap == null ? null : (_) => onTap!(),
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF3A3028) : bg,
          border: Border(
            bottom: BorderSide(
              color:
                  _isBlack ? const Color(0xFF1E1E24) : const Color(0xFFD9D0C4),
              width: 0.5,
            ),
            left: highlight
                ? const BorderSide(color: Color(0xFFE8A060), width: 2)
                : BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: (isC || highlight)
            ? Text(
                highlight
                    ? PianoRollMetrics.noteLabel(pitch)
                    : PianoRollMetrics.octaveLabel(pitch),
                style: TextStyle(
                  fontSize: highlight ? 8 : 9,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? const Color(0xFFE8A060)
                      : (_isBlack
                          ? PianoRollTheme.cKeyAccent
                          : PianoRollTheme.whiteKeyLabel),
                ),
              )
            : null,
      ),
    );
  }
}
