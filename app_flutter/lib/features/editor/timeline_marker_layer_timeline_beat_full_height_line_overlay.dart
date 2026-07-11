part of 'timeline_marker_layer.dart';

class TimelineBeatFullHeightLineOverlay extends StatelessWidget {
  const TimelineBeatFullHeightLineOverlay({
    super.key,
    required this.left,
    required this.width,
    required this.color,
  });

  final double left;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: ColoredBox(color: color),
      ),
    );
  }
}
