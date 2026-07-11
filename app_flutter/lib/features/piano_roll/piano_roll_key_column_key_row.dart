part of 'piano_roll_key_column.dart';

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.pitch,
    required this.rowHeight,
    this.highlight = false,
    this.onTap,
    this.label,
    this.enabled = true,
    this.drumLane = false,
    this.row = 0,
  });

  final int pitch;
  final double rowHeight;
  final bool highlight;
  final VoidCallback? onTap;
  final String? label;
  final bool enabled;
  final bool drumLane;
  final int row;

  bool get _isBlack => PianoRollNoteOps.isBlackKey(pitch);

  @override
  Widget build(BuildContext context) {
    final isC = pitch % 12 == 0;
    final bg = drumLane
        ? (row.isEven ? const Color(0xFF24242D) : const Color(0xFF202029))
        : !enabled
            ? PianoRollTheme.keyColumnBackground
            : (_isBlack
                ? PianoRollTheme.blackKeyRow
                : PianoRollTheme.whiteKeyRow);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTap == null ? null : (_) => onTap!(),
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF3A3028) : bg,
          border: Border(
            bottom: BorderSide(
              color: drumLane
                  ? const Color(0xFF41414F)
                  : (_isBlack
                      ? const Color(0xFF1E1E24)
                      : const Color(0xFFD9D0C4)),
              width: drumLane ? 1 : 0.5,
            ),
            left: highlight
                ? const BorderSide(color: Color(0xFFE8A060), width: 2)
                : BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: enabled && (label != null || isC || highlight)
            ? Text(
                label ??
                    (highlight
                        ? PianoRollMetrics.noteLabel(pitch)
                        : PianoRollMetrics.octaveLabel(pitch)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
