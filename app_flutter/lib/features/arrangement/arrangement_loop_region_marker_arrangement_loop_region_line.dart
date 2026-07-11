part of 'arrangement_loop_region_marker.dart';

class ArrangementLoopRegionLine extends StatelessWidget {
  const ArrangementLoopRegionLine({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: PianoRollMetrics.clipEndLineWidth,
          color: ArrangementLoopRegionTheme.color,
        ),
      ),
    );
  }
}
