part of 'arrangement_view.dart';

class _MasterHeader extends StatelessWidget {
  const _MasterHeader({required this.master, required this.width});

  final MasterTrackSnapshot master;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: master.name,
      child: Semantics(
        label: master.name,
        child: Container(
          width: width,
          height: ArrangementTimelineMetrics.trackLaneHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2418),
            border: Border(
              top: BorderSide(color: Colors.amber.withValues(alpha: 0.35)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          child: Icon(Icons.speaker_outlined,
              size: 22, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }
}
