part of 'arrangement_view.dart';

class _MasterHeader extends StatelessWidget {
  const _MasterHeader({required this.master, required this.width});

  final MasterTrackSnapshot master;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: master.name,
      child: Semantics(
        label: master.name,
        child: Container(
          width: width,
          height: ArrangementTimelineMetrics.trackLaneHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ArrangementTheme.masterHeader,
            border: Border(
              top: BorderSide(color: ArrangementTheme.masterBorder),
              right: const BorderSide(color: ArrangementTheme.border),
            ),
          ),
          child: Icon(Icons.speaker_outlined,
              size: 22, color: ArrangementTheme.masterIcon),
        ),
      ),
    );
  }
}
