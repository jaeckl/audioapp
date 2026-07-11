part of 'timeline_marker_layer.dart';

class TimelineSyncedLineLayer extends StatelessWidget {
  const TimelineSyncedLineLayer({
    super.key,
    required this.sideColumnWidth,
    required this.lines,
    this.clipToTimelineBand = true,
  });

  final double sideColumnWidth;
  final List<Widget> lines;
  final bool clipToTimelineBand;

  @override
  Widget build(BuildContext context) {
    final stack = IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: lines,
      ),
    );
    return Positioned(
      left: sideColumnWidth,
      top: 0,
      right: 0,
      bottom: 0,
      child: clipToTimelineBand ? ClipRect(child: stack) : stack,
    );
  }
}
