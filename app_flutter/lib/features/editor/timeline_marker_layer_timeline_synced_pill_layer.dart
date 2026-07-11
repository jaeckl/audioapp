part of 'timeline_marker_layer.dart';

class TimelineSyncedPillLayer extends StatelessWidget {
  const TimelineSyncedPillLayer({
    super.key,
    required this.sideColumnWidth,
    required this.rulerHeight,
    required this.rulerMarkers,
  });

  final double sideColumnWidth;
  final double rulerHeight;
  final List<Widget> rulerMarkers;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sideColumnWidth,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: TimelineMarkerLayerMetrics.overlayTop(),
              left: 0,
              right: 0,
              height: TimelineMarkerLayerMetrics.overlayHeight(rulerHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: rulerMarkers,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
