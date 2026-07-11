part of 'piano_roll_clip_end_marker.dart';

class PianoRollClipEndLine extends StatelessWidget {
  const PianoRollClipEndLine({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: PianoRollTheme.clipEndLineWidth,
          color: PianoRollTheme.clipBoundary,
        ),
      ),
    );
  }
}
