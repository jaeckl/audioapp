part of 'midi_take_comp_view.dart';

class _MidiTakeLabelRail extends StatelessWidget {
  const _MidiTakeLabelRail({
    required this.height,
    required this.laneHeight,
    required this.laneGap,
    required this.takes,
    this.compMode = false,
    this.activeTakeIdAtPlayhead,
  });

  final double height;
  final double laneHeight;
  final double laneGap;
  final List<MidiClipTakeSnapshot> takes;
  final bool compMode;
  final String? activeTakeIdAtPlayhead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MidiTakeCompViewState._labelRailWidth,
      height: height,
      child: ColoredBox(
        color: PianoRollTheme.keyColumnBackground,
        child: Stack(
          children: [
            _label(top: 0, height: laneHeight, text: 'COMP'),
            for (final entry in takes.indexed)
              _label(
                top: (entry.$1 + 1) * (laneHeight + laneGap),
                height: laneHeight,
                text: entry.$2.name,
                accent: MidiTakeColor.forIndex(entry.$1),
                highlighted:
                    compMode && entry.$2.id == activeTakeIdAtPlayhead,
              ),
          ],
        ),
      ),
    );
  }

  Widget _label({
    required double top,
    required double height,
    required String text,
    Color? accent,
    bool highlighted = false,
  }) {
    return Positioned(
      left: 0,
      top: top,
      right: 0,
      height: height,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: accent == null
              ? null
              : MidiTakeColor.laneAccentFill(accent, highlighted: highlighted),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            left: accent == null
                ? BorderSide.none
                : BorderSide(
                    color: MidiTakeColor.laneAccentBorder(
                      accent,
                      highlighted: highlighted,
                    ),
                    width: highlighted ? 3 : 2,
                  ),
          ),
        ),
        child: RotatedBox(
          quarterTurns: -1,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlighted ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
