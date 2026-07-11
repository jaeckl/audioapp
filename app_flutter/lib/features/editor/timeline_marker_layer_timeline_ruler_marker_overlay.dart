part of 'timeline_marker_layer.dart';

class TimelineRulerMarkerOverlay extends StatelessWidget {
  const TimelineRulerMarkerOverlay({
    super.key,
    required this.left,
    required this.width,
    required this.rulerHeight,
    required this.markers,
  });

  final double left;
  final double width;
  final double rulerHeight;
  final List<Widget> markers;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TimelineMarkerLayerMetrics.overlayTop(),
      left: left,
      width: width,
      height: TimelineMarkerLayerMetrics.overlayHeight(rulerHeight),
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: markers,
        ),
      ),
    );
  }
}
