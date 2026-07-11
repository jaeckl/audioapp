part of 'arrangement_view.dart';

class _AddTrackLane extends StatelessWidget {
  const _AddTrackLane();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ArrangementTimelineMetrics.trackLaneHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
    );
  }
}
