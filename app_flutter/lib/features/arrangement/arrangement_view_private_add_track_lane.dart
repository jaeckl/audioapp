part of 'arrangement_view.dart';

class _AddTrackLane extends StatelessWidget {
  const _AddTrackLane();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ArrangementTimelineMetrics.trackLaneHeight,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ArrangementTheme.divider),
        ),
      ),
    );
  }
}
