part of 'timeline_marker_layer.dart';

class TimelineBeatVerticalLineOverlay extends StatelessWidget {
  const TimelineBeatVerticalLineOverlay({
    super.key,
    required this.left,
    required this.rulerHeight,
    required this.width,
    required this.color,
  });

  final double left;
  final double rulerHeight;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: rulerHeight,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: ColoredBox(color: color),
      ),
    );
  }
}
