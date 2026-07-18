part of 'piano_roll_key_column.dart';

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.pitch,
    required this.rowHeight,
    this.highlight = false,
    this.selected = false,
    this.onTap,
    this.label,
    this.enabled = true,
    this.drumLane = false,
    this.row = 0,
  });

  final int pitch;
  final double rowHeight;
  final bool highlight;
  final bool selected;
  final VoidCallback? onTap;
  final String? label;
  final bool enabled;
  final bool drumLane;
  final int row;

  bool get _isBlack => PianoRollNoteOps.isBlackKey(pitch);

  @override
  Widget build(BuildContext context) {
    final isC = pitch % 12 == 0;
    final Color bg;
    if (selected) {
      bg = const Color(0xFF3A2A30);
    } else if (drumLane) {
      bg = row.isEven ? const Color(0xFF24242D) : const Color(0xFF202029);
    } else if (!enabled) {
      bg = PianoRollTheme.keyColumnBackground;
    } else if (_isBlack) {
      bg = PianoRollTheme.blackKeyRow;
    } else {
      bg = PianoRollTheme.whiteKeyRow;
    }

    final showLabel =
        enabled && (label != null || isC || highlight || selected);
    final Color labelColor;
    if (selected) {
      labelColor = PianoRollTheme.accent;
    } else if (highlight) {
      labelColor = const Color(0xFFE8A060);
    } else if (_isBlack) {
      labelColor = PianoRollTheme.cKeyAccent;
    } else {
      labelColor = PianoRollTheme.whiteKeyLabel;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTap == null ? null : (_) => onTap!(),
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(
              color: drumLane
                  ? const Color(0xFF41414F)
                  : (_isBlack
                      ? const Color(0xFF1E1E24)
                      : const Color(0xFFD9D0C4)),
              width: drumLane ? 1 : 0.5,
            ),
            left: selected
                ? const BorderSide(color: PianoRollTheme.accent, width: 2)
                : highlight
                    ? const BorderSide(color: Color(0xFFE8A060), width: 2)
                    : BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: showLabel
            ? Text(
                label ??
                    ((highlight || selected)
                        ? PianoRollMetrics.noteLabel(pitch)
                        : PianoRollMetrics.octaveLabel(pitch)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: (highlight || selected) ? 8 : 9,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              )
            : null,
      ),
    );
  }
}
