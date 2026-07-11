part of 'arrangement_view.dart';

class _AddTrackHeader extends StatelessWidget {
  const _AddTrackHeader({
    required this.width,
    required this.onTap,
    this.onLongPress,
  });

  final double width;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add track',
      child: Semantics(
        label: 'Add track',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              width: width,
              height: ArrangementTimelineMetrics.trackLaneHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  right:
                      BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              child: Icon(Icons.add,
                  size: 24, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}
