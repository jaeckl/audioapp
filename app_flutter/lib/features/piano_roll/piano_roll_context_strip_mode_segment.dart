part of 'piano_roll_context_strip.dart';

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.notesMode,
    required this.onChanged,
  });

  final bool notesMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: PianoRollTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B3B49)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentTab(
            label: 'Notes',
            active: notesMode,
            onTap: () => onChanged(true),
          ),
          _SegmentTab(
            label: 'Comp',
            active: !notesMode,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}
