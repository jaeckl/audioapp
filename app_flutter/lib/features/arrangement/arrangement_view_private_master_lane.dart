part of 'arrangement_view.dart';

class _MasterLane extends StatelessWidget {
  const _MasterLane({
    required this.width,
    required this.timelineEndBeat,
    required this.pixelsPerBeat,
    required this.regionStartBeat,
    required this.regionEndBeat,
    required this.showRegionShading,
  });

  final double width;
  final double timelineEndBeat;
  final double pixelsPerBeat;
  final double regionStartBeat;
  final double regionEndBeat;
  final bool showRegionShading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final laneHeight = ArrangementTimelineMetrics.trackLaneHeight;
    return SizedBox(
      width: width,
      height: laneHeight,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, laneHeight),
            painter: ArrangementGridPainter(
              virtualLengthBeats: timelineEndBeat,
              pixelsPerBeat: pixelsPerBeat,
              gridBeats: 1,
              regionStartBeat: regionStartBeat,
              regionEndBeat: regionEndBeat,
              showRegionShading: showRegionShading,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ArrangementTheme.masterLaneWash,
              border: Border(
                top: BorderSide(color: ArrangementTheme.masterBorder),
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Master → Device out',
              style: theme.textTheme.labelMedium?.copyWith(
                color: ArrangementTheme.masterLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
