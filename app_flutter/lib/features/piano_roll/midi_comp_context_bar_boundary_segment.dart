part of 'midi_comp_context_bar.dart';

class _BoundarySegment extends StatelessWidget {
  const _BoundarySegment({
    required this.holdPrevious,
    required this.onChanged,
  });

  final bool holdPrevious;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: PianoRollTheme.dockBackground,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3B3B49)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('CUT', !holdPrevious, () => onChanged(false)),
          _seg('RING', holdPrevious, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active
          ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.28)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : PianoRollTheme.labelMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
