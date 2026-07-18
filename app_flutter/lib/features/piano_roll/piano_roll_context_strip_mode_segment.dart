part of 'piano_roll_context_strip.dart';

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.centerMode,
    required this.showCompTab,
    required this.showHarmonicTab,
    required this.onChanged,
  });

  final PianoRollCenterMode centerMode;
  final bool showCompTab;
  final bool showHarmonicTab;
  final ValueChanged<PianoRollCenterMode> onChanged;

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
            active: centerMode == PianoRollCenterMode.notes,
            onTap: () => onChanged(PianoRollCenterMode.notes),
          ),
          if (showHarmonicTab) ...[
            _SegmentTab(
              label: 'Harmonic',
              active: centerMode == PianoRollCenterMode.harmonic,
              onTap: () => onChanged(PianoRollCenterMode.harmonic),
            ),
            _SegmentTab(
              label: 'Progression',
              active: centerMode == PianoRollCenterMode.progression,
              onTap: () => onChanged(PianoRollCenterMode.progression),
            ),
            _SegmentTab(
              label: 'Rhythm',
              active: centerMode == PianoRollCenterMode.rhythm,
              onTap: () => onChanged(PianoRollCenterMode.rhythm),
            ),
          ],
          if (showCompTab)
            _SegmentTab(
              label: 'Comp',
              active: centerMode == PianoRollCenterMode.comp,
              onTap: () => onChanged(PianoRollCenterMode.comp),
            ),
        ],
      ),
    );
  }
}
